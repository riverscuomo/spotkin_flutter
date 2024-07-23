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
      _handleAuthCode(widget.initialAuthCode!);
    }

    _checkExistingAuth();
  }

  Future<void> _handleAuthCode(String code) async {
    try {
      await spotifyService.exchangeCodeForToken(code);
      _navigateToHomeScreen();
    } catch (e) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Failed to authenticate with Spotify')),
      // );
    }
  }

  Future<void> _checkExistingAuth() async {
    final accessToken = await spotifyService.getAccessToken();
    if (accessToken != null) {
      _navigateToHomeScreen();
    }
  }

  void _navigateToHomeScreen() async {
    final accessToken = await spotifyService.getAccessToken();
    if (accessToken != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            config: widget.config,
            accessToken: accessToken,
            backendUrl: widget.config['BACKEND_URL']!,
          ),
        ),
      );
    }
  }

  void _initiateSpotifyLogin() {
    spotifyService.initiateSpotifyLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Spotify Auth Demo')),
      body: Center(
        child: ElevatedButton(
          onPressed: _initiateSpotifyLogin,
          child: const Text('Login with Spotify'),
        ),
      ),
    );
  }
}
