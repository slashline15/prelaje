/// Mapeado de MensagemSistema em schemas.py.
class MensagemSistemaDto {
  const MensagemSistemaDto({
    required this.code,
    required this.severity,
    required this.message,
    this.value,
    this.limit,
  });

  final String code;

  /// "warning" ou "error"
  final String severity;

  final String message;
  final double? value;
  final double? limit;

  bool get isError => severity == 'error';
  bool get isWarning => severity == 'warning';

  factory MensagemSistemaDto.fromJson(Map<String, dynamic> json) =>
      MensagemSistemaDto(
        code: json['code'] as String,
        severity: json['severity'] as String,
        message: json['message'] as String,
        value: (json['value'] as num?)?.toDouble(),
        limit: (json['limit'] as num?)?.toDouble(),
      );
}
