import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
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

  Future<SpotifyApi> get spotify async {
    if (_spotify == null) {
      await _initializeSpotify();
    }
    return _spotify!;
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

  void _updateSpotifyInstance(SpotifyApiCredentials credentials) {
    _spotify = SpotifyApi(credentials);
  }

  // void _initializeSpotify() {
  //   final credentials =
  //       SpotifyApiCredentials(clientId, clientSecret, scopes: scope.split(' '));
  //   _spotify = SpotifyApi(credentials);
  // }

  Future<bool> checkAuthentication() async {
    print('spotify service: Checking authentication...');
    return true;
    try {
      await _ensureAuthenticated();
      final me = await _spotify.me.get();
      print('Authentication successful. User ID: ${me.id}');
      return true;
    } catch (e) {
      print('Authentication check failed: $e');
      return false;
    }
  }

  Future<void> exchangeCodeForToken(String code) async {
    print('Exchanging code for token...');
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
        final expiresIn = tokenData['expires_in'];
        final DateTime expiration =
            DateTime.now().add(Duration(seconds: expiresIn));
        await _secureStorage.write(key: _accessTokenKey, value: accessToken);
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
        print('Access Token: ${accessToken.substring(0, 10)}...');

        final credentials = SpotifyApiCredentials(
          clientId,
          clientSecret,
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiration: expiration,
          scopes: scope.split(' '),
        );
        print(credentials);
        await saveCredentials(credentials);
        // _spotify = SpotifyApi(
        //   credentials,
        // );
        _updateSpotifyInstance(credentials);

        final me = await _spotify.me.get();
        print(me.id);
        print(
            'SPOTIFY SERVICE: SpotifyApi re-initialized with new access token: $_spotify');
      } else {
        print(
            'Failed to exchange code for token. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'Failed to authenticate with Spotify: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error exchanging code for token: $e');
      throw Exception('Failed to authenticate with Spotify: $e');
    }
  }

  void initiateSpotifyLogin() {
    final spotifyAuthUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': scope,
      // 'show_dialog': 'SPOTIFY SERVICE: true', // Force re-consent
    });

    print('Initiating Spotify login with URL: $spotifyAuthUrl');
    print('Client ID: $clientId');
    print('Redirect URI: $redirectUri');
    print('Requested Scopes: $scope');

    html.window.location.href = spotifyAuthUrl.toString();
  }

  // Future<String?> getAccessToken() async {
  Future<SpotifyApiCredentials?> retrieveCredentials() async {
    print('SPOTIFY SERVICE: Retrieving credentials...');
    final accessToken = await _secureStorage.read(key: _accessTokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    final expirationString = await _secureStorage.read(key: _expirationKey);

    if (accessToken == null ||
        refreshToken == null ||
        expirationString == null) {
      return null;
    }

    final expiration = DateTime.parse(expirationString);
    return SpotifyApiCredentials(
      clientId,
      clientSecret,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiration: expiration,
      scopes: scope.split(' '),
    );
  }

  Future<void> saveCredentials(SpotifyApiCredentials credentials) async {
    print('SPOTIFY SERVICE: Saving credentials...');
    if (credentials.accessToken == null ||
        credentials.refreshToken == null ||
        credentials.expiration == null) {
      throw Exception('Invalid credentials');
    } else {
      await _secureStorage.write(
          key: _accessTokenKey, value: credentials.accessToken);
      await _secureStorage.write(
          key: _refreshTokenKey, value: credentials.refreshToken);
      await _secureStorage.write(
          key: _expirationKey,
          value: credentials.expiration!.toIso8601String());
    }
  }

  Future<void> refreshAccessToken() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken == null) {
      throw Exception('No refresh token available');
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
          'Access Token refreshed and stored: ${accessToken.substring(0, 10)}...');

      // If a new refresh token is provided, store it as well
      if (tokenData['refresh_token'] != null) {
        await _secureStorage.write(
            key: _refreshTokenKey, value: tokenData['refresh_token']);
        print('New refresh token stored');
      }

      final expiresIn = tokenData['expires_in'];
      final DateTime expiration =
          DateTime.now().add(Duration(seconds: expiresIn));

      final credentials = SpotifyApiCredentials(
        clientId,
        clientSecret,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiration: expiration,
        scopes: scope.split(' '),
      );
      print(credentials);
      await saveCredentials(credentials);
      // _spotify = SpotifyApi(
      //   credentials,
      // );
      _updateSpotifyInstance(credentials);
      print('SpotifyApi re-initialized with new access token');
    } else {
      print(
          'Failed to refresh token. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to refresh token');
    }
  }

  Future<void> _ensureAuthenticated() async {
    print('SPOTIFY SERVICE: Ensuring authentication...');
    // Retrieve the saved credentials and use them to connect to Spotify
    final credentials = await retrieveCredentials();
    if (credentials == null) {
      print('No credentials found. Initiating login...');
      throw Exception('Not authenticated');
    }

    print('SPOTIFY SERVICE: Access token found. Initializing SpotifyApi...');
    _updateSpotifyInstance(credentials);
    // _spotify = SpotifyApi(
    //   SpotifyApiCredentials(
    //     clientId,
    //     clientSecret,
    //     accessToken: credentials.accessToken,
    //     scopes: scope.split(' '),
    //     expiration: credentials.expiration,
    //   ),
    // );
    print('SpotifyApi initialized with access token: $credentials');
    await saveCredentials(credentials);

    // If we've exhausted all retry attempts, throw an exception
    throw Exception('Failed to authenticate after multiple attempts');
  }

  Future<PlaylistSimple> createPlaylist(String name, String description,
      {bool public = false}) async {
    print('spotify service: Creating playlist...');
    var userId;
    try {
      // Get the current user's ID
      final me = await _spotify.me.get();
      userId = me.id;

      if (userId == null) {
        throw Exception('Failed to get user ID');
      }
    } catch (e) {
      print('SPOTIFYSERVICE: spotify.me failed $e');
      rethrow;
    }

    try {
      // Create the playlist
      final playlist = await _spotify.playlists.createPlaylist(userId, name,
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
      print('Error creating playlist: $e');
      rethrow;
    }
  }

  Future<PlaylistSimple> getPlaylist(String playlistId) async {
    // await _ensureAuthenticated();
    try {
      return await _spotify.playlists.get(playlistId);
    } catch (e) {
      print('Error fetching playlist: $e');
      rethrow;
    }
  }

  Future<List<PlaylistSimple>> getUserPlaylists(
      {int limit = 50, int offset = 0}) async {
    var me;
    try {
      print('Fetching user profile...');
      me = await _spotify.me.get();
      print('User profile fetched successfully: ${me.id}');

      // Rest of your code...
    } catch (e) {
      print('Error fetching user profile: $e');
      if (e is SpotifyException) {
        print('Spotify error code: ${e.status}');
        print('Spotify error message: ${e.message}');
      }
      rethrow;
    }
    print('User profile fetched. User ID: ${me.id}');

    if (me.id == null) {
      throw Exception('Failed to get user ID. Check authentication.');
    }

    print('Fetching user playlists...');
    final playlistsPage = await _spotify.playlists
        .getUsersPlaylists(me.id!)
        .getPage(limit, offset);
    print('Successfully fetched ${playlistsPage.items?.length ?? 0} playlists');

    return playlistsPage.items?.toList() ?? [];
  }

  Future<void> updatePlaylist(String playlistId,
      {String? name, String? description}) async {
    await _ensureAuthenticated();
    // await _spotify.playlists.changePlaylistDetails(playlistId, name: name, description: description);
  }

  Future<Artist> getArtist(String artistId) async {
    await _ensureAuthenticated();
    return await _spotify.artists.get(artistId);
  }

  Future<Iterable<Track>> getPlaylistTracks(String playlistId) async {
    await _ensureAuthenticated();
    return await _spotify.playlists.getTracksByPlaylistId(playlistId).all();
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    _initializeSpotify();
  }

  Future<Iterable<dynamic>> search(
    String query, {
    int limit = 20,
    required List<SearchType> types,
  }) async {
    try {
      print('Performing search for query: $query with limit: $limit');
      final searchResults =
          await _spotify.search.get(query, types: types).first(limit);

      print('Number of pages: ${searchResults.length}');

      final unifiedResults = <dynamic>[];

      for (var page in searchResults) {
        if (page.items != null) {
          unifiedResults.addAll(page.items!);
        }
      }

      print(
          'SPOTIFY SERVICE: Total number of results: ${unifiedResults.length}');

      return unifiedResults;
    } catch (e) {
      print('Error searching Spotify: $e');
      return [];
    }
  }

  Iterable<T> _extractItems<T>(List<Page> pages) {
    for (var page in pages) {
      if (page is Page<T>) {
        print('Extracting items of type $T, count: ${page.items?.length ?? 0}');
        return page.items ?? [];
      }
    }
    print('No items found of type $T');
    return [];
  }
}



    // int retryCount = 0;
    // while (retryCount < 3) {
    //   try {
    //     // Test the token with a simple API call
    //     final me = await _spotify.me.get();
    //     print('Successfully authenticated. User ID: ${me.id}');
    //     return; // Authentication successful, exit the method
    //   } catch (e) {
    //     if (e is SpotifyException && e.status == 401) {
    //       print(
    //           'SPOTIFY SERVICE: Token expired, attempting to refresh... (Attempt ${retryCount + 1})');
    //       try {
    //         await refreshAccessToken();
    //         // Re-initialize SpotifyApi with the new token
    //         final newAccessToken = await getAccessToken();
    //         if (newAccessToken == null) {
    //           throw Exception('Failed to get new access token after refresh');
    //         }
    //         _spotify = SpotifyApi(
    //           SpotifyApiCredentials(
    //             clientId,
    //             clientSecret,
    //             accessToken: newAccessToken,
    //             scopes: scope.split(' '),
    //           ),
    //         );
    //         print(
    //             'SpotifyApi re-initialized with new access token: ${newAccessToken.substring(0, 10)}...');
    //         retryCount++;
    //       } catch (refreshError) {
    //         print('Error refreshing token: $refreshError');
    //         retryCount++;
    //       }
    //     } else {
    //       throw e; // Rethrow if it's not a 401 error
    //     }
    //   }
    // }

  // Future<T> _retryOperation<T>(Future<T> Function() operation,
  //     {int maxRetries = 2}) async {
  //   int attempts = 0;
  //   while (true) {
  //     try {
  //       await _ensureAuthenticated();
  //       return await operation();
  //     } on SpotifyException catch (e) {
  //       print('Spotify API error: ${e.message}, Status code: ${e.status}');
  //       if (e.status == 401 && attempts < maxRetries) {
  //         print(
  //             'SPOTIFY SERVICE: Token might be expired. Attempting to refresh... (Attempt ${attempts + 1})');
  //         try {
  //           await refreshAccessToken();
  //           attempts++;
  //         } catch (refreshError) {
  //           print('Error refreshing token: $refreshError');
  //           print('Attempting full re-authentication...');
  //           initiateSpotifyLogin();
  //           throw Exception('Re-authentication required');
  //         }
  //       } else {
  //         rethrow;
  //       }
  //     } catch (e) {
  //       print('Error in operation: $e');
  //       rethrow;
  //     }
  //   }
  // }