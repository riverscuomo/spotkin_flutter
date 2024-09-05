import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:spotkin_flutter/app_core.dart';

class AuthScreen extends StatefulWidget {
  final Map<String, dynamic> config;

  AuthScreen({required this.config});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Automatically initiate login flow on screen load
    _initiateSpotifyLogin();
  }

  Future<void> _initiateSpotifyLogin() async {
    setState(() => _isLoading = true);

    // 1. Build the Spotify OAuth URL
    final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': widget.config['SPOTIFY_CLIENT_ID'],
      'response_type': 'token', // Use 'code' if using authorization code flow
      'redirect_uri':
          'http://localhost:8888/auth.html', // Your registered redirect URI
      'scope': widget.config['SPOTIFY_SCOPE'],
    });

    try {
      // 2. Start the OAuth process using flutter_web_auth_2
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'http', // The scheme used in your redirect URI
      );

      // 3. Extract the access token from the result
      final fragment = Uri.parse(result).fragment;
      final accessToken = Uri.splitQueryString(fragment)['access_token'];

      if (accessToken != null) {
        print('Access token: $accessToken');
        _handleAccessToken(accessToken); // Handle the access token
      } else {
        print('Failed to extract access token');
      }
    } catch (e) {
      print('Error during Spotify login: $e');
      _showErrorSnackBar('Failed to login with Spotify');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAccessToken(String accessToken) async {
    // Handle storing the access token and navigate to the home screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(config: widget.config),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _initiateSpotifyLogin,
                child: const Text('Login with Spotify'),
              ),
      ),
    );
  }
}
