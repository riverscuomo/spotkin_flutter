// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:provider/provider.dart';
import 'package:spotkin_flutter/app_core.dart';

import 'helpers/load_config.dart';
import 'spotify_theme_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // kIsWeb ? setUrlStrategy(PathUrlStrategy()) : null;
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
        /// The order of providers is important, as some depend on others. You can't use a provider before it's created.
        /// You can't put these in alphabetical order, for example, because `BackendService` depends on `SpotifyService`.
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
