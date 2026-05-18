import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_client.dart';
import 'pages/login_page.dart';
import 'pages/main_shell.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  await ApiClient().init();
  ApiClient().onUnauthorized = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  };
  runApp(const WhisperApp());
}

class WhisperApp extends StatelessWidget {
  const WhisperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whisper',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      themeMode: ThemeMode.light,
      home: ApiClient().isLoggedIn ? const MainShell() : const LoginPage(),
    );
  }
}
