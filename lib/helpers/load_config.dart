import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<Map<String, dynamic>> loadConfig() async {
  String configString = await rootBundle.loadString('assets/config.json');

  if (kDebugMode) {
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();
    try {
      Map<String, dynamic> config = jsonDecode(configString);

      // Get the development access token
      String? devAccessToken = config['DEV_ACCESS_TOKEN'];

      if (devAccessToken != null && devAccessToken.isNotEmpty) {
        // Store the token in secure storage
        await secureStorage.write(key: 'accessToken', value: devAccessToken);
        print('Development Spotify access token loaded into secure storage');
      } else {
        print('No development Spotify access token found in config');
      }
    } catch (e) {
      print('Error loading development config: $e');
    }
  }
  // print('Loaded config: $configString');
  Map<String, dynamic> config = jsonDecode(configString);
  return config;
}

Future<void> loadDevConfig() async {}

// // In your SpotifyService or wherever you handle Spotify authentication
// Future<String?> getSpotifyAccessToken() async {
//   return await _secureStorage.read(key: 'spotify_access_token');
// }

// // Optional: Function to clear the token when needed (e.g., for logout)
// Future<void> clearSpotifyAccessToken() async {
//   await _secureStorage.delete(key: 'spotify_access_token');
// }
