import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'theme/app_theme.dart';
import 'layout/app_layout.dart';

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = _MyHttpOverrides();

  // Configure status bar for Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize database factory based on platform
  if (kIsWeb) {
    // Web: use the FFI web factory
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isAndroid || Platform.isIOS) {
    // Mobile: use the default sqflite factory (native implementation)
    // sqflite plugin handles Android/iOS natively via the native SQLite library
    // No FFI initialization needed
  } else {
    // Desktop (Windows/macOS/Linux): use the FFI factory
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const ProviderScope(child: ShiningPersonalApp()));
}

class ShiningPersonalApp extends StatelessWidget {
  const ShiningPersonalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '生活工作台',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
    );
  }
}
