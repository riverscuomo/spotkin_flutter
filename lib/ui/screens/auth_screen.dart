import 'package:flutter/foundation.dart';
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
  bool _isInitiatingLogin = false; // Flag to debounce login
  late SpotifyService _spotifyService;

  @override
  void initState() {
    super.initState();
    _spotifyService = SpotifyService(
      clientId: widget.config['SPOTIFY_CLIENT_ID'],
      clientSecret: widget.config['SPOTIFY_CLIENT_SECRET'],
      redirectUri: widget.config['SPOTIFY_REDIRECT_URI'],
      scope: widget.config['SPOTIFY_SCOPE'],
    );
    _checkForSavedCredentials(); // Automatically check for saved credentials
  }

  Future<void> _checkForSavedCredentials() async {
    setState(() => _isLoading = true);

    // Use your existing checkAuthentication method from SpotifyService
    final isAuthenticated = await _spotifyService.checkAuthentication();

    if (isAuthenticated) {
      // User is already authenticated, proceed to home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(config: widget.config),
        ),
      );
    } else {
      // No valid credentials, initiate the login flow
      _initiateSpotifyLogin();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _initiateSpotifyLogin() async {
    // Prevent multiple login attempts if one is already in progress
    if (_isInitiatingLogin) return;

    setState(() {
      _isLoading = true;
      _isInitiatingLogin = true;
    });

    debugPrint(
        "widget.config['SPOTIFY_REDIRECT_URI']: ${widget.config['SPOTIFY_REDIRECT_URI']}");

    final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': widget.config['SPOTIFY_CLIENT_ID'],
      'response_type': 'code', // Authorization code flow
      'redirect_uri': widget.config['SPOTIFY_REDIRECT_URI'],
      'scope': widget.config['SPOTIFY_SCOPE'],
    });

    try {
      const callbackScheme = kReleaseMode ? 'https' : 'http';

      // Start the OAuth process using your existing SpotifyService logic
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: callbackScheme,
        options: const FlutterWebAuth2Options(
          windowName: '_blank',
        ),
      );

      // Extract the authorization code from the result
      final uri = Uri.parse(result);
      final authCode = uri.queryParameters['code'];

      if (authCode != null) {
        await _handleAuthorizationCode(
            authCode); // Use SpotifyService to exchange the code
      } else {
        debugPrint('Failed to extract authorization code');
      }
    } catch (e) {
      debugPrint('Error during Spotify login: $e');
      _showErrorSnackBar('Failed to login with Spotify');
    } finally {
      setState(() {
        _isLoading = false;
        _isInitiatingLogin = false; // Reset flag after login attempt finishes
      });
    }
  }

  Future<void> _handleAuthorizationCode(String code) async {
    try {
      // Use the existing exchangeCodeForToken method to exchange code for access token
      await _spotifyService.exchangeCodeForToken(code);

      // After successfully exchanging the code, navigate to the home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(config: widget.config),
        ),
      );
    } catch (e) {
      debugPrint('Error handling authorization code: $e');
      _showErrorSnackBar('Failed to authenticate with Spotify');
    }
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
            ? CircularProgressIndicator().withDebugLabel('AuthLoader')
            : ElevatedButton(
                onPressed: _initiateSpotifyLogin,
                child: const Text('Login with Spotify'),
              ).withDebugLabel('SpotifyLoginButton'),
      ),
    ).withDebugLabel('AuthScaffold');
  }
}
