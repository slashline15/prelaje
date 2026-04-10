/// Mapeado do endpoint GET /api/v1/referencias/cargas-uso.
///
/// Inclui valores depreciados (legados) marcados com [depreciado] = true.
/// A UI deve filtrar depreciados para exibição, mas preservá-los para
/// compatibilidade com projetos salvos em histórico.
class CargaUsoReferenciaDto {
  const CargaUsoReferenciaDto({
    required this.uso,
    required this.usoCategoria,
    required this.subcategoria,
    required this.cargaKnM2,
    required this.psi0,
    required this.psi1,
    required this.psi2,
    required this.depreciado,
    this.aliasDe,
  });

  /// Chave de uso (ex: "residencial_dormitorios_salas_cozinha").
  /// É o valor que vai para DadosLaje.uso.
  final String uso;

  final String usoCategoria;
  final String subcategoria;

  /// Carga acidental característica qk (kN/m²).
  final double cargaKnM2;

  final double psi0;
  final double psi1;
  final double psi2;

  /// Se true, não exibir na lista principal do wizard.
  final bool depreciado;

  /// Se depreciado, aponta para o uso_id preferencial.
  final String? aliasDe;

  /// Label legível para o wizard (ex: "Quarto / Sala").
  String get labelWizard => _labelMap[uso] ?? subcategoria;

  factory CargaUsoReferenciaDto.fromJson(Map<String, dynamic> json) =>
      CargaUsoReferenciaDto(
        uso: json['uso'] as String,
        usoCategoria: json['uso_categoria'] as String,
        subcategoria: json['subcategoria'] as String,
        cargaKnM2: (json['carga_kn_m2'] as num).toDouble(),
        psi0: (json['psi_0'] as num?)?.toDouble() ?? 0.5,
        psi1: (json['psi_1'] as num?)?.toDouble() ?? 0.4,
        psi2: (json['psi_2'] as num?)?.toDouble() ?? 0.3,
        depreciado: (json['depreciado'] as bool?) ?? false,
        aliasDe: json['alias_de'] as String?,
      );
}

/// Labels de wizard em português para os usos ativos.
const _labelMap = <String, String>{
  'residencial_dormitorios_salas_cozinha': 'Quarto / Sala / Cozinha',
  'residencial_banheiros': 'Banheiro',
  'residencial_despensa_lavanderia': 'Despensa / Lavanderia',
  'residencial_corredores_uso_comum': 'Corredor de uso comum',
  'comercial_escritorios_salas_gerais': 'Escritório / Sala comercial',
  'comercial_sanitarios': 'Sanitário comercial',
  'comercial_corredores_acesso_publico': 'Corredor de acesso público',
  'comercial_arquivos_deslizantes': 'Arquivo deslizante',
  'servico_forros_sem_acesso_pessoas': 'Forro (sem acesso)',
  'servico_garagens_veiculos_leves': 'Garagem (veículos leves)',
  'educacao_salas_de_aula': 'Sala de aula',
  'biblioteca_sala_de_leitura': 'Biblioteca — leitura',
  'biblioteca_sala_de_estantes': 'Biblioteca — estantes',
};
