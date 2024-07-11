import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'screens/screens.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy()); // Use path URL strategy
  Map<String, dynamic> config = await loadConfig();
  String sampleJobs = await loadSampleJobs();
  runApp(MyApp(config, sampleJobs));
}
Future<Map<String, dynamic>> loadConfig() async {
  String configString = await rootBundle.loadString('assets/config.json');
  return jsonDecode(configString);
}

Future<String> loadSampleJobs() async {
  return await rootBundle.loadString('assets/sample_jobs.json');
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> config;
  final String sampleJobs;

  MyApp(this.config, this.sampleJobs);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Spotify Web Auth',
      theme: ThemeData(primarySwatch: Colors.blue),
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            builder: (context) => MyHomePage(config: config, sampleJobs: sampleJobs),
          );
        }
        // Handle Spotify callback
        if (settings.name!.startsWith('/?code=')) {
          final uri = Uri.parse(settings.name!);
          final code = uri.queryParameters['code'];
          return MaterialPageRoute(
            builder: (context) => MyHomePage(
              config: config,
              sampleJobs: sampleJobs,
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
  final String sampleJobs;
  final String? initialAuthCode;

  MyHomePage({required this.config, required this.sampleJobs, this.initialAuthCode});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final String clientId;
  late final String clientSecret;
  late final String redirectUri;
  late final String scope;
  late final String backendUrl;
  late final String sampleJobs;

  @override
  void initState() {
    super.initState();
    clientId = widget.config['SPOTIFY_CLIENT_ID']!;
    clientSecret = widget.config['SPOTIFY_CLIENT_SECRET']!;
    redirectUri = widget.config['SPOTIFY_REDIRECT_URI']!;
    scope = widget.config['SPOTIFY_SCOPE']!;
    backendUrl = widget.config['BACKEND_URL']!;
    sampleJobs = widget.sampleJobs;

    if (widget.initialAuthCode != null) {
      _exchangeCodeForToken(widget.initialAuthCode!);
    }
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
      print('Access Token: $accessToken');
      
      // Navigate to UpdatePlaylistsScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => UpdatePlaylistsScreen(
            accessToken: accessToken,
            backendUrl: backendUrl,
            sampleJobs: sampleJobs,
          ),
        ),
      );
    } else {
      print('Failed to exchange code for token: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to authenticate with Spotify')),
      );
    }
  }

  void _initiateSpotifyLogin() {
    final spotifyAuthUrl =
        'https://accounts.spotify.com/authorize?client_id=$clientId&response_type=code&redirect_uri=${Uri.encodeComponent(redirectUri)}&scope=$scope';

    print('Redirecting to: $spotifyAuthUrl');
    html.window.location.href = spotifyAuthUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Spotify Auth Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: _initiateSpotifyLogin,
          child: Text('Login with Spotify'),
        ),
      ),
    );
  }
}
