import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wanmac/controllers/auth_controller.dart';
import 'package:wanmac/main.dart';
import 'package:wanmac/models/sign_in_start_request.dart';
import 'package:wanmac/models/sign_in_verify_request.dart';
import 'package:wanmac/models/sign_up_request.dart';
import 'package:wanmac/models/verify_otp_request.dart';
import 'package:wanmac/views/screens/splash_screen.dart';

class AuthService {
  static Timer? _sessionRefreshTimer;
  static Timer? _refreshTokenExpiryTimer;

  static const Duration _tokenRefreshBuffer = Duration(minutes: 5);

  static Future<Map<String, dynamic>> signUp(SignUpRequest request) async {
    return await AuthController.signUp(request);
  }

  static Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    return await AuthController.resendOtp(phoneNumber);
  }

  static Future<Map<String, dynamic>> signInStart(
    SignInStartRequest request,
  ) async {
    return await AuthController.signInStart(request);
  }

  static Future<Map<String, dynamic>> verifySignupOtpAndSaveUser(
    VerifyOtpRequest request,
  ) async {
    final result = await AuthController.verifyOtp(request);

    if (result['success'] != true) return result;

    final accessToken = (result['accessToken'] ?? '').toString();
    final idToken = (result['idToken'] ?? '').toString();
    final refreshToken = (result['refreshToken'] ?? '').toString();

    if (accessToken.isEmpty || idToken.isEmpty || refreshToken.isEmpty) {
      return {
        'success': false,
        'message': 'Missing authentication tokens after verification',
      };
    }

    await _saveTokens(
      accessToken: accessToken,
      idToken: idToken,
      refreshToken: refreshToken,
      isFreshLogin: true,
    );

    final userResult = await AuthController.getUserDetails(idToken);

    if (userResult['success'] != true) {
      await logout(navigateToSplash: false);
      return {
        'success': false,
        'message': userResult['message'] ?? 'Failed to fetch user details',
      };
    }

    final user = userResult['user'] as Map<String, dynamic>;
    await _saveUserToPrefs(user);

    return {
      'success': true,
      'message': result['message'] ?? 'Verification successful',
      'user': user,
    };
  }

  static Future<Map<String, dynamic>> verifySignInOtpAndSaveUser(
    SignInVerifyRequest request,
  ) async {
    final result = await AuthController.signInVerify(request);

    if (result['success'] != true) return result;

    final accessToken = (result['accessToken'] ?? '').toString();
    final idToken = (result['idToken'] ?? '').toString();
    final refreshToken = (result['refreshToken'] ?? '').toString();

    if (accessToken.isEmpty || idToken.isEmpty || refreshToken.isEmpty) {
      return {
        'success': false,
        'message': 'Missing authentication tokens after sign in',
      };
    }

    await _saveTokens(
      accessToken: accessToken,
      idToken: idToken,
      refreshToken: refreshToken,
      isFreshLogin: true,
    );

    final userResult = await AuthController.getUserDetails(idToken);

    if (userResult['success'] != true) {
      await logout(navigateToSplash: false);
      return {
        'success': false,
        'message': userResult['message'] ?? 'Failed to fetch user details',
      };
    }

    final user = userResult['user'] as Map<String, dynamic>;
    await _saveUserToPrefs(user);

    return {
      'success': true,
      'message': result['message'] ?? 'Signin successful',
      'user': user,
    };
  }

  static Future<bool> refreshSession() async {
    final prefs = await SharedPreferences.getInstance();
    print('🔄 Refreshing session...');
    final refreshToken = prefs.getString('refreshToken') ?? '';

    if (refreshToken.isEmpty) {
      await logout();
      return false;
    }

    final result = await AuthController.refreshSession(refreshToken);

    if (result['success'] != true) {
      await logout();
      return false;
    }

    final accessToken = (result['accessToken'] ?? '').toString();
    final idToken = (result['idToken'] ?? '').toString();
    final returnedRefreshToken = (result['refreshToken'] ?? refreshToken)
        .toString();

    if (accessToken.isEmpty || idToken.isEmpty) {
      await logout();
      return false;
    }

    await _saveTokens(
      accessToken: accessToken,
      idToken: idToken,
      refreshToken: returnedRefreshToken,
      isFreshLogin: false,
    );
   print('✅ Session refreshed successfully');
    return true;
  }

 static Future<String?> getValidIdToken() async {
    final prefs = await SharedPreferences.getInstance();

    final idToken = prefs.getString('idToken') ?? '';
    final expiryString = prefs.getString('tokenExpiry');

    print('🔍 idToken exists: ${idToken.isNotEmpty}');
    print('🔍 tokenExpiry: $expiryString');

    if (idToken.isEmpty || expiryString == null) {
      print('❌ Missing token or expiry');
      await logout();
      return null;
    }
    final expiry = DateTime.tryParse(expiryString);

    if (expiry == null) {
      await logout();
      return null;
    }

    final now = DateTime.now();

    // Refresh 5 minutes before token expires
    if (now.isAfter(expiry.subtract(_tokenRefreshBuffer))) {
      final refreshed = await refreshSession();

      if (!refreshed) {
        await logout();
        return null;
      }
    }

    final updatedPrefs = await SharedPreferences.getInstance();
    return updatedPrefs.getString('idToken');
  }

 static Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();

    final idToken = prefs.getString('idToken');
    final expiryString = prefs.getString('tokenExpiry');

    if (idToken == null || idToken.isEmpty || expiryString == null) {
      return false;
    }

    final expiry = DateTime.tryParse(expiryString);

    if (expiry == null) {
      return false;
    }

    // Just check if the token has not expired.
    // Do NOT refresh the session here.
    return DateTime.now().isBefore(expiry);
  }

  static Future<void> startSavedSessionWatcher() async {
    final prefs = await SharedPreferences.getInstance();

    final expiryString = prefs.getString('tokenExpiry');
    final refreshExpiryString = prefs.getString('refreshTokenExpiry');

    if (expiryString == null || refreshExpiryString == null) return;

    final expiry = DateTime.tryParse(expiryString);
    final refreshExpiry = DateTime.tryParse(refreshExpiryString);

    if (expiry == null || refreshExpiry == null) {
      await logout();
      return;
    }

    _startSessionRefreshTimer(expiry);
    _startRefreshTokenExpiryTimer(refreshExpiry);
  }

 static void _startSessionRefreshTimer(DateTime expiry) {
    _sessionRefreshTimer?.cancel();

    final refreshAt = expiry.subtract(_tokenRefreshBuffer);
    final duration = refreshAt.difference(DateTime.now());

    print('⏳ ID token refresh scheduled in: $duration');

    if (duration.isNegative || duration.inSeconds <= 0) {
      Future.microtask(() async {
        await refreshSession();
      });
      return;
    }

    _sessionRefreshTimer = Timer(duration, () async {
      final refreshed = await refreshSession();

      if (!refreshed) {
        await logout();
      }
    });
  }

  static void _startRefreshTokenExpiryTimer(DateTime expiry) {
    _refreshTokenExpiryTimer?.cancel();

    final duration = expiry.difference(DateTime.now());

    print('🗓 Refresh token expires/logs out in: $duration');

    if (duration.isNegative || duration.inSeconds <= 0) {
      Future.microtask(() async {
        await logout();
      });
      return;
    }

    _refreshTokenExpiryTimer = Timer(duration, () async {
      await logout();
    });
  }



  static Future<void> logout({bool navigateToSplash = true}) async {
    _sessionRefreshTimer?.cancel();
    _sessionRefreshTimer = null;

    _refreshTokenExpiryTimer?.cancel();
    _refreshTokenExpiryTimer = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('accessToken');
    await prefs.remove('idToken');
    await prefs.remove('refreshToken');
    await prefs.remove('tokenExpiry');
    await prefs.remove('refreshTokenExpiry');

    await prefs.remove('userId');
    await prefs.remove('firstName');
    await prefs.remove('lastName');
    await prefs.remove('email');
    await prefs.remove('phoneNumber');
    await prefs.remove('referralCode');
    await prefs.remove('referredByCode');
    await prefs.remove('referredByUserId');
    await prefs.remove('wanBucksBalance');
    await prefs.remove('referralRewardApplied');
    await prefs.remove('createdAt');

    if (navigateToSplash) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  static Future<void> _saveTokens({
    required String accessToken,
    required String idToken,
    required String refreshToken,
    required bool isFreshLogin,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final tokenExpiry = _extractJwtExpiry(idToken);

    if (tokenExpiry == null) {
      throw Exception('Unable to parse idToken expiry');
    }

    // Set refresh token expiry only on real login/signup.
    // Do not reset the 30 days every normal token refresh.
    if (isFreshLogin || prefs.getString('refreshTokenExpiry') == null) {
      final refreshTokenExpiry = DateTime.now().add(const Duration(days: 30));

      await prefs.setString(
        'refreshTokenExpiry',
        refreshTokenExpiry.toIso8601String(),
      );

      _startRefreshTokenExpiryTimer(refreshTokenExpiry);
    }

    await prefs.setString('accessToken', accessToken);
    await prefs.setString('idToken', idToken);
    await prefs.setString('refreshToken', refreshToken);
    await prefs.setString('tokenExpiry', tokenExpiry.toIso8601String());

    _startSessionRefreshTimer(tokenExpiry);
  }

  static DateTime? _extractJwtExpiry(String jwt) {
    try {
      final parts = jwt.split('.');

      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = map['exp'];

      if (exp is! int) return null;

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveUserToPrefs(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('userId', (user['userId'] ?? '').toString());
    await prefs.setString('firstName', (user['firstName'] ?? '').toString());
    await prefs.setString('lastName', (user['lastName'] ?? '').toString());
    await prefs.setString('email', (user['email'] ?? '').toString());

    await prefs.setString(
      'phoneNumber',
      (user['phoneNumber'] ?? '').toString(),
    );

    await prefs.setString(
      'referralCode',
      (user['referralCode'] ?? '').toString(),
    );

    await prefs.setString(
      'referredByCode',
      (user['referredByCode'] ?? '').toString(),
    );

    await prefs.setString(
      'referredByUserId',
      (user['referredByUserId'] ?? '').toString(),
    );

    await prefs.setDouble(
      'wanBucksBalance',
      ((user['wanBucksBalance'] ?? 0) as num).toDouble(),
    );

    await prefs.setBool(
      'referralRewardApplied',
      (user['referralRewardApplied'] ?? false) as bool,
    );

    await prefs.setString('createdAt', (user['createdAt'] ?? '').toString());
  }

  static Future<Map<String, dynamic>> requestPhoneUpdate(
    String phoneNumber,
  ) async {
    final idToken = await getValidIdToken();

    if (idToken == null || idToken.isEmpty) {
      return {
        'success': false,
        'message': 'Session expired. Please sign in again.',
      };
    }

    return await AuthController.requestPhoneUpdate(
      idToken: idToken,
      phoneNumber: phoneNumber,
    );
  }

  static Future<Map<String, dynamic>> verifyPhoneUpdate({
    required String phoneNumber,
    required String code,
  }) async {
    final idToken = await getValidIdToken();

    if (idToken == null || idToken.isEmpty) {
      return {
        'success': false,
        'message': 'Session expired. Please sign in again.',
      };
    }

    final result = await AuthController.verifyPhoneUpdate(
      idToken: idToken,
      phoneNumber: phoneNumber,
      code: code,
    );

    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phoneNumber', phoneNumber);
    }

    return result;
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    final idToken = await getValidIdToken();

    if (idToken == null || idToken.isEmpty) {
      return {
        'success': false,
        'message': 'Session expired. Please sign in again.',
      };
    }

    final result = await AuthController.deleteAccount(idToken);

    if (result['success'] == true) {
      await logout();
    }

    return result;
  }
}
