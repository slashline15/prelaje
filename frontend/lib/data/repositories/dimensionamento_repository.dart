import '../datasources/prelaje_api_datasource.dart';
import '../models/carga_uso_referencia_dto.dart';
import '../models/dados_laje_dto.dart';
import '../models/resultado_dimensionamento_dto.dart';
import '../models/revestimento_referencia_dto.dart';
import '../models/vigota_referencia_dto.dart';

/// Estados possíveis de conectividade com o backend.
enum BackendStatus { unknown, online, offline }

/// Repositório de dimensionamento — única fonte de verdade para a camada de domain.
///
/// Responsabilidades:
/// - Cache em memória das referências (vigotas, usos, revestimentos).
/// - Gestão do estado online/offline.
/// - Isolamento: features nunca conhecem o datasource diretamente.
class DimensionamentoRepository {
  DimensionamentoRepository({PrelajeApiDatasource? datasource})
      : _datasource = datasource ?? PrelajeApiDatasource();

  final PrelajeApiDatasource _datasource;

  // ---------------------------------------------------------------------------
  // Cache em memória — carregado uma vez por sessão
  // ---------------------------------------------------------------------------

  List<VigotaReferenciaDto>? _vigotasCache;
  List<CargaUsoReferenciaDto>? _cargasUsoCache;
  List<RevestimentoReferenciaDto>? _revestimentosCache;

  BackendStatus _backendStatus = BackendStatus.unknown;
  BackendStatus get backendStatus => _backendStatus;
  bool get isOnline => _backendStatus == BackendStatus.online;

  // ---------------------------------------------------------------------------
  // Health
  // ---------------------------------------------------------------------------

  /// Atualiza o status de conectividade. Chamar no boot do app.
  Future<BackendStatus> checkHealth() async {
    final ok = await _datasource.checkHealth();
    _backendStatus = ok ? BackendStatus.online : BackendStatus.offline;
    return _backendStatus;
  }

  // ---------------------------------------------------------------------------
  // Referências (com cache)
  // ---------------------------------------------------------------------------

  Future<List<VigotaReferenciaDto>> getVigotas() async {
    _vigotasCache ??= await _datasource.fetchVigotas();
    return _vigotasCache!;
  }

  Future<List<CargaUsoReferenciaDto>> getCargasUso() async {
    _cargasUsoCache ??= await _datasource.fetchCargasUso();
    return _cargasUsoCache!;
  }

  Future<List<RevestimentoReferenciaDto>> getRevestimentos() async {
    _revestimentosCache ??= await _datasource.fetchRevestimentos();
    return _revestimentosCache!;
  }

  /// Invalida todos os caches (útil para pull-to-refresh ou troca de servidor).
  void invalidateCache() {
    _vigotasCache = null;
    _cargasUsoCache = null;
    _revestimentosCache = null;
  }

  // ---------------------------------------------------------------------------
  // Dimensionamento
  // ---------------------------------------------------------------------------

  /// Chama POST /dimensionar. Nunca retorna null — lança AppException em falha.
  Future<ResultadoDimensionamentoDto> dimensionar(DadosLajeDto dados) async {
    final resultado = await _datasource.dimensionar(dados);
    _backendStatus = BackendStatus.online;
    return resultado;
  }

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  /// Retorna bytes do PDF gerado pelo backend.
  Future<List<int>> gerarPdf(DadosLajeDto dados) =>
      _datasource.gerarPdf(dados);

  void dispose() => _datasource.dispose();
}
