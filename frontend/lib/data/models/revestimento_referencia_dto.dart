/// Mapeado do endpoint GET /api/v1/referencias/revestimentos.
///
/// Presets de carga permanente de revestimento (preset_revestimentos.csv).
/// O usuário escolhe um preset; o valor [gRevKnM2] vai para
/// DadosLaje.g_revestimento.
class RevestimentoReferenciaDto {
  const RevestimentoReferenciaDto({
    required this.id,
    required this.descricao,
    required this.gRevKnM2,
  });

  final int id;
  final String descricao;

  /// Carga permanente de revestimento (kN/m²).
  final double gRevKnM2;

  factory RevestimentoReferenciaDto.fromJson(Map<String, dynamic> json) =>
      RevestimentoReferenciaDto(
        id: json['id'] as int,
        descricao: json['descricao'] as String,
        gRevKnM2: (json['g_rev_kn_m2'] as num).toDouble(),
      );
}
