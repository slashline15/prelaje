/// Hierarquia de exceções tipadas do app.
///
/// Nunca exponha Exception genérica para a UI — use AppException.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Falha de rede (sem conexão, timeout, socket error).
class NetworkException extends AppException {
  const NetworkException([String message = 'Sem conexão com o servidor.'])
      : super(message);
}

/// O servidor respondeu, mas com status de erro (4xx, 5xx).
class ApiException extends AppException {
  const ApiException({
    required this.statusCode,
    required String message,
    this.detail,
  }) : super(message);

  final int statusCode;

  /// Campo "detail" do FastAPI, quando presente.
  final String? detail;
}

/// Entradas rejeitadas pela validação do motor (HTTP 422).
/// Mapeado de FastAPI ValidationError.
class ValidationException extends AppException {
  const ValidationException(String message) : super(message);
}

/// O servidor demorou demais para responder.
class TimeoutException extends AppException {
  const TimeoutException([String message = 'O servidor demorou demais. Tente novamente.'])
      : super(message);
}

/// Falha ao decodificar resposta JSON.
class ParseException extends AppException {
  const ParseException([String message = 'Resposta inesperada do servidor.'])
      : super(message);
}
