import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:spotify/spotify.dart';
import 'dart:html' as html;

class SpotifyService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _accessTokenKey = 'accessToken';

  late SpotifyApi _spotify;
  final String clientId;
  final String clientSecret;
  final String redirectUri;
  final String scope;

  SpotifyService({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    required this.scope,
  }) {
    _initializeSpotify();
  }

  void _initializeSpotify() {
    final credentials = SpotifyApiCredentials(clientId, clientSecret);
    _spotify = SpotifyApi(credentials);
  }

  Future<void> exchangeCodeForToken(String code) async {
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
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      print('Access Token: $accessToken');
      _spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret,
          accessToken: accessToken));
    } else {
      print('Failed to exchange code for token: ${response.body}');
      throw Exception('Failed to authenticate with Spotify');
    }
  }

  void initiateSpotifyLogin() {
    final spotifyAuthUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': scope,
    });

    print('Redirecting to: $spotifyAuthUrl');
    html.window.location.href = spotifyAuthUrl.toString();
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  // refresh token
  Future<void> refreshAccessToken() async {
    final refreshToken = await _secureStorage.read(key: 'refreshToken');
    final tokenEndpoint = Uri.parse('https://accounts.spotify.com/api/token');
    final response = await http.post(
      tokenEndpoint,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );
    print(response);

    if (response.statusCode == 200) {
      final tokenData = json.decode(response.body);
      final accessToken = tokenData['access_token'];
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      print('Access Token: $accessToken');
      _spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret,
          accessToken: accessToken));
    } else {
      print('Failed to refresh token: ${response.body}');
      throw Exception('Failed to refresh token');
    }
  }

  Future<List<PlaylistSimple>> getUserPlaylists(String userId) async {
    final accessToken = await getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }
    _spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret,
        accessToken: accessToken));
    final playlists = await _spotify.playlists.getUsersPlaylists(userId).all();
    return playlists.toList();
  }

  Future<void> updatePlaylist(String playlistId,
      {String? name, String? description}) async {
    final accessToken = await getAccessToken();
    if (accessToken == null) {
      throw Exception('Not authenticated');
    }
    // _spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret, accessToken: accessToken));
    // await _spotify.playlists.updatePlaylist(playlistId,  description: description);
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    _initializeSpotify(); // Reset to unauthenticated state
  }

  // Add more methods as needed...
}
