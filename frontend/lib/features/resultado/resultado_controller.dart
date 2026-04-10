import 'package:flutter/foundation.dart';

import '../../data/models/dados_laje_dto.dart';
import '../../data/models/resultado_dimensionamento_dto.dart';
import '../../data/repositories/dimensionamento_repository.dart';

enum PdfState { idle, loading, ready, error }

/// Controller da tela de resultado.
///
/// Responsável por:
/// 1. Exibir o resultado recebido do wizard.
/// 2. Disparar a geração de PDF via backend.
/// 3. Gerenciar estado do PDF (loading, pronto, erro).
class ResultadoController extends ChangeNotifier {
  ResultadoController({
    required DimensionamentoRepository repository,
    required ResultadoDimensionamentoDto resultado,
    required DadosLajeDto dados,
  })  : _repo = repository,
        _resultado = resultado,
        _dados = dados;

  final DimensionamentoRepository _repo;
  final ResultadoDimensionamentoDto _resultado;
  final DadosLajeDto _dados;

  ResultadoDimensionamentoDto get resultado => _resultado;

  PdfState _pdfState = PdfState.idle;
  PdfState get pdfState => _pdfState;

  List<int>? _pdfBytes;
  List<int>? get pdfBytes => _pdfBytes;

  String? _pdfError;
  String? get pdfError => _pdfError;

  bool get isPdfLoading => _pdfState == PdfState.loading;
  bool get isPdfReady => _pdfState == PdfState.ready;

  // ---------------------------------------------------------------------------
  // Helpers de exibição
  // ---------------------------------------------------------------------------

  /// Cor semântica do status.
  StatusColor get statusColor {
    if (_resultado.aprovado) {
      return _resultado.hasWarnings ? StatusColor.warning : StatusColor.success;
    }
    return StatusColor.error;
  }

  /// Texto do status para exibição ao empreiteiro (sem jargão técnico).
  String get statusLabel {
    switch (_resultado.status) {
      case 'approved':
        return 'Laje dentro do catálogo';
      case 'approved_with_warnings':
        return 'Dentro do catálogo — verificar alertas';
      case 'rejected':
        return 'Fora dos limites — consulte engenheiro';
      default:
        return _resultado.status;
    }
  }

  /// Custo total estimado ou null se orçamento não disponível.
  double? get totalOrcamento => _resultado.orcamento?.resumo.totalGeral;

  /// Custo por m² ou null se orçamento não disponível.
  double? get custoUnitarioM2 => _resultado.orcamento?.resumo.custoUnitarioM2;

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  /// Solicita PDF ao backend.
  Future<void> solicitarPdf() async {
    if (_pdfState == PdfState.loading) return;
    _pdfState = PdfState.loading;
    _pdfBytes = null;
    _pdfError = null;
    notifyListeners();

    try {
      _pdfBytes = await _repo.gerarPdf(_dados);
      _pdfState = PdfState.ready;
    } catch (e) {
      _pdfError = e.toString();
      _pdfState = PdfState.error;
    }
    notifyListeners();
  }
}

enum StatusColor { success, warning, error }
