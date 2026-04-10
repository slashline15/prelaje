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
  const NetworkException([super.message = 'Sem conexão com o servidor.']);
}

/// O servidor respondeu, mas com status de erro (4xx, 5xx).
class ApiException extends AppException {
  const ApiException({
    required this.statusCode,
    required super.message,
    this.detail,
  });

  final int statusCode;

  /// Campo "detail" do FastAPI, quando presente.
  final String? detail;
}

/// Entradas rejeitadas pela validação do motor (HTTP 422).
/// Mapeado de FastAPI ValidationError.
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// O servidor demorou demais para responder.
class TimeoutException extends AppException {
  const TimeoutException([super.message = 'O servidor demorou demais. Tente novamente.']);
}

/// Falha ao decodificar resposta JSON.
class ParseException extends AppException {
  const ParseException([super.message = 'Resposta inesperada do servidor.']);
}
