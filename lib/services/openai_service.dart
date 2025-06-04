import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spotify/spotify.dart' as spotify;

class OpenAIService {
  final String backendUrl;
  
  OpenAIService({required this.backendUrl});

  /// Gets information about a track using the backend server proxy to OpenAI
  Future<String> getTrackInfo(spotify.Track track) async {
    try {
      // Send track data to the server
      final response = await http.post(
        Uri.parse('$backendUrl/ai/track'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': track.name,
          'artists': track.artists?.map((a) => a.name).toList() ?? ['Unknown Artist'],
          'album': track.album?.name ?? 'Unknown Album'
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      } else {
        throw Exception('Failed to get track info: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting track info from server: $e');
      return 'Sorry, I couldn\'t retrieve information about this track. Please try again later.';
    }
  }

  /// Gets information about an artist using the backend server proxy to OpenAI
  Future<String> getArtistInfo(spotify.Artist artist) async {
    try {
      // Send artist data to the server
      final response = await http.post(
        Uri.parse('$backendUrl/ai/artist'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': artist.name,
          'genres': artist.genres?.toList() ?? []
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      } else {
        throw Exception('Failed to get artist info: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting artist info from server: $e');
      return 'Sorry, I couldn\'t retrieve information about this artist. Please try again later.';
    }
  }

  /// Gets information about an album using the backend server proxy to OpenAI
  Future<String> getAlbumInfo(dynamic album) async {
    try {
      // Extract artist names handling both Album and AlbumSimple types
      List<String> artistNames = ['Unknown Artist'];
      if (album.artists != null) {
        artistNames = album.artists
            .map<String>((a) => a.name ?? 'Unknown')
            .where((name) => name.isNotEmpty)
            .toList();
        
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
        return data['response'];
      } else {
        throw Exception('Failed to get album info: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting album info from server: $e');
      return 'Sorry, I couldn\'t retrieve information about this album. Please try again later.';
    }
  }

  // Prompt building is now handled server-side
}
