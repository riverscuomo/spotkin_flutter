import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spotify/spotify.dart';
import 'dart:async';

class SpotifyService {
  // Constants
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _expirationKey = 'expiration';
  static const String _tokenEndpoint = 'https://accounts.spotify.com/api/token';
  static const Duration _defaultTimeout = Duration(seconds: 15);
  static const Duration _playlistTracksTimeout = Duration(seconds: 20);
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
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final tokenData = json.decode(response.body);
        await _saveTokenData(tokenData);
        await _updateSpotifyWithNewToken(tokenData);
      } else {
        debugPrint('Failed to authenticate: ${response.statusCode} ${response.reasonPhrase}');
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
      if (refreshToken == null) {
        debugPrint('Cannot refresh token: No refresh token stored');
        return false;
      }

      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      ).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final tokenData = json.decode(response.body);
        await _saveTokenData(tokenData);
        await _updateSpotifyWithNewToken(tokenData);
        return true;
      } else {
        debugPrint('Token refresh failed: ${response.statusCode} ${response.reasonPhrase}');
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

  /// Helper method to standardize API calls with error handling
  Future<T> _executeApiCall<T>(
      String operation, Future<T> Function() apiCall, T defaultValue) async {
    try {
      await _ensureAuthenticated();
      final result = await apiCall().timeout(_defaultTimeout);
      return result;
    } catch (e, stackTrace) {
      debugPrint('Error in $operation: $e');
      debugPrint('Stack trace: $stackTrace');
      return defaultValue;
    }
  }

  Future<PlaylistSimple> createPlaylist(String name, String description,
      {bool public = false}) async {
    final result = await _executeApiCall<PlaylistSimple?>('createPlaylist', () async {
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
    }, null);
    
    // Ensure we always return a non-null PlaylistSimple to maintain API compatibility
    if (result == null) {
      throw Exception('Failed to create playlist');
    }
    return result;
  }

  Future<PlaylistSimple?> getPlaylist(String playlistId) async {
    return await _executeApiCall<PlaylistSimple?>('getPlaylist', 
      () async => await _spotify.playlists.get(playlistId), 
      null);
  }

  Future<List<PlaylistSimple>> getUserPlaylists(
      {int limit = 50, int offset = 0}) async {
    return await _executeApiCall<List<PlaylistSimple>>('getUserPlaylists', () async {
      final me = await _spotify.me.get();
      final playlistsPage = await _spotify.playlists
          .getUsersPlaylists(me.id!)
          .getPage(limit, offset);
      return playlistsPage.items?.toList() ?? [];
    }, []);
  }

  Future<List<AlbumSimple>> getAlbums(List<String> albumIds) async {
    return await _executeApiCall<List<AlbumSimple>>('getAlbums', () async {
      final albumsIterable = await _spotify.albums.list(albumIds);
      return albumsIterable.toList();
    }, []);
  }

  Future<List<Artist>> getArtists(List<String> artistIds) async {
    return await _executeApiCall<List<Artist>>('getArtists', () async {
      final artistsIterable = await _spotify.artists.list(artistIds);
      return artistsIterable.toList();
    }, []);
  }

  Future<Iterable<Track>> getPlaylistTracks(String playlistId) async {
    debugPrint('SpotifyService: Getting tracks for playlist: $playlistId');
    
    final result = await _executeApiCall<Iterable<Track>>('getPlaylistTracks', () async {
      // Using a longer timeout specifically for playlist tracks which can be large
      return await _spotify.playlists
          .getTracksByPlaylistId(playlistId)
          .all()
          .timeout(
        _playlistTracksTimeout,
        onTimeout: () {
          debugPrint('SpotifyService: Timeout getting tracks for playlist: $playlistId');
          return <Track>[];
        },
      );
    }, <Track>[]);
    
    debugPrint('SpotifyService: Retrieved ${result.length} tracks for playlist: $playlistId');
    return result;
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _expirationKey);
    await _initializeSpotify();
  }

  /// Get the currently authenticated Spotify user profile
  Future<User?> getCurrentUser() async {
    debugPrint('Getting current user profile');
    
    final user = await _executeApiCall<User?>('getCurrentUser', 
        () async => await _spotify.me.get(), 
        null);
    
    if (user != null) {
      debugPrint('Current user: ${user.id} - ${user.displayName}');
    }
    
    return user;
  }
  
  Future<Iterable<dynamic>> search(
    String query, {
    int limit = 20,
    required List<SearchType> types,
  }) async {
    debugPrint('Performing search for query: $query with limit: $limit with types: $types');
    
    return await _executeApiCall<Iterable<dynamic>>('search', () async {
      final searchResults = await _spotify.search.get(query, types: types).first(limit);
      debugPrint('Number of pages: ${searchResults.length}');

      final unifiedResults = <dynamic>[];
      for (var page in searchResults) {
        if (page.items != null) {
          unifiedResults.addAll(page.items!);
        }
      }

      debugPrint('SPOTIFY SERVICE: Total number of results: ${unifiedResults.length}');
      return unifiedResults;
    }, <dynamic>[]);
  }
}
