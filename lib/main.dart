import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotkin_flutter/app_core.dart';

import 'helpers/load_config.dart';
import 'spotify_theme_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> config = await loadConfig();

  // Add checks for required config values
  assert(config.containsKey('SPOTIFY_CLIENT_ID'),
      'SPOTIFY_CLIENT_ID is missing from config');
  assert(config.containsKey('SPOTIFY_CLIENT_SECRET'),
      'SPOTIFY_CLIENT_SECRET is missing from config');
  assert(config.containsKey('SPOTIFY_REDIRECT_URI'),
      'SPOTIFY_REDIRECT_URI is missing from config');
  assert(config.containsKey('SPOTIFY_SCOPE'),
      'SPOTIFY_SCOPE is missing from config');
  assert(
      config.containsKey('BACKEND_URL'), 'BACKEND_URL is missing from config');

  setupServiceLocator(config: config);

  runApp(
    MultiProvider(
      providers: [
        Provider<SpotifyService>(
          create: (context) => SpotifyService(
            clientId: config['SPOTIFY_CLIENT_ID']!,
            clientSecret: config['SPOTIFY_CLIENT_SECRET']!,
            redirectUri: config['SPOTIFY_REDIRECT_URI']!,
            scope: config['SPOTIFY_SCOPE']!,
          ),
        ),
        Provider<BackendService>(
          create: (context) => BackendService(
            backendUrl: config['BACKEND_URL']!,
            spotifyService: context.read<SpotifyService>(),
          ),
        ),
        Provider<JobProvider>(
          create: (context) => JobProvider(
            context.read<BackendService>(),
          ),
        ),
      ],
      child: MyApp(config),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> config;

  const MyApp(this.config, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Spotify Web Auth',
      theme: spotifyThemeData,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Container(
          color: Colors.black,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: child!,
            ),
          ),
        );
      },
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        if (uri.path == '/') {
          if (uri.queryParameters.containsKey('access_token') ||
              uri.queryParameters.containsKey('error')) {
            // This is a callback from Spotify
            return MaterialPageRoute(
              builder: (context) => AuthScreen(config: config),
              settings: settings,
            );
          } else {
            // Normal root route
            return MaterialPageRoute(
              builder: (context) => AuthScreen(config: config),
            );
          }
        }
        // Handle other routes here if needed
        return null;
      },
    );
  }
}
