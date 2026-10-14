import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/root_shell.dart';
import 'widgets/adaptive.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.create();
  runApp(ChangeNotifierProvider<AppState>.value(value: state, child: const KickerApp()));
}

class KickerApp extends StatelessWidget {
  const KickerApp({super.key});

  static const _delegates = <LocalizationsDelegate<dynamic>>[
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
  static const _locales = [Locale('de'), Locale('en')];

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      // Systemblau als Akzentfarbe — genau wie die bisherige SwiftUI-App (kein eigener AccentColor).
      return const CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: 'Kicker-App',
        theme: CupertinoThemeData(primaryColor: CupertinoColors.systemBlue),
        localizationsDelegates: _delegates,
        supportedLocales: _locales,
        home: RootShell(),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kicker-App',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: Colors.green, brightness: Brightness.dark, useMaterial3: true),
      localizationsDelegates: _delegates,
      supportedLocales: _locales,
      home: const RootShell(),
    );
  }
}
