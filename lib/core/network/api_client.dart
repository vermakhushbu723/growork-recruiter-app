import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which side of the platform this app signs in to.
const String kApp = 'recruiter';

/// Backend base URL. Override per device with
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.5:5080/api/v1`.
/// Defaults: Android emulator → host machine (10.0.2.2), everything else →
/// localhost.
String get apiBaseUrl {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:5080/api/v1';
  }
  return 'http://localhost:5080/api/v1';
}

/// Readable error from the API (`message` from the server, or a network
/// problem) — safe to show to the user.
class ApiException implements Exception {
  ApiException(this.message, {this.status});

  final String message;
  final int? status;

  bool get isUnauthorized => status == 401;

  @override
  String toString() => message;
}

/// Keeps the session token in secure storage, falling back to shared
/// preferences where secure storage isn't available (tests, some web).
class TokenStore {
  static const _key = 'auth_token';
  static const _secure = FlutterSecureStorage();

  static Future<String?> read() async {
    try {
      return await _secure.read(key: _key);
    } catch (_) {
      return (await SharedPreferences.getInstance()).getString(_key);
    }
  }

  static Future<void> write(String? token) async {
    try {
      if (token == null) {
        await _secure.delete(key: _key);
      } else {
        await _secure.write(key: _key, value: token);
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      if (token == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, token);
      }
    }
  }
}

/// Single Dio instance for the Subkamyaab API. Every call returns the
/// response's `data` field and throws [ApiException] on failure.
class Api {
  Api._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = _token;
          if (t != null) options.headers['Authorization'] = 'Bearer $t';
          handler.next(options);
        },
      ),
    );
  }

  static final Api instance = Api._();

  late final Dio _dio;
  String? _token;

  bool get hasToken => _token != null;

  /// Points the client at another server (tests, staging).
  void setBaseUrl(String url) => _dio.options.baseUrl = url;

  Future<void> loadToken() async => _token = await TokenStore.read();

  Future<void> setToken(String? token) async {
    _token = token;
    await TokenStore.write(token);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, [Object? body]) =>
      _send(() => _dio.post(path, data: body ?? const {}));

  Future<dynamic> patch(String path, [Object? body]) =>
      _send(() => _dio.patch(path, data: body ?? const {}));

  Future<dynamic> delete(String path) => _send(() => _dio.delete(path));

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final res = await request();
      final body = res.data;
      return body is Map ? body['data'] : body;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] is String
          ? data['message'] as String
          : switch (e.type) {
              DioExceptionType.connectionTimeout ||
              DioExceptionType.receiveTimeout ||
              DioExceptionType.sendTimeout =>
                'The server is taking too long. Please try again.',
              DioExceptionType.connectionError =>
                'Can\'t reach the server. Check your internet connection.',
              _ => 'Something went wrong. Please try again.',
            };
      throw ApiException(message, status: e.response?.statusCode);
    }
  }
}

final api = Api.instance;

// ── JSON helpers shared by the model `fromJson` factories ──

String jStr(Object? v, [String fallback = '']) =>
    v == null ? fallback : v.toString();

int jInt(Object? v, [int fallback = 0]) =>
    v is num ? v.toInt() : int.tryParse('$v') ?? fallback;

double jDouble(Object? v, [double fallback = 0]) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? fallback;

bool jBool(Object? v, [bool fallback = false]) => v is bool ? v : fallback;

List<String> jStrList(Object? v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

DateTime? jDate(Object? v) => v == null ? null : DateTime.tryParse('$v');

Map<String, dynamic> jMap(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const {};

List<Map<String, dynamic>> jMapList(Object? v) => v is List
    ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : const [];

/// "Just now", "5h ago", "3 days ago", "2 weeks ago", "12 Oct".
String timeAgo(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays == 1) return '1 day ago';
  if (d.inDays < 7) return '${d.inDays} days ago';
  if (d.inDays < 30) {
    final w = d.inDays ~/ 7;
    return w == 1 ? '1 week ago' : '$w weeks ago';
  }
  if (d.inDays < 365) {
    final m = d.inDays ~/ 30;
    return m == 1 ? '1 month ago' : '$m months ago';
  }
  return '${t.day}/${t.month}/${t.year}';
}
