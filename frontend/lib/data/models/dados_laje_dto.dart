/// Mapeado de DadosLaje em schemas.py.
///
/// Campos em snake_case para corresponder diretamente ao JSON do backend.
/// Usar [toJson] para serializar antes de enviar ao endpoint POST /dimensionar.
class DadosLajeDto {
  const DadosLajeDto({
    required this.vao,
    required this.intereixo,
    required this.hEnchimento,
    required this.hCapa,
    required this.larguraTotal,
    this.fck = 20.0,
    this.classeAco = 'CA-50',
    required this.codigoVigota,
    required this.uso,
    this.gRevestimento = 0.0,
    this.tipoApoio = 'biapoiada',
    this.modo = 'analitico',
  });

  /// Vão livre entre apoios (m). Validação: 0 < vao ≤ 10.0
  final double vao;

  /// Intereixo entre nervuras (m). Deve corresponder ao catálogo da vigota.
  final double intereixo;

  /// Altura do enchimento EPS/cerâmica (m).
  final double hEnchimento;

  /// Espessura da capa de concreto (m). Mínimo: 0.025 (NBR 6118).
  final double hCapa;

  /// Largura total da laje (m).
  final double larguraTotal;

  /// Resistência do concreto da capa (MPa). Range: 20–50.
  final double fck;

  /// Classe do aço. Valores: "CA-50", "CA-60".
  final String classeAco;

  /// Código canônico da vigota (ex: "TR 8644"). Vem de GET /vigotas.
  final String codigoVigota;

  /// uso_id do endpoint GET /referencias/cargas-uso.
  final String uso;

  /// Carga permanente de revestimento (kN/m²). Vem de GET /referencias/revestimentos.
  final double gRevestimento;

  /// Condição de apoio. Valores: "biapoiada", "continua_2_vaos", "continua_3_vaos".
  final String tipoApoio;

  /// Modo do motor. Valores: "catalogo", "analitico".
  final String modo;

  Map<String, dynamic> toJson() => {
        'vao': vao,
        'intereixo': intereixo,
        'h_enchimento': hEnchimento,
        'h_capa': hCapa,
        'largura_total': larguraTotal,
        'fck': fck,
        'classe_aco': classeAco,
        'codigo_vigota': codigoVigota,
        'uso': uso,
        'g_revestimento': gRevestimento,
        'tipo_apoio': tipoApoio,
        'modo': modo,
      };

  DadosLajeDto copyWith({
    double? vao,
    double? intereixo,
    double? hEnchimento,
    double? hCapa,
    double? larguraTotal,
    double? fck,
    String? classeAco,
    String? codigoVigota,
    String? uso,
    double? gRevestimento,
    String? tipoApoio,
    String? modo,
  }) =>
      DadosLajeDto(
        vao: vao ?? this.vao,
        intereixo: intereixo ?? this.intereixo,
        hEnchimento: hEnchimento ?? this.hEnchimento,
        hCapa: hCapa ?? this.hCapa,
        larguraTotal: larguraTotal ?? this.larguraTotal,
        fck: fck ?? this.fck,
        classeAco: classeAco ?? this.classeAco,
        codigoVigota: codigoVigota ?? this.codigoVigota,
        uso: uso ?? this.uso,
        gRevestimento: gRevestimento ?? this.gRevestimento,
        tipoApoio: tipoApoio ?? this.tipoApoio,
        modo: modo ?? this.modo,
      );
}
