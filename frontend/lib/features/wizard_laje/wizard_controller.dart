import 'package:flutter/foundation.dart';

import '../../data/models/carga_uso_referencia_dto.dart';
import '../../data/models/dados_laje_dto.dart';
import '../../data/models/revestimento_referencia_dto.dart';
import '../../data/models/resultado_dimensionamento_dto.dart';
import '../../data/models/vigota_referencia_dto.dart';
import '../../data/repositories/dimensionamento_repository.dart';

// ---------------------------------------------------------------------------
// Estado do Wizard
// ---------------------------------------------------------------------------

enum WizardLoadState { idle, loadingRefs, refsLoaded, calculating, error }

/// Estado imutável das escolhas do usuário no wizard.
class WizardSelections {
  const WizardSelections({
    this.vao = 4.0,
    this.larguraTotal = 4.0,
    this.vigota,
    this.uso,
    this.revestimento,
    this.modo = 'catalogo',
    this.hCapa = 0.025,
    this.fck = 20.0,
    this.classeAco = 'CA-50',
    this.tipoApoio = 'biapoiada',
  });

  final double vao;
  final double larguraTotal;
  final VigotaReferenciaDto? vigota;
  final CargaUsoReferenciaDto? uso;
  final RevestimentoReferenciaDto? revestimento;
  final String modo;
  final double hCapa;
  final double fck;
  final String classeAco;
  final String tipoApoio;

  /// Valida os campos obrigatórios antes de enviar ao backend.
  String? validate() {
    if (vao <= 0 || vao > 10.0) return 'Vão deve estar entre 0 e 10 m.';
    if (larguraTotal <= 0) return 'Largura deve ser positiva.';
    if (vigota == null) return 'Selecione a vigota.';
    if (uso == null) return 'Selecione o uso da laje.';
    if (revestimento == null) return 'Selecione o acabamento.';
    if (hCapa < 0.025) return 'A capa mínima é 2,5 cm.';
    return null;
  }

  /// Monta o DTO completo para envio ao backend.
  DadosLajeDto toDadosLaje() {
    final v = vigota!;
    return DadosLajeDto(
      vao: vao,
      // Intereixo é fixo por vigota — não pode ser digitado livremente.
      intereixo: v.intereixoCm / 100.0,
      // h_enchimento default do catálogo: 8 cm (0.08 m). Pode ser exposto
      // depois como step avançado.
      hEnchimento: 0.08,
      // Capa mínima normativa: 2,5 cm. Pode ser ajustada no passo de dimensões.
      hCapa: hCapa,
      larguraTotal: larguraTotal,
      fck: fck,
      classeAco: classeAco,
      codigoVigota: v.codigo,
      uso: uso!.uso,
      gRevestimento: revestimento!.gRevKnM2,
      tipoApoio: tipoApoio,
      modo: modo,
    );
  }

  WizardSelections copyWith({
    double? vao,
    double? larguraTotal,
    VigotaReferenciaDto? vigota,
    CargaUsoReferenciaDto? uso,
    RevestimentoReferenciaDto? revestimento,
    String? modo,
    double? hCapa,
    double? fck,
    String? classeAco,
    String? tipoApoio,
  }) =>
      WizardSelections(
        vao: vao ?? this.vao,
        larguraTotal: larguraTotal ?? this.larguraTotal,
        vigota: vigota ?? this.vigota,
        uso: uso ?? this.uso,
        revestimento: revestimento ?? this.revestimento,
        modo: modo ?? this.modo,
        hCapa: hCapa ?? this.hCapa,
        fck: fck ?? this.fck,
        classeAco: classeAco ?? this.classeAco,
        tipoApoio: tipoApoio ?? this.tipoApoio,
      );
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class WizardController extends ChangeNotifier {
  WizardController({required DimensionamentoRepository repository})
      : _repo = repository;

  final DimensionamentoRepository _repo;

  // Estado
  WizardLoadState _state = WizardLoadState.idle;
  WizardLoadState get state => _state;

  WizardSelections _selections = const WizardSelections();
  WizardSelections get selections => _selections;

  // Referências do backend
  List<VigotaReferenciaDto> _vigotas = [];
  List<CargaUsoReferenciaDto> _usos = [];
  List<RevestimentoReferenciaDto> _revestimentos = [];

  List<VigotaReferenciaDto> get vigotas => _vigotas;
  List<CargaUsoReferenciaDto> get usos => _usos;
  List<RevestimentoReferenciaDto> get revestimentos => _revestimentos;

  VigotaReferenciaDto? get vigotaRecomendada {
    if (_vigotas.isEmpty) return null;
    final candidatas = _vigotas
        .where(
          (v) =>
              v.disponivelCatalogo &&
              v.vaoMaxM >= _selections.vao &&
              v.fckCatalogoMpa.contains(_selections.fck),
        )
        .toList()
      ..sort((a, b) {
        final porVao = b.vaoMaxM.compareTo(a.vaoMaxM);
        if (porVao != 0) return porVao;
        return b.hVigotaCm.compareTo(a.hVigotaCm);
      });
    if (candidatas.isNotEmpty) return candidatas.first;

    final porVao = _vigotas
        .where((v) => v.vaoMaxM >= _selections.vao && v.disponivelCatalogo)
        .toList()
      ..sort((a, b) {
        final porVao = b.vaoMaxM.compareTo(a.vaoMaxM);
        if (porVao != 0) return porVao;
        return b.hVigotaCm.compareTo(a.hVigotaCm);
      });
    if (porVao.isNotEmpty) return porVao.first;

    return _vigotas.first;
  }

  double get hCapaRecomendada {
    final recomendada = vigotaRecomendada;
    if (recomendada == null) return 0.025;
    return (recomendada.capaMinCm / 100.0).clamp(0.025, 0.20);
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ResultadoDimensionamentoDto? _resultado;
  ResultadoDimensionamentoDto? get resultado => _resultado;

  bool get isRefsLoaded => _state == WizardLoadState.refsLoaded;
  bool get isCalculating => _state == WizardLoadState.calculating;
  bool get hasResult => _resultado != null;

  // ---------------------------------------------------------------------------
  // Inicialização: carrega referências do backend
  // ---------------------------------------------------------------------------

  Future<void> loadReferencias() async {
    if (_state == WizardLoadState.refsLoaded) return; // já carregado
    _setState(WizardLoadState.loadingRefs);
    try {
      final results = await Future.wait([
        _repo.getVigotas(),
        _repo.getCargasUso(),
        _repo.getRevestimentos(),
      ]);
      _vigotas = results[0] as List<VigotaReferenciaDto>;
      _usos = results[1] as List<CargaUsoReferenciaDto>;
      _revestimentos = results[2] as List<RevestimentoReferenciaDto>;

      _selections = WizardSelections(
        vigota: _vigotas.isNotEmpty ? vigotaRecomendada ?? _vigotas.first : null,
        uso: _usos.isNotEmpty ? _usos.first : null,
        revestimento: _revestimentos.isNotEmpty ? _revestimentos.first : null,
        modo: 'catalogo',
        hCapa: hCapaRecomendada,
      );

      _setState(WizardLoadState.refsLoaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(WizardLoadState.error);
    }
  }

  // ---------------------------------------------------------------------------
  // Atualização das seleções
  // ---------------------------------------------------------------------------

  void updateVao(double value) {
    _selections = _selections.copyWith(vao: value.clamp(0.5, 10.0));
    _syncAutomaticSelections();
    notifyListeners();
  }

  void updateLargura(double value) {
    _selections = _selections.copyWith(larguraTotal: value > 0 ? value : 1.0);
    notifyListeners();
  }

  void selectVigota(VigotaReferenciaDto vigota) {
    _selections = _selections.copyWith(vigota: vigota);
    notifyListeners();
  }

  void selectUso(CargaUsoReferenciaDto uso) {
    _selections = _selections.copyWith(uso: uso);
    notifyListeners();
  }

  void selectRevestimento(RevestimentoReferenciaDto revestimento) {
    _selections = _selections.copyWith(revestimento: revestimento);
    notifyListeners();
  }

  void setModo(String modo) {
    _selections = _selections.copyWith(modo: modo);
    _syncAutomaticSelections();
    notifyListeners();
  }

  void updateHCapa(double value) {
    _selections = _selections.copyWith(hCapa: value.clamp(0.025, 0.20));
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Cálculo
  // ---------------------------------------------------------------------------

  /// Envia ao backend e popula [resultado].
  /// Retorna null em sucesso; mensagem de erro em falha.
  Future<String?> calcular() async {
    final validationError = _selections.validate();
    if (validationError != null) return validationError;

    _setState(WizardLoadState.calculating);
    _resultado = null;

    try {
      final dados = _selections.toDadosLaje();
      _resultado = await _repo.dimensionar(dados);
      _setState(WizardLoadState.refsLoaded);
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(WizardLoadState.error);
      return _errorMessage;
    }
  }

  void resetResultado() {
    _resultado = null;
    notifyListeners();
  }

  void _syncAutomaticSelections() {
    if (_selections.modo == 'catalogo') {
      final recomendada = vigotaRecomendada;
      if (recomendada != null) {
        _selections = _selections.copyWith(
          vigota: recomendada,
          hCapa: recomendada.capaMinCm / 100.0,
        );
      }
      return;
    }

    if (_selections.vigota == null && _vigotas.isNotEmpty) {
      _selections = _selections.copyWith(vigota: _vigotas.first);
    }
  }

  void _setState(WizardLoadState newState) {
    _state = newState;
    notifyListeners();
  }
}
