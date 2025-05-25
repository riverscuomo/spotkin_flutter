import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotkin_flutter/app_core.dart';
import 'helpers/load_config.dart';
import 'spotify_theme_data.dart';
import 'ui/widgets/debug_label_wrapper.dart';

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
        ChangeNotifierProvider(
            create: (_) =>
                JobProvider()), // Ensure this is ChangeNotifierProvider
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
      title: 'Spotkin',
      theme: spotifyThemeData,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Container(
          color: Colors.black,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 750),
              child: child!,
            ),
          ).withDebugLabel('CenterWrapper'),
        ).withDebugLabel('RootContainer');
      },
      // Initial route should just navigate to the auth screen without URL parsing
      initialRoute: '/',
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) =>
              AuthScreen(config: config).withDebugLabel('AuthScreen'),
        );
      },
    );
  }
}
