import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  /// 登录走独立路径 /api/packer_login（不走 /api/desktop 前缀）
  Future<bool> login(String serverUrl, String username, String password) async {
    await _api.setServerUrl(serverUrl);
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ));
      final resp = await dio.post(
        '$serverUrl/api/packer_login',
        data: {'username': username, 'password': password},
      );
      final data = Map<String, dynamic>.from(resp.data);
      if (data['code'] == 0 && data['token'] != null) {
        await _api.setToken(data['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConfig.usernameKey, username);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConfig.usernameKey);
  }
}
