import 'dart:async';
import 'package:flutter/material.dart';
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

    if (widget.initialAuthCode != null) {
      print(
          'AUTHSCREEN: Handling initial auth code: ${widget.initialAuthCode}');
      _handleAuthCode(widget.initialAuthCode!);
    } else if (widget.initialError != null) {
      print('AUTHSCREEN: Handling initial error: ${widget.initialError}');
      _showErrorSnackBar('Authentication failed: ${widget.initialError}');
    } else {
      _initializeAuth();
    }
  }

  Future<void> _initializeAuth() async {
    print('AUTHSCREEN: AUTHSCREEN: Initializing authentication...');
    setState(() => _isLoading = true);

    // try {
    //   if (widget.initialAuthCode != null) {
    //     await _handleAuthCode(widget.initialAuthCode!);
    //   } else {
    //     await _checkExistingAuth();
    //   }
    // } catch (e) {
    //   print('AUTHSCREEN: Error during authentication initialization: $e');
    //   _showErrorSnackBar('Failed to initialize authentication');
    // }

    setState(() => _isLoading = false);
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

  Future<void> _checkExistingAuth() async {
    try {
      print('AUTHSCREEN: Checking existing authentication...');
      await Future.delayed(Duration(seconds: 3));
      if (await spotifyService.checkAuthentication()) {
        print('AUTHSCREEN: Existing token is valid');
        _navigateToHomeScreen();
      } else {
        print(
            'AUTHSCREEN: token may be missing!  or invalid, initiating login');
        _initiateSpotifyLogin();
      }
    } catch (e) {
      print('AUTHSCREEN: Error checking existing auth: $e');
      _initiateSpotifyLogin();
    }
  }

  void _navigateToHomeScreen() async {
    final accessToken = await spotifyService
        .retrieveCredentials()
        .then((creds) => creds!.accessToken);
    if (accessToken != null) {
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
    } else {
      print('AUTHSCREEN: Failed to navigate: No access token available');
      _showErrorSnackBar('Authentication failed');
    }
  }

  void _initiateSpotifyLogin() {
    if (_authAttempts >= MAX_AUTH_ATTEMPTS) {
      _showErrorSnackBar(
          'Too many authentication attempts. Please try again later.');
      return;
    }

    print(
        'AUTHSCREEN: Initiating Spotify login (Attempt ${_authAttempts + 1})...');
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
