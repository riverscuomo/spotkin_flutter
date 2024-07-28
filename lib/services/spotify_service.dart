import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import 'package:spotify/spotify.dart';

class SpotifyService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';

  SpotifyApi? _spotify;
  final String clientId;
  final String clientSecret;
  final String redirectUri;
  final String scope;
  Completer<void>? _initializationCompleter;

  SpotifyService({
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    required this.scope,
  });

  Future<void> initializeSpotify() async {
    if (_spotify != null) return; // Already initialized

    print('--initializeSpotify--');
    final credentials = SpotifyApiCredentials(clientId, clientSecret);
    final grant = SpotifyApi.authorizationCodeGrant(credentials);

    final scopes = [
      AuthorizationScope.user.readEmail,
      AuthorizationScope.library.read
    ];

    final authUri = grant.getAuthorizationUrl(
      Uri.parse(redirectUri),
      scopes: scopes,
    );

    await redirect(authUri);
    final responseUri = await listen(redirectUri);

    _spotify = SpotifyApi.fromAuthCodeGrant(grant, responseUri);
  }

  SpotifyApi get spotify {
    if (_spotify == null) {
      throw StateError(
          'SpotifyService not initialized. Call initializeSpotify() first.');
    }
    return _spotify!;
  }

  Future<void> redirect(Uri uri) async {
    print('--redirect--');
    html.window.location.href = uri.toString();
  }

  Future<String> listen(String redirectUri) async {
    print('--listen--');
    final completer = Completer<Uri>();
    final subscription = html.window.onMessage.listen((event) {
      final uri = Uri.parse(event.data);
      completer.complete(uri);
    });

    final uri = await completer.future;
    subscription.cancel();
    print('SpotifyService: Received redirect URI: $uri');
    return uri.toString();
  }

  Future<bool> checkAuthentication() async {
    print('--checkAuthentication--');
    try {
      await _ensureAuthenticated();
      // final me = await _spotify.me.get();
      // print('SpotifyService: Authentication successful. User ID: ${me.id}');
      return true;
    } catch (e) {
      print('SpotifyService: Authentication check failed: $e');
      return false;
    }
  }

  Future<void> exchangeCodeForToken(String code) async {
    print('--exchangeCodeForToken--');
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
        final accessToken = tokenData['access_token'];
        final refreshToken = tokenData['refresh_token'];
        await _secureStorage.write(key: _accessTokenKey, value: accessToken);
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
        print(
            'SpotifyService: Access Token: ${accessToken.substring(0, 10)}...');
        _spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret,
            accessToken: accessToken));
      } else {
        print(
            'Failed to exchange code for token. Status: ${response.statusCode}');
        print('SpotifyService: Response body: ${response.body}');
        throw Exception(
            'Failed to authenticate with Spotify: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('SpotifyService: Error exchanging code for token: $e');
      throw Exception(
          'SpotifyService: Failed to authenticate with Spotify: $e');
    }
  }

  void initiateSpotifyLogin() {
    print('--initiateSpotifyLogin--');
    final spotifyAuthUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': scope,
      // 'show_dialog': 'true', // Force re-consent
    });

    print('SpotifyService: Initiating Spotify login with URL: $spotifyAuthUrl');
    print('SpotifyService: Client ID: $clientId');
    print('SpotifyService: Redirect URI: $redirectUri');
    print('SpotifyService: Requested Scopes: $scope');

    html.window.location.href = spotifyAuthUrl.toString();
  }

  Future<String?> getAccessToken() async {
    print('--getAccessToken--');
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<void> refreshAccessToken() async {
    print('--refreshAccessToken--');
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      throw Exception('SpotifyService: No refresh token available');
    }

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
    );

    if (response.statusCode == 200) {
      final tokenData = json.decode(response.body);
      final accessToken = tokenData['access_token'];
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
      print(
          'SpotifyService: Access Token refreshed and stored: ${accessToken.substring(0, 10)}...');

      // If a new refresh token is provided, store it as well
      if (tokenData['refresh_token'] != null) {
        await _secureStorage.write(
            key: _refreshTokenKey, value: tokenData['refresh_token']);
        print('SpotifyService: New refresh token stored');
      }

      _spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret,
          accessToken: accessToken));
      print('SpotifyService: SpotifyApi re-initialized with new access token');
    } else {
      print(
          'Failed to refresh token. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception('SpotifyService: Failed to refresh token');
    }
  }

  Future<void> _ensureAuthenticated() async {
    print('--_ensureAuthenticated--');
    final accessToken = await getAccessToken();
    if (accessToken == null) {
      print('SpotifyService: No access token found. Initiating login...');
      throw Exception('SpotifyService: Not authenticated');
    }

    print('SpotifyService: Access token found. Initializing SpotifyApi...');
    _spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret,
        accessToken: accessToken));
    print(
        'SpotifyService: SpotifyApi initialized with access token: ${accessToken.substring(0, 10)}...');

    int retryCount = 0;
    while (retryCount < 3) {
      try {
        // Test the token with a simple API call
        final me = await _spotify!.me.get();
        print('SpotifyService: Successfully authenticated. User ID: ${me.id}');
        return; // Authentication successful, exit the method
      } catch (e) {
        if (e is SpotifyException && e.status == 401) {
          print(
              'SpotifyService: Token expired, attempting to refresh... (Attempt ${retryCount + 1})');
          try {
            await refreshAccessToken();
            // Re-initialize SpotifyApi with the new token
            final newAccessToken = await getAccessToken();
            if (newAccessToken == null) {
              throw Exception(
                  'SpotifyService: Failed to get new access token after refresh');
            }
            _spotify = SpotifyApi(SpotifyApiCredentials(clientId, clientSecret,
                accessToken: newAccessToken));
            print(
                'SpotifyApi re-initialized with new access token: ${newAccessToken.substring(0, 10)}...');
            retryCount++;
          } catch (refreshError) {
            print('SpotifyService: Error refreshing token: $refreshError');
            retryCount++;
          }
        } else {
          throw e; // Rethrow if it's not a 401 error
        }
      }
    }

    // If we've exhausted all retry attempts, throw an exception
    throw Exception(
        'SpotifyService: Failed to authenticate after multiple attempts');
  }

  Future<void> _ensureInitialized() async {
    if (_spotify != null) return;

    if (_initializationCompleter == null) {
      _initializationCompleter = Completer<void>();
      try {
        await initializeSpotify();
        _initializationCompleter!.complete();
      } catch (e) {
        _initializationCompleter!.completeError(e);
        _initializationCompleter = null;
      }
    }

    await _initializationCompleter!.future;
  }

  Future<T> _retryOperation<T>(Future<T> Function() operation,
      {int maxRetries = 2}) async {
    int attempts = 0;
    while (true) {
      try {
        await _ensureAuthenticated();
        return await operation();
      } on SpotifyException catch (e) {
        print(
            'SpotifyService: Spotify API error: ${e.message}, Status code: ${e.status}');
        if (e.status == 401 && attempts < maxRetries) {
          print(
              'SpotifyService: Token might be expired. Attempting to refresh... (Attempt ${attempts + 1})');
          try {
            await refreshAccessToken();
            attempts++;
          } catch (refreshError) {
            print('SpotifyService: Error refreshing token: $refreshError');
            print('SpotifyService: Attempting full re-authentication...');
            initiateSpotifyLogin();
            throw Exception('SpotifyService: Re-authentication required');
          }
        } else {
          rethrow;
        }
      } catch (e) {
        print('SpotifyService: Error in operation: $e');
        rethrow;
      }
    }
  }

  Future<PlaylistSimple> createPlaylist(String name, String description,
      {bool public = false}) async {
    await _ensureInitialized();
    try {
      // Get the current user's ID
      final me = await _spotify!.me.get();
      final userId = me.id;

      if (userId == null) {
        throw Exception('SpotifyService: Failed to get user ID');
      }

      // Create the playlist
      final playlist = await _spotify!.playlists.createPlaylist(userId, name,
          public: public, description: description);

      // Convert the full Playlist object to a PlaylistSimple object
      return PlaylistSimple()
        ..id = playlist.id
        ..name = playlist.name
        ..public = playlist.public
        ..collaborative = playlist.collaborative
        ..images = playlist.images
        ..owner = playlist.owner
        // ..tracks = playlist.tracks
        ..type = playlist.type
        ..uri = playlist.uri;
    } catch (e) {
      print('SpotifyService: Error creating playlist: $e');
      rethrow;
    }
  }

  Future<PlaylistSimple> fetchPlaylist(String playlistId) async {
    await _ensureAuthenticated();
    try {
      return await _spotify!.playlists.get(playlistId);
    } catch (e) {
      print('SpotifyService: Error fetching playlist: $e');
      rethrow;
    }
  }

  Future<List<PlaylistSimple>> getUserPlaylists(
      {int limit = 50, int offset = 0}) async {
    return _retryOperation(() async {
      print('SpotifyService: Fetching user profile...');
      final me = await _spotify!.me.get();
      print('SpotifyService: User profile fetched. User ID: ${me.id}');

      if (me.id == null) {
        throw Exception(
            'SpotifyService: Failed to get user ID. Check authentication.');
      }

      print('SpotifyService: Fetching user playlists...');
      final playlistsPage = await _spotify!.playlists
          .getUsersPlaylists(me.id!)
          .getPage(limit, offset);
      print(
          'Successfully fetched ${playlistsPage.items?.length ?? 0} playlists');

      return playlistsPage.items?.toList() ?? [];
    });
  }

  Future<void> updatePlaylist(String playlistId,
      {String? name, String? description}) async {
    await _ensureAuthenticated();
    // await _spotify.playlists.changePlaylistDetails(playlistId, name: name, description: description);
  }

  Future<Artist> getArtist(String artistId) async {
    await _ensureAuthenticated();
    return await _spotify!.artists.get(artistId);
  }

  Future<Iterable<Track>> getPlaylistTracks(String playlistId) async {
    await _ensureInitialized();
    await _ensureAuthenticated();
    return await _spotify!.playlists.getTracksByPlaylistId(playlistId).all();
  }

  Future<void> logout() async {
    print('--logout--');
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    initializeSpotify();
  }

  Future<Iterable<dynamic>> search(
    String query, {
    int limit = 20,
    required List<SearchType> types,
  }) async {
    await _ensureInitialized();
    try {
      print(
          'SpotifyService: Performing search for query: $query with limit: $limit');
      final searchResults =
          await _spotify!.search.get(query, types: types).first(limit);

      print('SpotifyService: Number of pages: ${searchResults.length}');

      final unifiedResults = <dynamic>[];

      for (var page in searchResults) {
        if (page.items != null) {
          unifiedResults.addAll(page.items!);
        }
      }

      print(
          'SpotifyService: Total number of results: ${unifiedResults.length}');

      return unifiedResults;
    } catch (e) {
      print('SpotifyService: Error searching Spotify: $e');
      return [];
    }
  }

  Iterable<T> _extractItems<T>(List<Page> pages) {
    for (var page in pages) {
      if (page is Page<T>) {
        print(
            'SpotifyService: Extracting items of type $T, count: ${page.items?.length ?? 0}');
        return page.items ?? [];
      }
    }
    print('SpotifyService: No items found of type $T');
    return [];
  }
}
