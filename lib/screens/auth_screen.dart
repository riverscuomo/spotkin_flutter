import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:spotkin_flutter/app_core.dart';

class AuthScreen extends StatefulWidget {
  final Map<String, dynamic> config;

  AuthScreen({required this.config});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final SpotifyService spotifyService;
  bool _isLoading = true;
  int _authAttempts = 0;
  static const int MAX_AUTH_ATTEMPTS = 3;

  @override
  void initState() {
    super.initState();
    spotifyService = SpotifyService(
      clientId: widget.config['SPOTIFY_CLIENT_ID']!,
      clientSecret: widget.config['SPOTIFY_CLIENT_SECRET']!,
      redirectUri: widget.config['SPOTIFY_REDIRECT_URI']!,
      scope: widget.config['SPOTIFY_SCOPE']!,
    );

    _checkExistingAuth();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleIncomingLink();
  }

  Future<void> _checkExistingAuth() async {
    setState(() => _isLoading = true);
    try {
      print('AUTHSCREEN: Checking existing authentication...');
      if (await spotifyService.checkAuthentication()) {
        print('AUTHSCREEN: Existing authentication is valid');
        _navigateToHomeScreen();
        return;
      }
    } catch (e) {
      print('AUTHSCREEN: Error checking existing auth: $e');
    }
    setState(() => _isLoading = false);
  }

  void _handleIncomingLink() {
    final uri = Uri.parse(ModalRoute.of(context)!.settings.name ?? '');
    if (uri.queryParameters.containsKey('access_token')) {
      final accessToken = uri.queryParameters['access_token']!;
      _handleAccessToken(accessToken);
    } else if (uri.queryParameters.containsKey('error')) {
      _showErrorSnackBar(
          'Authentication failed: ${uri.queryParameters['error']}');
    }
  }

  Future<void> _handleAccessToken(String accessToken) async {
    try {
      await spotifyService.setAccessToken(accessToken);
      _navigateToHomeScreen();
    } catch (e) {
      print('Error handling access token: $e');
      _showErrorSnackBar('Failed to set access token');
    }
  }

  Future<void> _navigateToHomeScreen() async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          config: widget.config,
          backendUrl: widget.config['BACKEND_URL']!,
        ),
      ),
    );
  }

  void _initiateSpotifyLogin() {
    final backendUrl = widget.config['BACKEND_URL']!;
    final loginUrl = '$backendUrl/spotify-login';
    Utils.myLaunch(loginUrl);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _initiateSpotifyLogin,
                    child: Text('Login with Spotify'),
                  ),
                  if (_authAttempts > 0)
                    Text(
                        'Authentication attempts: $_authAttempts/${MAX_AUTH_ATTEMPTS}'),
                ],
              ),
      ),
    );
  }
}
