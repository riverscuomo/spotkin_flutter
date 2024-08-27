import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:provider/provider.dart';
import 'package:spotkin_flutter/app_core.dart';

import 'helpers/load_config.dart';
import 'spotify_theme_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setUrlStrategy(PathUrlStrategy());
  Map<String, dynamic> config = await loadConfig();
  setupServiceLocator(config: config);

  final backendService = BackendService(
    backendUrl: config['BACKEND_URL'],
    accessToken: '', // Initialize with an empty string
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<BackendService>.value(value: backendService),
        ChangeNotifierProxyProvider<BackendService, JobProvider>(
          create: (context) => JobProvider(backendService),
          update: (context, backendService, previous) =>
              previous ?? JobProvider(backendService),
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
