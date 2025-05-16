import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class ApiService {
  final Dio _dio;
  final CookieJar cookieJar;

  ApiService()
      : cookieJar = CookieJar(),
        _dio = Dio() {
    _dio.interceptors.add(CookieManager(cookieJar));
    _dio.options.baseUrl = 'http://10.0.2.2:8000';
    _dio.options.headers = {
      'Accept': 'application/json',
    };
  }

  // LOGIN
  Future<void> loginUser(String email, String password) async {
    try {
      final response = await _dio.post('/api/dw-user-login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['status'] == true) {
        print("✅ Login successful. Session cookies saved.");
      } else {
        print("❌ Login failed: ${response.data['message']}");
        throw Exception('Login failed');
      }
    } catch (e) {
      print("❌ Error during login: $e");
      throw Exception('Login error');
    }
  }

  // UPDATE PROFILE
  Future<Response> updateProfile(Map<String, String> data) {
    return _dio.post('/api/update-profile', data: data);
  }
}
