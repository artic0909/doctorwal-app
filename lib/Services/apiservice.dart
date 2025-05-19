import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio() {
    _dio.options.baseUrl = 'http://10.0.2.2:8000';
    _dio.options.headers = {'Accept': 'application/json'};
  }

  // LOGIN (Non-authenticated, based on response only)
  Future<Map<String, dynamic>?> getProfile(String email) async {
    try {
      final response = await _dio.post(
        '/api/get-profile',
        data: {'user_email': email},
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return response.data['data'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  // UPDATE PROFILE
  Future<Response> updateProfile(Map<String, String> data) {
    return _dio.put('/api/update-profile', data: data);
  }

  // UPDATE PASSWORD
  Future<Response> updatePassword(Map<String, String> data) {
    return _dio.put('/api/update-password', data: data);
  }
}
