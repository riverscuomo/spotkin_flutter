import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spotify/spotify.dart' as spotify;

class OpenAIService {
  final String backendUrl;
  
  // Simple in-memory cache that only lasts for the current session
  final Map<String, String> _cache = {};

  OpenAIService({required this.backendUrl});

  /// Gets information about a track using the backend server proxy to OpenAI
  Future<String> getTrackInfo(spotify.Track track) async {
    // Generate unique cache key
    final cacheKey = 'track_${track.id ?? track.name}';
    
    // Return cached response if available
    if (_cache.containsKey(cacheKey)) {
      debugPrint('Using cached track info for ${track.name}');
      return _cache[cacheKey]!;
    }
    
    try {
      // Send track data to the server
      final response = await http.post(
        Uri.parse('$backendUrl/ai/track'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': track.name,
          'artists':
              track.artists?.map((a) => a.name).toList() ?? ['Unknown Artist'],
          'album': track.album?.name ?? 'Unknown Album'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['response'];
        
        // Cache the response
        _cache[cacheKey] = responseText;
        
        return responseText;
      } else {
        throw Exception(
            'Failed to get track info: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting track info from server: $e');
      return 'Sorry, I couldn\'t retrieve information about this track. Please try again later.';
    }
  }

  /// Gets information about an artist using the backend server proxy to OpenAI
  Future<String> getArtistInfo(spotify.Artist artist) async {
    // Generate unique cache key
    final cacheKey = 'artist_${artist.id ?? artist.name}';
    
    // Return cached response if available
    if (_cache.containsKey(cacheKey)) {
      debugPrint('Using cached artist info for ${artist.name}');
      return _cache[cacheKey]!;
    }
    
    try {
      // Send artist data to the server
      final response = await http.post(
        Uri.parse('$backendUrl/ai/artist'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(
            {'name': artist.name, 'genres': artist.genres?.toList() ?? []}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['response'];
        
        // Cache the response
        _cache[cacheKey] = responseText;
        
        return responseText;
      } else {
        throw Exception(
            'Failed to get artist info: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting artist info from server: $e');
      return 'Sorry, I couldn\'t retrieve information about this artist. Please try again later.';
    }
  }

  /// Gets information about an album using the backend server proxy to OpenAI
  Future<String> getAlbumInfo(spotify.AlbumSimple album) async {
    // Generate unique cache key
    final cacheKey = 'album_${album.id ?? album.name}';
    
    // Return cached response if available
    if (_cache.containsKey(cacheKey)) {
      debugPrint('Using cached album info for ${album.name}');
      return _cache[cacheKey]!;
    }
    
    try {
      List<String> artistNames = [];
      // Use null-aware operator to safely access artists collection
      final artists = album.artists;
      if (artists != null && artists.isNotEmpty) {
        // Use a loop to extract artist names
        for (final artist in artists) {
          artistNames.add(artist.name ?? 'Unknown');
        }

        if (artistNames.isEmpty) {
          artistNames = ['Unknown Artist'];
        }
      }

      // Send album data to the server
      final response = await http.post(
        Uri.parse('$backendUrl/ai/album'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': album.name ?? 'Unknown Album',
          'artists': artistNames,
          'release_date': album.releaseDate
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['response'];
        
        // Cache the response
        _cache[cacheKey] = responseText;
        
        return responseText;
      } else {
        throw Exception(
            'Failed to get album info: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting album info from server: $e');
      return 'Sorry, I couldn\'t retrieve information about this album. Please try again later.';
    }
  }

  // Prompt building is now handled server-side
  
  /// Clears the in-memory cache
  void clearCache() {
    _cache.clear();
    debugPrint('AI response cache cleared');
  }
}
