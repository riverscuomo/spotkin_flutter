import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class AuthScreen extends StatefulWidget {
  final Map<String, dynamic> config;
  final String? initialAuthCode;

  AuthScreen({required this.config, this.initialAuthCode});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final SpotifyService spotifyService;
  bool _isLoading = false;
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

    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    setState(() => _isLoading = true);

    try {
      if (widget.initialAuthCode != null) {
        await _handleAuthCode(widget.initialAuthCode!);
      } else {
        await _checkExistingAuth();
      }
    } catch (e) {
      print('Error during authentication initialization: $e');
      _showErrorSnackBar('Failed to initialize authentication');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _handleAuthCode(String code) async {
    if (_authAttempts >= MAX_AUTH_ATTEMPTS) {
      _showErrorSnackBar(
          'Too many authentication attempts. Please try again later.');
      return;
    }

    _authAttempts++;

    try {
      print('Exchanging auth code for token (Attempt $_authAttempts)...');
      await spotifyService.exchangeCodeForToken(code);
      print('Token exchange successful');
      _navigateToHomeScreen();
    } catch (e) {
      print('Error exchanging code for token: $e');
      _showErrorSnackBar('Failed to authenticate with Spotify');
    }
  }

  Future<void> _checkExistingAuth() async {
    try {
      print('Checking existing authentication...');
      final accessToken = await spotifyService.getAccessToken();
      if (accessToken != null) {
        print('Existing access token found');
        if (await spotifyService.checkAuthentication()) {
          print('Existing token is valid');
          _navigateToHomeScreen();
        } else {
          print('Existing token is invalid, initiating login');
          _initiateSpotifyLogin();
        }
      } else {
        print('No existing access token found');
      }
    } catch (e) {
      print('Error checking existing auth: $e');
    }
  }

  void _navigateToHomeScreen() async {
    final accessToken = await spotifyService.getAccessToken();
    if (accessToken != null) {
      print('Navigating to Home Screen');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            config: widget.config,
            accessToken: accessToken,
            backendUrl: widget.config['BACKEND_URL']!,
          ),
        ),
      );
    } else {
      print('Failed to navigate: No access token available');
      _showErrorSnackBar('Authentication failed');
    }
  }

  void _initiateSpotifyLogin() {
    if (_authAttempts >= MAX_AUTH_ATTEMPTS) {
      _showErrorSnackBar(
          'Too many authentication attempts. Please try again later.');
      return;
    }

    print('Initiating Spotify login (Attempt ${_authAttempts + 1})...');
    spotifyService.initiateSpotifyLogin();
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
                    child: const Text('Login with Spotify'),
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
