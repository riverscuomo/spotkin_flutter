import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:spotkin_flutter/app_core.dart';

import 'helpers/load_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setUrlStrategy(PathUrlStrategy()); // Use path URL strategy
  Map<String, dynamic> config = await loadConfig();

  setupServiceLocator(config: config);
  // await getIt.allReady(); // Wait for all async registrations
  String jobs = await loadJobs();
  runApp(MyApp(config, jobs));
}

Future<String> loadJobs() async {
  return await rootBundle.loadString('assets/sample_jobs.json');
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> config;
  final String jobs;

  MyApp(this.config, this.jobs);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Spotify Web Auth',
      theme: spotifyThemeData,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Container(
          color: Colors.black, // Match your scaffold background color
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 700),
              child: child!,
            ),
          ),
        );
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => AuthScreen(config: config),
          );
        }
        // Handle Spotify callback
        if (settings.name!.startsWith('/?')) {
          final uri = Uri.parse(settings.name!);
          final code = uri.queryParameters['code'];
          final error = uri.queryParameters['error'];

          if (code != null) {
            print('Received Spotify callback with authorization code: $code');
            return MaterialPageRoute(
              builder: (context) => AuthScreen(
                config: config,
                initialAuthCode: code,
              ),
            );
          } else if (error != null) {
            print('Received Spotify callback with error: $error');
            return MaterialPageRoute(
              builder: (context) => AuthScreen(
                config: config,
                initialError: error,
              ),
            );
          }
        }
        return null;
      },
    );
  }
}

final spotifyThemeData = ThemeData(
  primarySwatch: Colors.green,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF121212),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF121212),
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
  ),
  textTheme: const TextTheme(
    headline6: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    bodyText2: TextStyle(color: Colors.white70),
    subtitle1: TextStyle(color: Colors.white54),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: const Color(0xFF212121),
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    labelStyle: const TextStyle(color: Colors.white54),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  dividerTheme: const DividerThemeData(
    color: Colors.white10,
    thickness: 1,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Colors.green),
      foregroundColor: MaterialStateProperty.all(Colors.white),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
  ),
  listTileTheme: const ListTileThemeData(
    tileColor: Color(0xFF212121),
    textColor: Colors.white,
    iconColor: Colors.white54,
  ),
  expansionTileTheme: const ExpansionTileThemeData(
    backgroundColor: Color(0xFF212121),
    collapsedBackgroundColor: Color(0xFF212121),
    textColor: Colors.white,
    collapsedTextColor: Colors.white,
    iconColor: Colors.white,
    collapsedIconColor: Colors.white,
  ),
);
