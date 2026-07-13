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
  static const Duration _refreshRetryDelay = Duration(minutes: 2);

  // ========================= SIGN UP =========================

  static Future<Map<String, dynamic>> signUp(SignUpRequest request) async {
    return AuthController.signUp(request);
  }

  static Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    return AuthController.resendOtp(phoneNumber);
  }

  // ========================= SIGN IN =========================

  static Future<Map<String, dynamic>> signInStart(
    SignInStartRequest request,
  ) async {
    return AuthController.signInStart(request);
  }

  // ========================= VERIFY SIGNUP OTP =========================

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
    } catch (error, stackTrace) {
      debugPrint('❌ Failed to save signup session: $error');
      debugPrintStack(stackTrace: stackTrace);

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

  // ========================= VERIFY SIGNIN OTP =========================

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
    } catch (error, stackTrace) {
      debugPrint('❌ Failed to save signin session: $error');
      debugPrintStack(stackTrace: stackTrace);

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

  // ========================= REFRESH SESSION =========================

  static Future<bool> refreshSession({
    bool navigateOnFailure = true,
    bool logoutOnFailure = false,
  }) async {
    if (_isRefreshingSession) {
      debugPrint('⏳ Session refresh already in progress');

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

      debugPrint('🔄 Refreshing customer session...');

      if (refreshToken.isEmpty) {
        debugPrint('❌ Refresh token is missing');

        if (logoutOnFailure) {
          await logout(navigateToSplash: navigateOnFailure);
        }

        return false;
      }

      final refreshExpiryString = prefs.getString('refreshTokenExpiry');

      if (refreshExpiryString != null) {
        final refreshExpiry = DateTime.tryParse(refreshExpiryString);

        if (refreshExpiry == null) {
          debugPrint(
            '⚠️ Invalid local refresh-token expiry. '
            'Removing only the invalid expiry metadata.',
          );

          await prefs.remove('refreshTokenExpiry');
        } else if (!DateTime.now().isBefore(refreshExpiry)) {
          debugPrint('❌ Refresh token has expired');

          await logout(navigateToSplash: navigateOnFailure);

          return false;
        }
      }

      final result = await AuthController.refreshSession(refreshToken);

      if (result['success'] != true) {
        final message = (result['message'] ?? 'Unknown refresh error')
            .toString();

        debugPrint('❌ Session refresh failed: $message');

        if (_isPermanentRefreshFailure(message)) {
          debugPrint(
            '🚪 Refresh token was rejected permanently. '
            'Logging customer out.',
          );

          await logout(navigateToSplash: navigateOnFailure);
        } else if (logoutOnFailure) {
          await logout(navigateToSplash: navigateOnFailure);
        } else {
          debugPrint(
            '⚠️ Temporary refresh failure. '
            'Keeping saved session.',
          );

          _scheduleRefreshRetry();
        }

        return false;
      }

      final accessToken = (result['accessToken'] ?? '').toString();

      final idToken = (result['idToken'] ?? '').toString();

      final returnedRefreshToken = (result['refreshToken'] ?? '').toString();

      final refreshTokenToSave = returnedRefreshToken.isNotEmpty
          ? returnedRefreshToken
          : refreshToken;

      if (accessToken.isEmpty || idToken.isEmpty) {
        debugPrint('❌ Refresh response is missing the ID or access token');

        _scheduleRefreshRetry();

        return false;
      }

      await _saveTokens(
        accessToken: accessToken,
        idToken: idToken,
        refreshToken: refreshTokenToSave,
        isFreshLogin: false,
      );

      debugPrint('✅ Customer session refreshed successfully');

      return true;
    } catch (error, stackTrace) {
      debugPrint('❌ Temporary customer session refresh error: $error');

      debugPrintStack(stackTrace: stackTrace);

      // Do not remove the refresh token because of:
      // - no internet
      // - timeout
      // - temporary server error
      // - app background restrictions
      _scheduleRefreshRetry();

      return false;
    } finally {
      _isRefreshingSession = false;
    }
  }

  static bool _isPermanentRefreshFailure(String message) {
    final normalized = message.toLowerCase();

    return normalized.contains('refresh token has expired') ||
        normalized.contains('refresh token expired') ||
        normalized.contains('invalid refresh token') ||
        normalized.contains('refresh token is invalid') ||
        normalized.contains('refresh token revoked') ||
        normalized.contains('notauthorizedexception') ||
        normalized.contains('not authorized') ||
        normalized.contains('user not found') ||
        normalized.contains('user does not exist');
  }

  // ========================= GET VALID ID TOKEN =========================

  static Future<String?> getValidIdToken() async {
    final prefs = await SharedPreferences.getInstance();

    final idToken = prefs.getString('idToken') ?? '';
    final expiryString = prefs.getString('tokenExpiry');
    final refreshToken = prefs.getString('refreshToken') ?? '';

    debugPrint('🔍 ID token exists: ${idToken.isNotEmpty}');
    debugPrint('🔍 Refresh token exists: ${refreshToken.isNotEmpty}');
    debugPrint('🔍 ID token expiry: $expiryString');

    if (refreshToken.isEmpty) {
      debugPrint('❌ Missing refresh token');

      await logout();

      return null;
    }

    if (idToken.isEmpty || expiryString == null) {
      debugPrint('⚠️ ID token or token expiry missing. Trying refresh.');

      final refreshed = await refreshSession(
        navigateOnFailure: false,
        logoutOnFailure: false,
      );

      if (!refreshed) {
        return null;
      }

      final updatedPrefs = await SharedPreferences.getInstance();

      return updatedPrefs.getString('idToken');
    }

    final expiry = DateTime.tryParse(expiryString);

    if (expiry == null) {
      debugPrint('⚠️ Invalid ID token expiry. Trying refresh.');

      final refreshed = await refreshSession(
        navigateOnFailure: false,
        logoutOnFailure: false,
      );

      if (!refreshed) {
        return null;
      }

      final updatedPrefs = await SharedPreferences.getInstance();

      return updatedPrefs.getString('idToken');
    }

    final refreshAt = expiry.subtract(_tokenRefreshBuffer);

    if (!DateTime.now().isBefore(refreshAt)) {
      final refreshed = await refreshSession(
        navigateOnFailure: false,
        logoutOnFailure: false,
      );

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

  // ========================= RESTORE SESSION =========================

  static Future<bool> hasValidSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final idToken = prefs.getString('idToken') ?? '';
      final refreshToken = prefs.getString('refreshToken') ?? '';

      final expiryString = prefs.getString('tokenExpiry');

      final refreshExpiryString = prefs.getString('refreshTokenExpiry');

      if (refreshToken.isEmpty) {
        debugPrint('❌ No refresh token saved');

        return false;
      }

      if (refreshExpiryString == null) {
        debugPrint('⚠️ Refresh expiry missing. Creating local fallback.');

        final fallbackRefreshExpiry = DateTime.now().add(_refreshTokenDuration);

        await prefs.setString(
          'refreshTokenExpiry',
          fallbackRefreshExpiry.toIso8601String(),
        );

        _startRefreshTokenExpiryTimer(fallbackRefreshExpiry);
      } else {
        final refreshExpiry = DateTime.tryParse(refreshExpiryString);

        if (refreshExpiry == null) {
          debugPrint(
            '⚠️ Invalid refresh expiry metadata. '
            'The app will verify the token with the backend.',
          );

          await prefs.remove('refreshTokenExpiry');
        } else if (!DateTime.now().isBefore(refreshExpiry)) {
          debugPrint('❌ Saved refresh token has expired');

          await logout(navigateToSplash: false);

          return false;
        }
      }

      if (idToken.isNotEmpty && expiryString != null) {
        final idTokenExpiry = DateTime.tryParse(expiryString);

        if (idTokenExpiry != null) {
          final refreshAt = idTokenExpiry.subtract(_tokenRefreshBuffer);

          if (DateTime.now().isBefore(refreshAt)) {
            debugPrint('✅ Existing customer ID token is valid');

            return true;
          }
        }
      }

      debugPrint(
        '🔄 ID token expired or is close to expiry. '
        'Trying refresh token.',
      );

      return refreshSession(navigateOnFailure: false, logoutOnFailure: false);
    } catch (error, stackTrace) {
      debugPrint('❌ Session restore error: $error');
      debugPrintStack(stackTrace: stackTrace);

      // Do not erase saved tokens because restoration
      // failed during a temporary application error.
      return false;
    }
  }

  // ========================= SESSION WATCHER =========================

  static Future<void> startSavedSessionWatcher() async {
    final prefs = await SharedPreferences.getInstance();

    final expiryString = prefs.getString('tokenExpiry');
    final refreshExpiryString = prefs.getString('refreshTokenExpiry');

    if (expiryString == null) {
      debugPrint('⚠️ No ID-token expiry available. Trying refresh.');

      final refreshed = await refreshSession(
        navigateOnFailure: false,
        logoutOnFailure: false,
      );

      if (!refreshed) {
        _scheduleRefreshRetry();
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

    debugPrint('⏳ Customer ID-token refresh scheduled in: $duration');

    if (duration.isNegative || duration.inSeconds <= 0) {
      Future<void>.microtask(() async {
        final refreshed = await refreshSession(
          navigateOnFailure: false,
          logoutOnFailure: false,
        );

        if (!refreshed) {
          debugPrint(
            '⚠️ Immediate session refresh was unsuccessful. '
            'Session was preserved.',
          );
        }
      });

      return;
    }

    _sessionRefreshTimer = Timer(duration, () async {
      final refreshed = await refreshSession(
        navigateOnFailure: false,
        logoutOnFailure: false,
      );

      if (!refreshed) {
        debugPrint(
          '⚠️ Scheduled session refresh failed. '
          'Saved refresh token was preserved.',
        );
      }
    });
  }

  static void _scheduleRefreshRetry() {
    _sessionRefreshTimer?.cancel();

    debugPrint(
      '⏳ Session refresh retry scheduled in: '
      '$_refreshRetryDelay',
    );

    _sessionRefreshTimer = Timer(_refreshRetryDelay, () async {
      final refreshed = await refreshSession(
        navigateOnFailure: false,
        logoutOnFailure: false,
      );

      if (!refreshed) {
        debugPrint('⚠️ Session refresh retry was unsuccessful');
      }
    });
  }

  static void _startRefreshTokenExpiryTimer(DateTime expiry) {
    _refreshTokenExpiryTimer?.cancel();

    final duration = expiry.difference(DateTime.now());

    debugPrint('🗓 Customer refresh token expires in: $duration');

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

  // ========================= LOGOUT =========================

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

  // ========================= SAVE TOKENS =========================

  static Future<void> _saveTokens({
    required String accessToken,
    required String idToken,
    required String refreshToken,
    required bool isFreshLogin,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final tokenExpiry = _extractJwtExpiry(idToken);

    if (tokenExpiry == null) {
      throw Exception('Unable to parse ID-token expiry');
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

  // ========================= JWT EXPIRY =========================

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
      debugPrint('❌ Failed to decode JWT expiry: $error');

      return null;
    }
  }

  // ========================= SAVE USER =========================

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

  // ========================= PHONE UPDATE =========================

  static Future<Map<String, dynamic>> requestPhoneUpdate(
    String phoneNumber,
  ) async {
    final idToken = await getValidIdToken();

    if (idToken == null || idToken.isEmpty) {
      return {
        'success': false,
        'message':
            'Session could not be refreshed. Please check your connection.',
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
        'message':
            'Session could not be refreshed. Please check your connection.',
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

  // ========================= DELETE ACCOUNT =========================

  static Future<Map<String, dynamic>> deleteAccount() async {
    final idToken = await getValidIdToken();

    if (idToken == null || idToken.isEmpty) {
      return {
        'success': false,
        'message':
            'Session could not be refreshed. Please check your connection.',
      };
    }

    final result = await AuthController.deleteAccount(idToken);

    if (result['success'] == true) {
      await logout();
    }

    return result;
  }
}
