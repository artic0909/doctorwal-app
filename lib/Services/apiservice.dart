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

  // SEND PATIENT INQUIRY
  Future<Map<String, dynamic>> sendPatientInquiry({
    required String currentlyLoggedinPartnerId,
    required String clinicType,
    required String clinicName,
    required String userName,
    required String userCity,
    required String userMobile,
    required String userEmail,
    required String userInquiry,
  }) async {
    try {
      final response = await _dio.post(
        '/api/patient-inquiry',
        data: {
          'currenty_loggedin_partner_id': currentlyLoggedinPartnerId,
          'clinic_type': clinicType,
          'clinic_name': clinicName,
          'user_name': userName,
          'user_city': userCity,
          'user_mobile': userMobile,
          'user_email': userEmail,
          'user_inquiry': userInquiry,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': response.data['status'] == true,
          'message': response.data['message'] ?? '',
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed with status code: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Unknown error occurred';
      if (e.response != null && e.response?.data != null) {
        // If API sends error message in JSON
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'];
        } else {
          errorMessage = e.response.toString();
        }
      } else {
        errorMessage = e.message ?? 'An unknown error occurred';
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }




  // PATIENT FEEDBACK
  Future<Map<String, dynamic>> sendPatientFeedback({
    required String currentlyLoggedinPartnerId,
    required String clinicType,
    required String clinicName,
    required String userName,
    required String userEmail,
    required String userRating,
    required String userFeedback,
  }) async {
    try {
      final response = await _dio.post(
        '/api/patient-feedback',
        data: {
          'currenty_loggedin_partner_id': currentlyLoggedinPartnerId,
          'clinic_type': clinicType,
          'clinic_name': clinicName,
          'user_name': userName,
          'user_email': userEmail,
          'rating': userRating,
          'feedback': userFeedback,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': response.data['status'] == true,
          'message': response.data['message'] ?? '',
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed with status code: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      String errorMessage = 'Unknown error occurred';
      if (e.response != null && e.response?.data != null) {
        // If API sends error message in JSON
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'];
        } else {
          errorMessage = e.response.toString();
        }
      } else {
        errorMessage = e.message ?? 'An unknown error occurred';
      }
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }


  
}
