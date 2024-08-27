import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotkin_flutter/app_core.dart';
import 'dart:html' as html;

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
      final credentials = await spotifyService.retrieveCredentials();
      if (credentials != null && credentials.accessToken != null) {
        print('AUTHSCREEN: Existing token found, verifying...');
        if (await spotifyService.verifyToken(credentials.accessToken!)) {
          print('AUTHSCREEN: Existing token is valid');
          _updateServicesAndNavigate(credentials.accessToken!);
          return;
        } else {
          print('AUTHSCREEN: Existing token is invalid, refreshing...');
          if (await spotifyService.refreshAccessToken()) {
            print('AUTHSCREEN: Token refreshed successfully');
            final newCredentials = await spotifyService.retrieveCredentials();
            if (newCredentials != null && newCredentials.accessToken != null) {
              _updateServicesAndNavigate(newCredentials.accessToken!);
              return;
            }
          }
        }
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
      final credentials = await spotifyService.retrieveCredentials();
      if (credentials != null && credentials.accessToken != null) {
        _updateServicesAndNavigate(credentials.accessToken!);
      } else {
        throw Exception('Failed to retrieve access token after exchange');
      }
    } catch (e) {
      print('AUTHSCREEN: Error exchanging code for token: $e');
      _showErrorSnackBar('Failed to authenticate with Spotify');
    }
  }

  void _updateServicesAndNavigate(String accessToken) {
    final backendService = Provider.of<BackendService>(context, listen: false);
    backendService.updateAccessToken(accessToken);

    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.loadJobs();

    _navigateToHomeScreen(accessToken);
  }

  void _navigateToHomeScreen(String accessToken) {
    print(
        'Navigating to Home Screen with access token: ${accessToken.substring(0, 10)}...');

    // Clear the URL parameters
    final uri = Uri.parse(html.window.location.href);
    if (uri.hasQuery) {
      var newUri = uri.removeFragment().replace(query: '');
      var cleanUrl = newUri.toString();
      if (cleanUrl.endsWith('?')) {
        cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
      }
      html.window.history.pushState(null, '', cleanUrl);
    }

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
                    child: Column(
                      children: [
                        const Text('Login with Spotify'),
                        Text(widget.config['SPOTIFY_REDIRECT_URI']!),
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
