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

  static bool _isRefreshingSession = false;

  static const Duration _tokenRefreshBuffer = Duration(minutes: 5);
  static const Duration _refreshTokenDuration = Duration(days: 30);

  static Future<Map<String, dynamic>> signUp(SignUpRequest request) async {
    return AuthController.signUp(request);
  }

  static Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    return AuthController.resendOtp(phoneNumber);
  }

  static Future<Map<String, dynamic>> signInStart(
    SignInStartRequest request,
  ) async {
    return AuthController.signInStart(request);
  }

  static Future<Map<String, dynamic>> verifySignupOtpAndSaveUser(
    VerifyOtpRequest request,
  ) async {
    final result = await AuthController.verifyOtp(request);

    if (result['success'] != true) {
      return result;
    }

    final accessToken = (result['accessToken'] ?? '').toString();
    final idToken = (result['idToken'] ?? '').toString();
    final refreshToken = (result['refreshToken'] ?? '').toString();

    if (accessToken.isEmpty || idToken.isEmpty || refreshToken.isEmpty) {
      return {
        'success': false,
        'message': 'Missing authentication tokens after verification',
      };
    }

    try {
      await _saveTokens(
        accessToken: accessToken,
        idToken: idToken,
        refreshToken: refreshToken,
        isFreshLogin: true,
      );
    } catch (error) {
      return {
        'success': false,
        'message': 'Failed to save authentication session',
      };
    }

    final userResult = await AuthController.getUserDetails(idToken);

    if (userResult['success'] != true) {
      await logout(navigateToSplash: false);

      return {
        'success': false,
        'message': userResult['message'] ?? 'Failed to fetch user details',
      };
    }

    final rawUser = userResult['user'];

    if (rawUser is! Map) {
      await logout(navigateToSplash: false);

      return {
        'success': false,
        'message': 'Invalid user details returned from server',
      };
    }

    final user = Map<String, dynamic>.from(rawUser);

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

    if (result['success'] != true) {
      return result;
    }

    final accessToken = (result['accessToken'] ?? '').toString();
    final idToken = (result['idToken'] ?? '').toString();
    final refreshToken = (result['refreshToken'] ?? '').toString();

    if (accessToken.isEmpty || idToken.isEmpty || refreshToken.isEmpty) {
      return {
        'success': false,
        'message': 'Missing authentication tokens after sign in',
      };
    }

    try {
      await _saveTokens(
        accessToken: accessToken,
        idToken: idToken,
        refreshToken: refreshToken,
        isFreshLogin: true,
      );
    } catch (error) {
      return {
        'success': false,
        'message': 'Failed to save authentication session',
      };
    }

    final userResult = await AuthController.getUserDetails(idToken);

    if (userResult['success'] != true) {
      await logout(navigateToSplash: false);

      return {
        'success': false,
        'message': userResult['message'] ?? 'Failed to fetch user details',
      };
    }

    final rawUser = userResult['user'];

    if (rawUser is! Map) {
      await logout(navigateToSplash: false);

      return {
        'success': false,
        'message': 'Invalid user details returned from server',
      };
    }

    final user = Map<String, dynamic>.from(rawUser);

    await _saveUserToPrefs(user);

    return {
      'success': true,
      'message': result['message'] ?? 'Signin successful',
      'user': user,
    };
  }

  static Future<bool> refreshSession({bool navigateOnFailure = true}) async {
    if (_isRefreshingSession) {
      print('⏳ Session refresh already in progress');

      for (int attempt = 0; attempt < 20; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));

        if (!_isRefreshingSession) {
          final prefs = await SharedPreferences.getInstance();
          final idToken = prefs.getString('idToken') ?? '';
          final expiryString = prefs.getString('tokenExpiry');

          if (idToken.isEmpty || expiryString == null) {
            return false;
          }

          final expiry = DateTime.tryParse(expiryString);

          return expiry != null && DateTime.now().isBefore(expiry);
        }
      }

      return false;
    }

    _isRefreshingSession = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refreshToken') ?? '';

      print('🔄 Refreshing session...');

      if (refreshToken.isEmpty) {
        print('❌ Refresh token is missing');

        await logout(navigateToSplash: navigateOnFailure);

        return false;
      }

      final refreshExpiryString = prefs.getString('refreshTokenExpiry');

      if (refreshExpiryString != null) {
        final refreshExpiry = DateTime.tryParse(refreshExpiryString);

        if (refreshExpiry == null || !DateTime.now().isBefore(refreshExpiry)) {
          print('❌ Refresh token has reached its saved expiry');

          await logout(navigateToSplash: navigateOnFailure);

          return false;
        }
      }

      final result = await AuthController.refreshSession(refreshToken);

      if (result['success'] != true) {
        print(
          '❌ Session refresh failed: '
          '${result['message'] ?? 'Unknown error'}',
        );

        await logout(navigateToSplash: navigateOnFailure);

        return false;
      }

      final accessToken = (result['accessToken'] ?? '').toString();

      final idToken = (result['idToken'] ?? '').toString();

      final newRefreshToken = (result['refreshToken'] ?? '').toString();

      final refreshTokenToSave = newRefreshToken.isNotEmpty
          ? newRefreshToken
          : refreshToken;

      if (accessToken.isEmpty || idToken.isEmpty) {
        print('❌ Refreshed ID or access token is missing');

        await logout(navigateToSplash: navigateOnFailure);

        return false;
      }

      await _saveTokens(
        accessToken: accessToken,
        idToken: idToken,
        refreshToken: refreshTokenToSave,
        isFreshLogin: false,
      );

      print('✅ Session refreshed successfully');

      return true;
    } catch (error, stackTrace) {
      print('❌ Refresh session error: $error');
      print(stackTrace);

      await logout(navigateToSplash: navigateOnFailure);

      return false;
    } finally {
      _isRefreshingSession = false;
    }
  }

  static Future<String?> getValidIdToken() async {
    final prefs = await SharedPreferences.getInstance();

    final idToken = prefs.getString('idToken') ?? '';
    final expiryString = prefs.getString('tokenExpiry');
    final refreshToken = prefs.getString('refreshToken') ?? '';

    print('🔍 ID token exists: ${idToken.isNotEmpty}');
    print('🔍 Refresh token exists: ${refreshToken.isNotEmpty}');
    print('🔍 Token expiry: $expiryString');

    if (refreshToken.isEmpty) {
      print('❌ Missing refresh token');

      await logout();

      return null;
    }

    if (idToken.isEmpty || expiryString == null) {
      print('⚠️ ID token or token expiry missing');

      final refreshed = await refreshSession();

      if (!refreshed) {
        return null;
      }

      final updatedPrefs = await SharedPreferences.getInstance();

      return updatedPrefs.getString('idToken');
    }

    final expiry = DateTime.tryParse(expiryString);

    if (expiry == null) {
      print('⚠️ Invalid token expiry');

      final refreshed = await refreshSession();

      if (!refreshed) {
        return null;
      }

      final updatedPrefs = await SharedPreferences.getInstance();

      return updatedPrefs.getString('idToken');
    }

    final refreshAt = expiry.subtract(_tokenRefreshBuffer);

    if (!DateTime.now().isBefore(refreshAt)) {
      final refreshed = await refreshSession();

      if (!refreshed) {
        return null;
      }
    }

    final updatedPrefs = await SharedPreferences.getInstance();

    final updatedIdToken = updatedPrefs.getString('idToken') ?? '';

    if (updatedIdToken.isEmpty) {
      return null;
    }

    return updatedIdToken;
  }

  static Future<bool> hasValidSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final idToken = prefs.getString('idToken') ?? '';
      final refreshToken = prefs.getString('refreshToken') ?? '';

      final expiryString = prefs.getString('tokenExpiry');

      final refreshExpiryString = prefs.getString('refreshTokenExpiry');

      if (refreshToken.isEmpty) {
        print('❌ No refresh token saved');
        return false;
      }

      if (refreshExpiryString == null) {
        print('⚠️ Refresh expiry missing, recreating it');

        final fallbackRefreshExpiry = DateTime.now().add(_refreshTokenDuration);

        await prefs.setString(
          'refreshTokenExpiry',
          fallbackRefreshExpiry.toIso8601String(),
        );

        _startRefreshTokenExpiryTimer(fallbackRefreshExpiry);
      } else {
        final refreshExpiry = DateTime.tryParse(refreshExpiryString);

        if (refreshExpiry == null) {
          print('❌ Invalid refresh token expiry');

          await logout(navigateToSplash: false);

          return false;
        }

        if (!DateTime.now().isBefore(refreshExpiry)) {
          print('❌ Refresh token has expired');

          await logout(navigateToSplash: false);

          return false;
        }
      }

      if (idToken.isNotEmpty && expiryString != null) {
        final idTokenExpiry = DateTime.tryParse(expiryString);

        if (idTokenExpiry != null) {
          final refreshAt = idTokenExpiry.subtract(_tokenRefreshBuffer);

          if (DateTime.now().isBefore(refreshAt)) {
            print('✅ Existing ID token is still valid');

            return true;
          }
        }
      }

      print(
        '🔄 ID token expired or close to expiry. '
        'Trying refresh token...',
      );

      return refreshSession(navigateOnFailure: false);
    } catch (error, stackTrace) {
      print('❌ Session restore error: $error');
      print(stackTrace);

      return false;
    }
  }

  static Future<void> startSavedSessionWatcher() async {
    final prefs = await SharedPreferences.getInstance();

    final expiryString = prefs.getString('tokenExpiry');

    final refreshExpiryString = prefs.getString('refreshTokenExpiry');

    if (expiryString == null) {
      print('⚠️ No ID token expiry available');

      final refreshed = await refreshSession(navigateOnFailure: false);

      if (!refreshed) {
        return;
      }
    }

    final updatedPrefs = await SharedPreferences.getInstance();

    final updatedExpiryString = updatedPrefs.getString('tokenExpiry');

    if (updatedExpiryString != null) {
      final expiry = DateTime.tryParse(updatedExpiryString);

      if (expiry != null) {
        _startSessionRefreshTimer(expiry);
      }
    }

    if (refreshExpiryString != null) {
      final refreshExpiry = DateTime.tryParse(refreshExpiryString);

      if (refreshExpiry != null) {
        _startRefreshTokenExpiryTimer(refreshExpiry);
      }
    }
  }

  static void _startSessionRefreshTimer(DateTime expiry) {
    _sessionRefreshTimer?.cancel();

    final refreshAt = expiry.subtract(_tokenRefreshBuffer);

    final duration = refreshAt.difference(DateTime.now());

    print('⏳ ID token refresh scheduled in: $duration');

    if (duration.isNegative || duration.inSeconds <= 0) {
      Future<void>.microtask(() async {
        await refreshSession();
      });

      return;
    }

    _sessionRefreshTimer = Timer(duration, () async {
      final refreshed = await refreshSession();

      if (!refreshed) {
        print('❌ Scheduled session refresh failed');
      }
    });
  }

  static void _startRefreshTokenExpiryTimer(DateTime expiry) {
    _refreshTokenExpiryTimer?.cancel();

    final duration = expiry.difference(DateTime.now());

    print('🗓 Refresh token expires/logs out in: $duration');

    if (duration.isNegative || duration.inSeconds <= 0) {
      Future<void>.microtask(() async {
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

    _isRefreshingSession = false;

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
      throw Exception('Unable to parse ID token expiry');
    }

    if (isFreshLogin || prefs.getString('refreshTokenExpiry') == null) {
      final refreshTokenExpiry = DateTime.now().add(_refreshTokenDuration);

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

      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);

      final decoded = utf8.decode(base64Url.decode(normalized));

      final map = jsonDecode(decoded) as Map<String, dynamic>;

      final exp = map['exp'];

      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }

      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      }

      return null;
    } catch (error) {
      print('❌ Failed to decode JWT expiry: $error');

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

    final wanBucksValue = user['wanBucksBalance'];

    final wanBucksBalance = wanBucksValue is num
        ? wanBucksValue.toDouble()
        : double.tryParse(wanBucksValue?.toString() ?? '') ?? 0.0;

    await prefs.setDouble('wanBucksBalance', wanBucksBalance);

    await prefs.setBool(
      'referralRewardApplied',
      user['referralRewardApplied'] == true,
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

    return AuthController.requestPhoneUpdate(
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
