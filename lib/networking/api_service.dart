import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'http_client_factory.dart';
import 'routes/auth_routes.dart';

class ApiService {
  static final String baseUrl = _resolveBaseUrl();
  static http.Client _client = createHttpClient();
  static final String? hostHeader = _resolveHostHeader();

  /// Test seam: lets unit tests substitute an [http.MockClient] instead of
  /// hitting the network. Never call this from production code.
  @visibleForTesting
  static void debugOverrideClient(http.Client client) {
    _client = client;
  }

  @visibleForTesting
  static void debugResetClient() {
    _client = createHttpClient();
  }

  static String _resolveBaseUrl() {
    final defaultUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.corevia.local';
    final androidOverride = dotenv.env['API_BASE_URL_ANDROID'];

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        androidOverride != null &&
        androidOverride.isNotEmpty) {
      return androidOverride;
    }
    return defaultUrl;
  }

  static String? _resolveHostHeader() {
    final defaultHost = dotenv.env['API_HOST_HEADER'];
    final androidHost = dotenv.env['API_HOST_HEADER_ANDROID'];

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        androidHost != null &&
        androidHost.isNotEmpty) {
      return androidHost;
    }

    return (defaultHost != null && defaultHost.isNotEmpty) ? defaultHost : null;
  }

  static const _sensitiveKeys = {
    'password', 'token', 'authorization', 'id_token', 'access_token',
    'refresh_token', 'secret', 'ssn', 'credit_card',
  };

  static String _redact(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr);
      if (map is Map<String, dynamic>) {
        final redacted = map.map((k, v) =>
          _sensitiveKeys.contains(k.toLowerCase())
              ? MapEntry(k, '***')
              : MapEntry(k, v),
        );
        return jsonEncode(redacted);
      }
    } catch (_) {}
    return jsonStr;
  }

  static void _log(String method, String url, {int? status, String? body}) {
    if (!kDebugMode) return;
    final statusStr = status != null ? ' → $status' : '';
    debugPrint('[$method]$statusStr $url');
    if (body != null && body.isNotEmpty && body != '{}') {
      debugPrint('  body: ${_redact(body)}');
    }
  }

  static Map<String, String> _jsonHeaders([Map<String, String>? extra]) => {
    'Content-Type': 'application/json',
    'Origin': baseUrl,
    if (hostHeader != null) 'Host': hostHeader!,
    ...?extra,
  };

  static Map<String, String> _getHeaders([Map<String, String>? extra]) => {
    'Origin': baseUrl,
    if (hostHeader != null) 'Host': hostHeader!,
    ...?extra,
  };

  // ── Public requests ─────────────────────────────────────────────────────────

  static Future<dynamic> get(
    String path, {
    Map<String, String>? params,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse("$baseUrl$path").replace(queryParameters: params);
    _log('GET', uri.toString());
    try {
      final res = await _client.get(uri, headers: _getHeaders(headers)).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Requête GET expirée'),
      );
      _log('GET', uri.toString(), status: res.statusCode);
      if (res.statusCode >= 200 && res.statusCode < 300) return jsonDecode(res.body);
      throw Exception("Erreur GET $path : ${res.statusCode} - ${res.body}");
    } catch (e) {
      throw Exception("Erreur réseau GET : $e");
    }
  }

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = "$baseUrl$path";
    _log('POST', url, body: jsonEncode(body));
    try {
      final res = await _client.post(
        Uri.parse(url),
        headers: _jsonHeaders(headers),
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Requête POST expirée'),
      );
      _log('POST', url, status: res.statusCode, body: res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) return jsonDecode(res.body);
      throw Exception("Erreur POST : ${res.statusCode} ${res.body}");
    } catch (e) {
      throw Exception("Erreur réseau POST : $e");
    }
  }

  static Future<dynamic> put(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = "$baseUrl$path";
    _log('PUT', url, body: jsonEncode(body));
    try {
      final res = await _client.put(
        Uri.parse(url),
        headers: _jsonHeaders(headers),
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Requête PUT expirée'),
      );
      _log('PUT', url, status: res.statusCode, body: res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) return jsonDecode(res.body);
      throw Exception("Erreur PUT : ${res.statusCode} ${res.body}");
    } catch (e) {
      throw Exception("Erreur réseau PUT : $e");
    }
  }

  static Future<dynamic> patch(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = "$baseUrl$path";
    _log('PATCH', url, body: jsonEncode(body));
    try {
      final res = await _client.patch(
        Uri.parse(url),
        headers: _jsonHeaders(headers),
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Requête PATCH expirée'),
      );
      _log('PATCH', url, status: res.statusCode, body: res.body);
      if (res.statusCode >= 200 && res.statusCode < 300) return jsonDecode(res.body);
      throw Exception("Erreur PATCH : ${res.statusCode} ${res.body}");
    } catch (e) {
      throw Exception("Erreur réseau PATCH : $e");
    }
  }

  static Future<dynamic> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final url = "$baseUrl$path";
    _log('DELETE', url);
    try {
      final res = await _client.delete(
        Uri.parse(url),
        headers: _getHeaders(headers),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Requête DELETE expirée'),
      );
      _log('DELETE', url, status: res.statusCode);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return res.body.isNotEmpty ? jsonDecode(res.body) : null;
      }
      throw Exception("Erreur DELETE : ${res.statusCode} ${res.body}");
    } catch (e) {
      throw Exception("Erreur réseau DELETE : $e");
    }
  }

  // ── Protected requests (auto-injects Bearer token) ─────────────────────────

  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: 'auth_token') ?? '';
    if (kDebugMode) {
      debugPrint('  auth token: ${token.isEmpty ? "(empty)" : "present"}');
    }
    return {'Authorization': 'Bearer $token'};
  }

  static Future<dynamic> authGet(String path, {Map<String, String>? params}) async {
    return get(path, params: params, headers: await _authHeaders());
  }

  static Future<dynamic> authPost(String path, Map<String, dynamic> body) async {
    return post(path, body, headers: await _authHeaders());
  }

  static Future<dynamic> authPut(String path, Map<String, dynamic> body) async {
    return put(path, body, headers: await _authHeaders());
  }

  static Future<dynamic> authPatch(String path, Map<String, dynamic> body) async {
    return patch(path, body, headers: await _authHeaders());
  }

  static Future<dynamic> authDelete(String path) async {
    return delete(path, headers: await _authHeaders());
  }

  // ── Auth helpers ────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    try {
      await authPost(AuthRoutes.logout(), {});
    } catch (_) {
      // Ignore server errors — always clear local session
    }
    await _storage.delete(key: 'auth_token');
  }

}
