/// Configuração de ambiente do app.
///
/// Para desenvolvimento local no emulador Android use o default (10.0.2.2).
/// Para dispositivo físico na mesma rede, configure API_BASE_URL no build:
///   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
class AppConfig {
  AppConfig._();

  /// URL base da API. Trocada em tempo de build via --dart-define.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String apiPrefix = '/api/v1';
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Quando true, o app aceita resultado offline se o backend estiver fora.
  static const bool offlineFallbackEnabled = true;
}
