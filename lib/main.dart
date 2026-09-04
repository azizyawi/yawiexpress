import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanmac/firebase_options.dart';
import 'package:wanmac/services/auth_service.dart';
import 'package:wanmac/views/screens/WelcomeScreen/app_entry_splash_screen.dart';
import 'package:wanmac/views/screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

const _systemBarStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarBrightness: Brightness.light,
  statusBarIconBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.white,
  systemNavigationBarDividerColor: Colors.white,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

Future<bool> _restoreSession() async {
  return await AuthService.hasValidSession();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  SystemChrome.setSystemUIOverlayStyle(_systemBarStyle);

  final isLoggedIn = await _restoreSession();

  if (isLoggedIn) {
    await AuthService.startSavedSessionWatcher();
  }

  runApp(
    ProviderScope(
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Wanpadi',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E2FA8),
        ),
      ),

      // Paint white behind Android's system navigation buttons.
      // Keep screens above this area, even in edge-to-edge mode.
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _systemBarStyle,
          child: ColoredBox(
            color: Colors.white,
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },

      home: isLoggedIn
          ? const AppEntrySplashScreen()
          : const SplashScreen(),
    );
  }
}