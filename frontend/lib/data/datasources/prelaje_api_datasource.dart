import '../../core/http/api_client.dart';
import '../models/carga_uso_referencia_dto.dart';
import '../models/dados_laje_dto.dart';
import '../models/resultado_dimensionamento_dto.dart';
import '../models/revestimento_referencia_dto.dart';
import '../models/vigota_referencia_dto.dart';

/// Datasource remoto — todas as chamadas HTTP ao backend.
///
/// Não faz cache; o repositório é responsável por isso.
/// Lança [AppException] em qualquer falha (via ApiClient).
class PrelajeApiDatasource {
  PrelajeApiDatasource({ApiClient? client})
      : _client = client ?? ApiClient();

  final ApiClient _client;

  /// Verifica se o backend está disponível.
  Future<bool> checkHealth() async {
    try {
      final response = await _client.get('/health') as Map<String, dynamic>;
      return response['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  /// GET /api/v1/vigotas
  Future<List<VigotaReferenciaDto>> fetchVigotas() async {
    final data = await _client.get('/vigotas') as List;
    return data
        .map((e) => VigotaReferenciaDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/v1/referencias/cargas-uso
  ///
  /// Retorna apenas os não-depreciados por padrão.
  Future<List<CargaUsoReferenciaDto>> fetchCargasUso({
    bool incluirDepreciados = false,
  }) async {
    final data = await _client.get('/referencias/cargas-uso') as List;
    final all = data
        .map((e) =>
            CargaUsoReferenciaDto.fromJson(e as Map<String, dynamic>))
        .toList();
    if (incluirDepreciados) return all;
    return all.where((e) => !e.depreciado).toList();
  }

  /// GET /api/v1/referencias/revestimentos
  Future<List<RevestimentoReferenciaDto>> fetchRevestimentos() async {
    final data = await _client.get('/referencias/revestimentos') as List;
    return data
        .map((e) =>
            RevestimentoReferenciaDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/dimensionar
  Future<ResultadoDimensionamentoDto> dimensionar(DadosLajeDto dados) async {
    final response =
        await _client.post('/dimensionar', dados.toJson()) as Map<String, dynamic>;
    return ResultadoDimensionamentoDto.fromJson(response);
  }

  /// POST /api/v1/relatorio-pdf
  ///
  /// Retorna os bytes do PDF gerado pelo backend.
  Future<List<int>> gerarPdf(DadosLajeDto dados) async {
    return _client.postBytes('/relatorio-pdf', dados.toJson());
  }

  void dispose() => _client.dispose();
}
