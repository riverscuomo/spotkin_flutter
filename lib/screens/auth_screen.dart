import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:spotkin_flutter/app_core.dart';

class AuthScreen extends StatefulWidget {
  final Map<String, dynamic> config;
  final String? initialAuthCode;
  final String? initialError;

  AuthScreen({required this.config, this.initialAuthCode, this.initialError});

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

    if (widget.initialAuthCode != null) {
      _handleAuthCode(widget.initialAuthCode!);
    } else if (widget.initialError != null) {
      _showErrorSnackBar('Authentication failed: ${widget.initialError}');
    }
  }

  Future<void> _handleAuthCode(String code) async {
    print('AUTHSCREEN: Handling auth code: $code');
    if (_authAttempts >= MAX_AUTH_ATTEMPTS) {
      _showErrorSnackBar(
          'Too many authentication attempts. Please try again later.');
      return;
    }

    _authAttempts++;

    try {
      print(
          'AUTHSCREEN: Exchanging auth code for token (Attempt $_authAttempts)...');
      await spotifyService.exchangeCodeForToken(code);
      print('AUTHSCREEN: Token exchange successful');
      _navigateToHomeScreen();
    } catch (e) {
      print('AUTHSCREEN: Error exchanging code for token: $e');
      _showErrorSnackBar('Failed to authenticate with Spotify');
    }
  }

  Future<void> _navigateToHomeScreen() async {
    print('AuthScreen: Navigating to Home Screen...');
    try {
      final credentials = await spotifyService.retrieveCredentials();
      if (credentials == null || credentials.accessToken == null) {
        throw Exception('No valid credentials available');
      }

      final accessToken = credentials.accessToken!;
      print(
          'Navigating to Home Screen with access token: ${accessToken.substring(0, 10)}...');

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            config: widget.config,
            accessToken: accessToken,
            backendUrl: widget.config['BACKEND_URL']!,
          ),
        ),
      );
    } catch (e) {
      print('AuthScreen: Failed to navigate: $e');
      _showErrorSnackBar('Authentication failed');
    }
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
                    child: Column(
                      children: [
                        const Text('Login with Spotify'),
                        Text(widget.config['BACKEND_URL']!),
                      ],
                    ),
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
