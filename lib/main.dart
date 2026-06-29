import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wanmac/firebase_options.dart';
import 'package:wanmac/services/auth_service.dart';
import 'package:wanmac/views/screens/WelcomeScreen/app_entry_splash_screen.dart';
import 'package:wanmac/views/screens/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarDividerColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _restoreSession() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    final isLoggedIn = await AuthService.hasValidSession();

    if (isLoggedIn) {
      AuthService.startSavedSessionWatcher();
    }

    return isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'WANPADI',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E2FA8)),
      ),
      home: FutureBuilder<bool>(
        future: _restoreSession(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SplashScreen();
          }

          return snapshot.data == true
              ? const AppEntrySplashScreen()
              : const SplashScreen();
        },
      ),
    );
  }
}
