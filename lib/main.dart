import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'screens/screens.dart';

const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy()); // Use path URL strategy
  Map<String, dynamic> config = await loadConfig();
  String jobs = await loadJobs();
  runApp(MyApp(config, jobs));
}

Future<Map<String, dynamic>> loadConfig() async {
  String configString = await rootBundle.loadString('assets/config.json');
  print('Loaded config: $configString');
  Map<String, dynamic> config = jsonDecode(configString);
  return config;
}

Future<String> loadJobs() async {
  return await rootBundle.loadString('assets/sample_jobs.json');
}

Future<String?> _getAccessToken() async {
  return await _secureStorage.read(key: 'accessToken');
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> config;
  final String jobs;

  MyApp(this.config, this.jobs);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Spotify Web Auth',
      theme: ThemeData(primarySwatch: Colors.blue),
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => MyHomePage(config: config, jobs: jobs),
          );
        }
        // Handle Spotify callback
        if (settings.name!.startsWith('/?code=')) {
          final uri = Uri.parse(settings.name!);
          final code = uri.queryParameters['code'];
          return MaterialPageRoute(
            builder: (context) => MyHomePage(
              config: config,
              jobs: jobs,
              initialAuthCode: code,
            ),
          );
        }
        return null;
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Map<String, dynamic> config;
  final String jobs;
  final String? initialAuthCode;

  MyHomePage({required this.config, required this.jobs, this.initialAuthCode});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final String clientId;
  late final String clientSecret;
  final String redirectUri = kReleaseMode
      ? 'https://spotkin-fd416.web.app'
      : 'http://localhost:8888';
  final String scope =
      "playlist-modify-private playlist-modify-public user-library-read playlist-read-private user-library-modify user-read-recently-played";
  final String backendUrl="https://spotkin-1b998975756a.herokuapp.com";
  late final String jobs;
  late final String accessToken;

  @override
  void initState() {
    super.initState();
    clientId = widget.config['SPOTIFY_CLIENT_ID']!;
    clientSecret = widget.config['SPOTIFY_CLIENT_SECRET']!;
    // redirectUri = widget.config['SPOTIFY_REDIRECT_URI']!;
    // scope = widget.config['SPOTIFY_SCOPE']!;
    // backendUrl = widget.config['BACKEND_URL']!;
    jobs = widget.jobs;

    print('Loaded config:');
    print('Redirect URI: $redirectUri');

    if (widget.initialAuthCode != null) {
      _exchangeCodeForToken(widget.initialAuthCode!);
    }

    _getAccessToken().then((value) {
      if (value != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => UpdatePlaylistsScreen(
              accessToken: value,
              backendUrl: backendUrl,
              jobs: jobs,
            ),
          ),
        );
      }
    });
  }

  Future<void> _exchangeCodeForToken(String code) async {
    final tokenEndpoint = Uri.parse('https://accounts.spotify.com/api/token');
    final response = await http.post(
      tokenEndpoint,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final tokenData = json.decode(response.body);
      final accessToken = tokenData['access_token'];
      await _secureStorage.write(key: 'accessToken', value: accessToken);
      print('Access Token: $accessToken');

      // Navigate to UpdatePlaylistsScreen
      print('now navigating to UpdatePlaylistsScreen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => UpdatePlaylistsScreen(
            accessToken: accessToken,
            backendUrl: backendUrl,
            jobs: jobs,
          ),
        ),
      );
    } else {
      print('Failed to exchange code for token: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to authenticate with Spotify')),
      );
    }
  }

  void _initiateSpotifyLogin() {
    final spotifyAuthUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': scope,
    });

    print('Redirecting to: $spotifyAuthUrl');
    html.window.location.href = spotifyAuthUrl.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spotify Auth Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: _initiateSpotifyLogin,
          child: const Text('Login with Spotify'),
        ),
      ),
    );
  }
}
