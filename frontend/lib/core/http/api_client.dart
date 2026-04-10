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

  Uri _uri(String path) =>
      Uri.parse('${AppConfig.baseUrl}${AppConfig.apiPrefix}$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// GET — retorna dynamic (Map ou List decodificado).
  Future<dynamic> get(String path) async {
    try {
      final response = await _client
          .get(_uri(path), headers: _headers)
          .timeout(AppConfig.requestTimeout);
      return _decode(response);
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutException();
    }
  }

  /// POST JSON — retorna dynamic.
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .post(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(AppConfig.requestTimeout);
      return _decode(response);
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutException();
    }
  }

  /// POST que retorna bytes crus (para download de PDF).
  Future<List<int>> postBytes(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client
          .post(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(AppConfig.requestTimeout);
      if (response.statusCode != 200) {
        _throwApiError(response);
      }
      return response.bodyBytes.toList();
    } on SocketException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const TimeoutException();
    }
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
