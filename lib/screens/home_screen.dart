import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> config;
  final String? initialAuthCode;

  HomeScreen({required this.config, 
   this.initialAuthCode});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      _navigateToUpdateScreen();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to authenticate with Spotify')),
      );
    }
  }

  Future<void> _checkExistingAuth() async {
    final accessToken = await spotifyService.getAccessToken();
    if (accessToken != null) {
      _navigateToUpdateScreen();
    }
  }

  void _navigateToUpdateScreen() async {
    final accessToken = await spotifyService.getAccessToken();
    if (accessToken != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => UpdateScreen(
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
