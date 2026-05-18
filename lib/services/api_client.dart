import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiClient {
  late Dio _dio;
  String? _token;
  String _baseUrl = AppConfig.defaultServerUrl;

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConfig.tokenKey);
    _baseUrl = prefs.getString(AppConfig.serverUrlKey) ?? AppConfig.defaultServerUrl;

    _dio = Dio(BaseOptions(
      baseUrl: '$_baseUrl/api/desktop',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          clearToken();
        }
        handler.next(error);
      },
    ));
  }

  bool get isLoggedIn => _token != null;
  String get serverUrl => _baseUrl;

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
  }

  Future<void> setServerUrl(String url) async {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _dio.options.baseUrl = '$_baseUrl/api/desktop';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.serverUrlKey, _baseUrl);
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? params}) async {
    final resp = await _dio.get(path, queryParameters: params);
    return Map<String, dynamic>.from(resp.data);
  }

  /// For endpoints returning JSON arrays
  Future<List<Map<String, dynamic>>> getList(String path, {Map<String, dynamic>? params}) async {
    final resp = await _dio.get(path, queryParameters: params);
    return List<Map<String, dynamic>>.from((resp.data as List).map((e) => Map<String, dynamic>.from(e)));
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    final resp = await _dio.post(path, data: data);
    return Map<String, dynamic>.from(resp.data);
  }

  Future<Map<String, dynamic>> delete(String path, {Map<String, dynamic>? params}) async {
    final resp = await _dio.delete(path, queryParameters: params);
    return Map<String, dynamic>.from(resp.data);
  }
}
