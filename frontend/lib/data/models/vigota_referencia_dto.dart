/// Mapeado do endpoint GET /api/v1/vigotas.
class VigotaReferenciaDto {
  const VigotaReferenciaDto({
    required this.codigo,
    required this.codigoCanonical,
    required this.aliases,
    required this.hVigotaCm,
    required this.larguraNervuraCm,
    required this.intereixoCm,
    required this.capaMinCm,
    required this.vaoMaxM,
    required this.disponivelAnalitico,
    required this.disponivelCatalogo,
    required this.fckCatalogoMpa,
    required this.intereixosCatalogoCm,
    required this.capasCatalogoCm,
  });

  final String codigo;
  final String codigoCanonical;
  final List<String> aliases;

  /// Altura da vigota pré-moldada (cm).
  final double hVigotaCm;

  /// Largura da nervura / alma (cm).
  final double larguraNervuraCm;

  /// Intereixo de projeto (cm). Fixo por modelo — não pode ser digitado livremente.
  final double intereixoCm;

  /// Espessura mínima de capa compatível (cm).
  final double capaMinCm;

  /// Vão máximo suportado pelo modelo (m).
  final double vaoMaxM;

  final bool disponivelAnalitico;
  final bool disponivelCatalogo;

  /// fck values disponíveis no catálogo (ex: [20, 25]).
  final List<double> fckCatalogoMpa;
  final List<double> intereixosCatalogoCm;
  final List<double> capasCatalogoCm;

  /// Label legível para o wizard (ex: "Vigota 8 cm / int. 42 cm").
  String get labelWizard =>
      'Vigota ${hVigotaCm.toStringAsFixed(0)} cm / int. ${intereixoCm.toStringAsFixed(0)} cm';

  factory VigotaReferenciaDto.fromJson(Map<String, dynamic> json) =>
      VigotaReferenciaDto(
        codigo: json['codigo'] as String,
        codigoCanonical: json['codigo_canonico'] as String,
        aliases: List<String>.from(json['aliases'] as List),
        hVigotaCm: (json['h_vigota_cm'] as num).toDouble(),
        larguraNervuraCm: (json['largura_nervura_cm'] as num).toDouble(),
        intereixoCm: (json['intereixo_cm'] as num).toDouble(),
        capaMinCm: (json['capa_min_cm'] as num).toDouble(),
        vaoMaxM: (json['vao_max_m'] as num).toDouble(),
        disponivelAnalitico: json['disponivel_analitico'] as bool,
        disponivelCatalogo: json['disponivel_catalogo'] as bool,
        fckCatalogoMpa: (json['fck_catalogo_mpa'] as List)
            .map((e) => (e as num).toDouble())
            .toList(),
        intereixosCatalogoCm: (json['intereixos_catalogo_cm'] as List)
            .map((e) => (e as num).toDouble())
            .toList(),
        capasCatalogoCm: (json['capas_catalogo_cm'] as List)
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}
