import 'mensagem_sistema_dto.dart';

// ---------------------------------------------------------------------------
// Sub-modelos
// ---------------------------------------------------------------------------

/// Mapeado de VerificacaoELU em schemas.py.
class VerificacaoEluDto {
  const VerificacaoEluDto({
    required this.msd,
    required this.vsd,
    required this.asCalculado,
    required this.asMinimo,
    required this.xd,
    required this.aprovadoFlexao,
    required this.aprovadoCisalhamento,
    required this.aprovadoArmaduraMinima,
  });

  final double msd;
  final double vsd;
  final double asCalculado;
  final double asMinimo;
  final double xd;
  final bool aprovadoFlexao;
  final bool aprovadoCisalhamento;
  final bool aprovadoArmaduraMinima;

  bool get aprovado =>
      aprovadoFlexao && aprovadoCisalhamento && aprovadoArmaduraMinima;

  factory VerificacaoEluDto.fromJson(Map<String, dynamic> json) =>
      VerificacaoEluDto(
        msd: (json['msd'] as num).toDouble(),
        vsd: (json['vsd'] as num).toDouble(),
        asCalculado: (json['as_calculado'] as num).toDouble(),
        asMinimo: (json['as_minimo'] as num).toDouble(),
        xd: (json['xd'] as num).toDouble(),
        aprovadoFlexao: json['aprovado_flexao'] as bool,
        aprovadoCisalhamento: json['aprovado_cisalhamento'] as bool,
        aprovadoArmaduraMinima: json['aprovado_armadura_minima'] as bool,
      );
}

/// Mapeado de VerificacaoELS em schemas.py.
class VerificacaoElsDto {
  const VerificacaoElsDto({
    required this.flechaImediata,
    required this.flechaDiferida,
    required this.flechaTotal,
    required this.flechaLimite,
    required this.aprovado,
  });

  final double flechaImediata;
  final double flechaDiferida;
  final double flechaTotal;
  final double flechaLimite;
  final bool aprovado;

  factory VerificacaoElsDto.fromJson(Map<String, dynamic> json) =>
      VerificacaoElsDto(
        flechaImediata: (json['flecha_imediata'] as num).toDouble(),
        flechaDiferida: (json['flecha_diferida'] as num).toDouble(),
        flechaTotal: (json['flecha_total'] as num).toDouble(),
        flechaLimite: (json['flecha_limite'] as num).toDouble(),
        aprovado: json['aprovado'] as bool,
      );
}

/// Mapeado de ArmaduraReforco em schemas.py.
class ArmaduraReforcoDto {
  const ArmaduraReforcoDto({
    required this.diametroMm,
    required this.quantidade,
    required this.asTotalCm2,
  });

  final double diametroMm;
  final int quantidade;
  final double asTotalCm2;

  factory ArmaduraReforcoDto.fromJson(Map<String, dynamic> json) =>
      ArmaduraReforcoDto(
        diametroMm: (json['diametro_mm'] as num).toDouble(),
        quantidade: json['quantidade'] as int,
        asTotalCm2: (json['as_total_cm2'] as num).toDouble(),
      );
}

/// Mapeado de ResultadoCatalogo em schemas.py.
class ResultadoCatalogoDto {
  const ResultadoCatalogoDto({
    required this.vaoTabelado,
    required this.cargaTotalKgfM2,
    this.reforco,
    required this.escoramento,
    required this.dentroDoCatalogo,
  });

  final double vaoTabelado;
  final double cargaTotalKgfM2;
  final ArmaduraReforcoDto? reforco;
  final double escoramento;
  final bool dentroDoCatalogo;

  factory ResultadoCatalogoDto.fromJson(Map<String, dynamic> json) =>
      ResultadoCatalogoDto(
        vaoTabelado: (json['vao_tabelado'] as num).toDouble(),
        cargaTotalKgfM2: (json['carga_total_kgf_m2'] as num).toDouble(),
        reforco: json['reforco'] != null
            ? ArmaduraReforcoDto.fromJson(
                json['reforco'] as Map<String, dynamic>)
            : null,
        escoramento: (json['escoramento_max_m'] as num).toDouble(),
        dentroDoCatalogo: json['dentro_do_catalogo'] as bool,
      );
}

/// Mapeado de Quantitativos em schemas.py.
class QuantitativosDto {
  const QuantitativosDto({
    required this.nVigotas,
    required this.nEnchimento,
    required this.volumeCapaM3,
    required this.pesoTelaKg,
  });

  final int nVigotas;
  final int nEnchimento;
  final double volumeCapaM3;
  final double pesoTelaKg;

  factory QuantitativosDto.fromJson(Map<String, dynamic> json) =>
      QuantitativosDto(
        nVigotas: json['n_vigotas'] as int,
        nEnchimento: json['n_enchimento'] as int,
        volumeCapaM3: (json['volume_capa_m3'] as num).toDouble(),
        pesoTelaKg: (json['peso_tela_kg'] as num).toDouble(),
      );
}

/// Mapeado de OrcamentoItem em schemas.py.
class OrcamentoItemDto {
  const OrcamentoItemDto({
    required this.categoria,
    required this.codigo,
    required this.descricao,
    required this.unidade,
    required this.quantidade,
    required this.quantidadeCompra,
    required this.unidadeCompra,
    required this.perdaPercentual,
    required this.precoUnitario,
    required this.custoTotal,
    this.observacoes,
  });

  final String categoria;
  final String codigo;
  final String descricao;
  final String unidade;
  final double quantidade;
  final double quantidadeCompra;
  final String unidadeCompra;
  final double perdaPercentual;
  final double precoUnitario;
  final double custoTotal;
  final String? observacoes;

  factory OrcamentoItemDto.fromJson(Map<String, dynamic> json) =>
      OrcamentoItemDto(
        categoria: json['categoria'] as String,
        codigo: json['codigo'] as String,
        descricao: json['descricao'] as String,
        unidade: json['unidade'] as String,
        quantidade: (json['quantidade'] as num).toDouble(),
        quantidadeCompra: (json['quantidade_compra'] as num).toDouble(),
        unidadeCompra: json['unidade_compra'] as String,
        perdaPercentual: (json['perda_percentual'] as num).toDouble(),
        precoUnitario: (json['preco_unitario'] as num).toDouble(),
        custoTotal: (json['custo_total'] as num).toDouble(),
        observacoes: json['observacoes'] as String?,
      );
}

/// Mapeado de OrcamentoResumo em schemas.py.
class OrcamentoResumoDto {
  const OrcamentoResumoDto({
    required this.areaLajeM2,
    required this.subtotalMateriais,
    required this.subtotalMaoObra,
    required this.subtotalIndiretos,
    required this.totalGeral,
    required this.custoUnitarioM2,
  });

  final double areaLajeM2;
  final double subtotalMateriais;
  final double subtotalMaoObra;
  final double subtotalIndiretos;
  final double totalGeral;
  final double custoUnitarioM2;

  factory OrcamentoResumoDto.fromJson(Map<String, dynamic> json) =>
      OrcamentoResumoDto(
        areaLajeM2: (json['area_laje_m2'] as num).toDouble(),
        subtotalMateriais: (json['subtotal_materiais'] as num).toDouble(),
        subtotalMaoObra: (json['subtotal_mao_obra'] as num).toDouble(),
        subtotalIndiretos: (json['subtotal_indiretos'] as num).toDouble(),
        totalGeral: (json['total_geral'] as num).toDouble(),
        custoUnitarioM2: (json['custo_unitario_m2'] as num).toDouble(),
      );
}

/// Mapeado de OrcamentoResultado em schemas.py.
class OrcamentoResultadoDto {
  const OrcamentoResultadoDto({
    required this.regiao,
    required this.itens,
    required this.resumo,
    required this.alertas,
  });

  final String regiao;
  final List<OrcamentoItemDto> itens;
  final OrcamentoResumoDto resumo;
  final List<String> alertas;

  factory OrcamentoResultadoDto.fromJson(Map<String, dynamic> json) =>
      OrcamentoResultadoDto(
        regiao: json['regiao'] as String,
        itens: (json['itens'] as List)
            .map((e) => OrcamentoItemDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        resumo: OrcamentoResumoDto.fromJson(
            json['resumo'] as Map<String, dynamic>),
        alertas: List<String>.from(json['alertas'] as List? ?? []),
      );
}

// ---------------------------------------------------------------------------
// ResultadoDimensionamentoDto — raiz
// ---------------------------------------------------------------------------

/// Mapeado de ResultadoDimensionamento em schemas.py.
///
/// Todos os campos são Optional quando o campo pode ser null no JSON
/// (elu, els, catalogo, orcamento).
class ResultadoDimensionamentoDto {
  const ResultadoDimensionamentoDto({
    required this.modo,
    required this.codigoVigota,
    required this.gK,
    required this.qK,
    required this.qSd,
    required this.qSer,
    this.elu,
    this.els,
    this.catalogo,
    required this.quantitativos,
    this.orcamento,
    required this.status,
    required this.aprovado,
    required this.alertas,
    required this.erros,
    required this.normasUtilizadas,
    required this.engineVersion,
    required this.parametrosValidade,
  });

  /// "catalogo" ou "analitico"
  final String modo;
  final String codigoVigota;

  final double gK;
  final double qK;
  final double qSd;
  final double qSer;

  final VerificacaoEluDto? elu;
  final VerificacaoElsDto? els;
  final ResultadoCatalogoDto? catalogo;

  final QuantitativosDto quantitativos;
  final OrcamentoResultadoDto? orcamento;

  /// "approved", "approved_with_warnings", "rejected"
  final String status;
  final bool aprovado;

  final List<MensagemSistemaDto> alertas;
  final List<MensagemSistemaDto> erros;
  final List<String> normasUtilizadas;
  final String engineVersion;
  final Map<String, dynamic> parametrosValidade;

  bool get hasWarnings => alertas.isNotEmpty;
  bool get hasErrors => erros.isNotEmpty;
  bool get isCatalogo => modo == 'catalogo';
  bool get isAnalitico => modo == 'analitico';

  factory ResultadoDimensionamentoDto.fromJson(Map<String, dynamic> json) =>
      ResultadoDimensionamentoDto(
        modo: json['modo'] as String,
        codigoVigota: json['codigo_vigota'] as String,
        gK: (json['g_k'] as num).toDouble(),
        qK: (json['q_k'] as num).toDouble(),
        qSd: (json['q_sd'] as num).toDouble(),
        qSer: (json['q_ser'] as num).toDouble(),
        elu: json['elu'] != null
            ? VerificacaoEluDto.fromJson(json['elu'] as Map<String, dynamic>)
            : null,
        els: json['els'] != null
            ? VerificacaoElsDto.fromJson(json['els'] as Map<String, dynamic>)
            : null,
        catalogo: json['catalogo'] != null
            ? ResultadoCatalogoDto.fromJson(
                json['catalogo'] as Map<String, dynamic>)
            : null,
        quantitativos: QuantitativosDto.fromJson(
            json['quantitativos'] as Map<String, dynamic>),
        orcamento: json['orcamento'] != null
            ? OrcamentoResultadoDto.fromJson(
                json['orcamento'] as Map<String, dynamic>)
            : null,
        status: json['status'] as String,
        aprovado: json['aprovado'] as bool,
        alertas: (json['alertas'] as List? ?? [])
            .map((e) =>
                MensagemSistemaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        erros: (json['erros'] as List? ?? [])
            .map((e) =>
                MensagemSistemaDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        normasUtilizadas:
            List<String>.from(json['normas_utilizadas'] as List? ?? []),
        engineVersion: json['engine_version'] as String? ?? '0.0.0',
        parametrosValidade:
            Map<String, dynamic>.from(json['parametros_validade'] as Map? ?? {}),
      );
}
