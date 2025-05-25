import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spotify/spotify.dart';

class SpotifyService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _expirationKey = 'expiration';
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

  Future<void> _initializeSpotify() async {
    final credentials = await retrieveCredentials();
    if (credentials == null) {
      final initialCredentials = SpotifyApiCredentials(clientId, clientSecret,
          scopes: scope.split(' '));
      _spotify = SpotifyApi(initialCredentials);
    } else {
      _updateSpotifyInstance(credentials);
    }
  }

  Future<void> setAccessToken(String accessToken) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    final credentials = SpotifyApiCredentials(
      clientId,
      clientSecret,
      accessToken: accessToken,
      scopes: scope.split(' '),
    );
    _updateSpotifyInstance(credentials);
  }

  void _updateSpotifyInstance(SpotifyApiCredentials credentials) {
    _spotify = SpotifyApi(credentials);
  }

  Future<bool> checkAuthentication() async {
    try {
      await _ensureAuthenticated();
      final me = await _spotify.me.get();
      debugPrint('Authentication successful. User ID: ${me.id}');
      return true;
    } catch (e) {
      debugPrint('Authentication check failed: $e');
      return false;
    }
  }

  Future<void> exchangeCodeForToken(String code) async {
    final tokenEndpoint = Uri.parse('https://accounts.spotify.com/api/token');
    try {
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
        await _saveTokenData(tokenData);
        await _updateSpotifyWithNewToken(tokenData);
      } else {
        throw Exception(
            'Failed to authenticate with Spotify: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error exchanging code for token: $e');
      rethrow;
    }
  }

  Future<void> _saveTokenData(Map<String, dynamic> tokenData) async {
    await _secureStorage.write(
        key: _accessTokenKey, value: tokenData['access_token']);
    await _secureStorage.write(
        key: _refreshTokenKey, value: tokenData['refresh_token']);
    final expiration =
        DateTime.now().add(Duration(seconds: tokenData['expires_in']));
    await _secureStorage.write(
        key: _expirationKey, value: expiration.toIso8601String());
  }

  Future<void> _updateSpotifyWithNewToken(
      Map<String, dynamic> tokenData) async {
    final credentials = SpotifyApiCredentials(
      clientId,
      clientSecret,
      accessToken: tokenData['access_token'],
      refreshToken: tokenData['refresh_token'],
      expiration:
          DateTime.now().add(Duration(seconds: tokenData['expires_in'])),
      scopes: scope.split(' '),
    );
    _updateSpotifyInstance(credentials);
  }

  Future<SpotifyApiCredentials?> retrieveCredentials() async {
    debugPrint('retrieveCredentials');
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    final expirationString = await _secureStorage.read(key: _expirationKey);

    if (accessToken == null ||
        refreshToken == null ||
        expirationString == null) {
      return null;
    }

    final expiration = DateTime.parse(expirationString);
    if (DateTime.now().isAfter(expiration)) {
      final refreshSuccess = await refreshAccessToken();
      if (!refreshSuccess) return null;
      return await retrieveCredentials();
    }

    return SpotifyApiCredentials(
      clientId,
      clientSecret,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiration: expiration,
      scopes: scope.split(' '),
    );
  }

  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final tokenEndpoint = Uri.parse('https://accounts.spotify.com/api/token');
      final response = await http.post(
        tokenEndpoint,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final tokenData = json.decode(response.body);
        await _saveTokenData(tokenData);
        await _updateSpotifyWithNewToken(tokenData);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error refreshing access token: $e');
      return false;
    }
  }

  Future<void> _ensureAuthenticated() async {
    final credentials = await retrieveCredentials();
    if (credentials == null) {
      throw Exception('Not authenticated');
    }
    _updateSpotifyInstance(credentials);
  }

  Future<String> getUserId() async {
    await _ensureAuthenticated();
    final me = await _spotify.me.get();
    return me.id ?? '';
  }

  Future<String?> retrieveAccessToken() async {
    final credentials = await retrieveCredentials();
    return credentials?.accessToken;
  }

  Future<PlaylistSimple> createPlaylist(String name, String description,
      {bool public = false}) async {
    await _ensureAuthenticated();
    final me = await _spotify.me.get();
    final playlist = await _spotify.playlists
        .createPlaylist(me.id!, name, public: public, description: description);
    return PlaylistSimple()
      ..id = playlist.id
      ..name = playlist.name
      ..public = playlist.public
      ..collaborative = playlist.collaborative
      ..images = me.images ?? []
      ..owner = playlist.owner
      ..type = playlist.type
      ..uri = playlist.uri;
  }

  Future<PlaylistSimple> getPlaylist(String playlistId) async {
    await _ensureAuthenticated();
    return await _spotify.playlists.get(playlistId);
  }

  Future<List<PlaylistSimple>> getUserPlaylists(
      {int limit = 50, int offset = 0}) async {
    await _ensureAuthenticated();
    final me = await _spotify.me.get();
    final playlistsPage = await _spotify.playlists
        .getUsersPlaylists(me.id!)
        .getPage(limit, offset);
    return playlistsPage.items?.toList() ?? [];
  }

  Future<List<AlbumSimple>> getAlbums(List<String> albumIds) async {
    await _ensureAuthenticated(); // Ensure the user is authenticated

    // Fetch multiple albums from Spotify by their IDs
    final albumsIterable = await _spotify.albums.list(albumIds);

    // Return the list of AlbumSimple objects
    return albumsIterable.toList();
  }

  Future<List<Artist>> getArtists(List<String> artistIds) async {
    await _ensureAuthenticated();
    final artistsIterable = await _spotify.artists.list(artistIds);
    return artistsIterable.toList();
  }

  Future<Iterable<Track>> getPlaylistTracks(String playlistId) async {
    try {
      debugPrint('SpotifyService: Getting tracks for playlist: $playlistId');
      await _ensureAuthenticated();

      // Get tracks with a timeout to prevent hanging
      final tracks = await _spotify.playlists
          .getTracksByPlaylistId(playlistId)
          .all()
          .timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint(
              'SpotifyService: Timeout getting tracks for playlist: $playlistId');
          return <Track>[];
        },
      );

      debugPrint(
          'SpotifyService: Retrieved ${tracks.length} tracks for playlist: $playlistId');
      return tracks;
    } catch (e, stackTrace) {
      debugPrint(
          'SpotifyService: Error getting tracks for playlist $playlistId: $e');
      debugPrint('Stack trace: $stackTrace');
      return <Track>[];
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _expirationKey);
    await _initializeSpotify();
  }

  Future<Iterable<dynamic>> search(
    String query, {
    int limit = 20,
    required List<SearchType> types,
  }) async {
    try {
      debugPrint(
          'Performing search for query: $query with limit: $limit with types: $types');
      final searchResults =
          await _spotify.search.get(query, types: types).first(limit);

      debugPrint('Number of pages: ${searchResults.length}');

      final unifiedResults = <dynamic>[];

      for (var page in searchResults) {
        if (page.items != null) {
          unifiedResults.addAll(page.items!);
        }
      }

      debugPrint(
          'SPOTIFY SERVICE: Total number of results: ${unifiedResults.length}');

      return unifiedResults;
    } catch (e) {
      debugPrint('Error searching Spotify: $e');
      return [];
    }
  }
}
