import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/sign_up_request.dart';
import '../models/verify_otp_request.dart';
import '../models/sign_in_start_request.dart';
import '../models/sign_in_verify_request.dart';

class AuthController {
  static const String baseUrl = 'https://api.wanmac.ng';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  static Future<Map<String, dynamic>> signUp(SignUpRequest request) async {
    final url = Uri.parse('$baseUrl/signup');

    try {
      final response = await http
          .post(url, headers: _headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 20));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
          'referralCode': data['referralCode'],
          'message': data['message'] ?? 'Signup successful',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Signup failed',
        };
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(
    VerifyOtpRequest request,
  ) async {
    final url = Uri.parse('$baseUrl/confirm-signup');

    try {
      final response = await http
          .post(url, headers: _headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 20));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Phone number confirmed successfully',
          'data': data,
          'accessToken': data['accessToken'],
          'idToken': data['idToken'],
          'refreshToken': data['refreshToken'],
          'expiresIn': data['expiresIn'],
          'tokenType': data['tokenType'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'OTP verification failed',
        };
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    final url = Uri.parse('$baseUrl/resend-confirmation-code');

    try {
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({'phoneNumber': phoneNumber}),
          )
          .timeout(const Duration(seconds: 20));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
          'destination': data['destination'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to resend OTP',
      };
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error. Check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> signInStart(
    SignInStartRequest request,
  ) async {
    final url = Uri.parse('$baseUrl/signin-start');

    try {
      final response = await http
          .post(url, headers: _headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 20));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Signin OTP sent',
          'data': data,
          'session': data['session'],
          'challengeName': data['challengeName'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Signin failed',
        };
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> signInVerify(
    SignInVerifyRequest request,
  ) async {
    final url = Uri.parse('$baseUrl/signin-verify');

    try {
      final response = await http
          .post(url, headers: _headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 20));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Signin successful',
          'data': data,
          'accessToken': data['accessToken'],
          'idToken': data['idToken'],
          'refreshToken': data['refreshToken'],
          'expiresIn': data['expiresIn'],
          'tokenType': data['tokenType'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'OTP verification failed',
          'session': data['session'],
          'challengeName': data['challengeName'],
        };
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserDetails(String token) async {
    final url = Uri.parse('$baseUrl/me');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'User details fetched successfully',
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch user details',
        };
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> refreshSession(
    String refreshToken,
  ) async {
    final url = Uri.parse('$baseUrl/refresh-session');

    try {
      final response = await http
          .post(
            url,
            headers: _headers,
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 20));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Session refreshed successfully',
          'accessToken': data['accessToken'],
          'idToken': data['idToken'],
          'expiresIn': data['expiresIn'],
          'tokenType': data['tokenType'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to refresh session',
        };
      }
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> requestPhoneUpdate({
    required String idToken,
    required String phoneNumber,
  }) async {
    final url = Uri.parse('$baseUrl/request-phone-update');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'phoneNumber': phoneNumber}),
          )
          .timeout(const Duration(seconds: 20));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Verification code sent',
          'phoneNumber': data['phoneNumber'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to request phone update',
      };
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteAccount(String idToken) async {
    final url = Uri.parse('$baseUrl/delete-account');

    try {
      final cleanToken = idToken.replaceAll('Bearer ', '').trim();

      final response = await http
          .delete(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $cleanToken',
            },
          )
          .timeout(const Duration(seconds: 20));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Account deleted successfully',
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to delete account',
      };
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> verifyPhoneUpdate({
    required String idToken,
    required String phoneNumber,
    required String code,
  }) async {
    final url = Uri.parse('$baseUrl/verify-phone-update');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({'phoneNumber': phoneNumber, 'code': code}),
          )
          .timeout(const Duration(seconds: 20));

      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Phone number updated successfully',
          'phoneNumber': data['phoneNumber'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Failed to verify phone update',
      };
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out. Try again.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
