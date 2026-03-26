import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio() {
    _dio.options.baseUrl = 'https://doctorwala.info';
    _dio.options.headers = {'Accept': 'application/json'};
  }

  Future<void> _setAuthHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  // GET AUTHENTICATED USER PROFILE
  Future<Map<String, dynamic>> getProfile() async {
    try {
      await _setAuthHeader();
      final response = await _dio.get('/api/user-profile');
      return response.data;
    } on DioException catch (e) {
      return {'status': false, 'message': e.message};
    }
  }

  // UPDATE USER PROFILE (supports image upload)
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String mobile,
    String? city,
    String? dob,
    String? gender,
    String? address,
    String? bloodGroup,
    String? height,
    String? weight,
    String? emergencyContact,
    String? allergies,
    String? chronicConditions,
    String? imagePath, // Path to local image file
  }) async {
    try {
      await _setAuthHeader();

      Map<String, dynamic> data = {
        'user_name': name,
        'user_email': email,
        'user_mobile': mobile,
        'user_city': city,
        'dob': dob,
        'gender': gender,
        'address': address,
        'blood_group': bloodGroup,
        'height': height,
        'weight': weight,
        'emergency_contact': emergencyContact,
        'allergies': allergies,
        'chronic_conditions': chronicConditions,
      };

      if (imagePath != null && imagePath.isNotEmpty) {
        data['image'] = await MultipartFile.fromFile(imagePath);
      }

      FormData formData = FormData.fromMap(data);

      final response = await _dio.post(
        '/api/update-profile',
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return e.response?.data;
      }
      return {'status': false, 'message': 'Network error occurred'};
    }
  }

  // UPDATE PASSWORD
  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      await _setAuthHeader();
      final response = await _dio.post(
        '/api/update-password',
        data: {
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return e.response?.data;
      }
      return {'status': false, 'message': 'Network error occurred'};
    }
  }

  // UPDATE PIN
  Future<Response> updatePin(Map<String, String> data) async {
    await _setAuthHeader();
    return _dio.post('/api/update-pin', data: data);
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

  // USER LOGIN WITH OTP
  // SEND OTP
  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      final response = await _dio.post(
        '/api/send-otp',
        data: {'user_email': email},
      );
      return {
        'success': response.data['status'],
        'message': response.data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error sending OTP: $e'};
    }
  }

  // VERIFY OTP
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      final response = await _dio.post(
        '/api/verify-otp',
        data: {'user_email': email, 'otp': otp},
      );

      return {
        'success': response.data['status'],
        'message': response.data['message'],
        'data': response.data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Error verifying OTP: $e'};
    }
  }
}

