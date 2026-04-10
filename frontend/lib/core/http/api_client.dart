import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../error/app_exception.dart';

/// Wrapper sobre o pacote http com tratamento centralizado de erros.
///
/// Todos os métodos lançam [AppException] — nunca expõem [http.ClientException]
/// ou [FormatException] direto para os callers.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String baseUrl, String path) =>
      Uri.parse('$baseUrl${AppConfig.apiPrefix}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// GET — retorna dynamic (Map ou List decodificado).
  Future<dynamic> get(String path) async {
    final response = await _requestWithFallback(
      path,
      (uri) => _client.get(uri, headers: _headers),
    );
    return _decode(response);
  }

  /// POST JSON — retorna dynamic.
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await _requestWithFallback(
      path,
      (uri) => _client.post(uri, headers: _headers, body: jsonEncode(body)),
    );
    return _decode(response);
  }

  /// POST que retorna bytes crus (para download de PDF).
  Future<List<int>> postBytes(String path, Map<String, dynamic> body) async {
    final response = await _requestWithFallback(
      path,
      (uri) => _client.post(uri, headers: _headers, body: jsonEncode(body)),
    );
    if (response.statusCode != 200) {
      _throwApiError(response);
    }
    return response.bodyBytes.toList();
  }

  Future<http.Response> _requestWithFallback(
    String path,
    Future<http.Response> Function(Uri uri) request,
  ) async {
    Object? lastError;
    for (final baseUrl in AppConfig.baseUrlCandidates) {
      try {
        return await request(_uri(baseUrl, path))
            .timeout(AppConfig.requestTimeout);
      } on SocketException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      } on TimeoutException catch (error) {
        lastError = error;
      }
    }

    if (lastError is TimeoutException) {
      throw const TimeoutException();
    }
    throw const NetworkException();
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw const ParseException();
      }
    }
    _throwApiError(response);
  }

  Never _throwApiError(http.Response response) {
    final detail = _extractDetail(response.body);
    if (response.statusCode == 422) {
      throw ValidationException(detail ?? 'Dados inválidos.');
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: detail ?? 'Erro ${response.statusCode} do servidor.',
      detail: detail,
    );
  }

  String? _extractDetail(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        final detail = json['detail'];
        if (detail is String) return detail;
        return detail?.toString();
      }
    } catch (_) {}
    return null;
  }

  void dispose() => _client.close();
}
