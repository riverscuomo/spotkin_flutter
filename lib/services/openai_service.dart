import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:spotify/spotify.dart' as spotify;

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  /// Gets information about a track using OpenAI API
  Future<String> getTrackInfo(spotify.Track track) async {
    try {
      final prompt = _buildTrackPrompt(track);
      return await _getCompletionFromOpenAI(prompt);
    } catch (e) {
      debugPrint('Error getting track info from OpenAI: $e');
      return 'Sorry, I couldn\'t retrieve information about this track. Please try again later.';
    }
  }

  /// Gets information about an artist using OpenAI API
  Future<String> getArtistInfo(spotify.Artist artist) async {
    try {
      final prompt = _buildArtistPrompt(artist);
      return await _getCompletionFromOpenAI(prompt);
    } catch (e) {
      debugPrint('Error getting artist info from OpenAI: $e');
      return 'Sorry, I couldn\'t retrieve information about this artist. Please try again later.';
    }
  }

  /// Gets information about an album using OpenAI API
  Future<String> getAlbumInfo(dynamic album) async {
    try {
      final prompt = _buildAlbumPrompt(album);
      return await _getCompletionFromOpenAI(prompt);
    } catch (e) {
      debugPrint('Error getting album info from OpenAI: $e');
      return 'Sorry, I couldn\'t retrieve information about this album. Please try again later.';
    }
  }

  /// Builds a prompt for getting track information
  String _buildTrackPrompt(spotify.Track track) {
    final artistNames = track.artists != null
        ? track.artists!
            .map((a) => a.name)
            .where((name) => name != null)
            .join(', ')
        : 'Unknown Artist';

    final albumName = track.album?.name ?? 'Unknown Album';

    return '''
      Give me interesting information, facts, and background about the song "${track.name}" by $artistNames from the album "$albumName".
      Include details about its creation, reception, musical style, lyrical themes, chart performance, and any interesting trivia.
      Format the response in a conversational, engaging way, like you're enthusiastically sharing this information with a music fan.
      Keep the response concise (maximum 3 paragraphs).
    ''';
  }

  /// Builds a prompt for getting artist information
  String _buildArtistPrompt(spotify.Artist artist) {
    return '''
      Give me interesting information and facts about the music artist "${artist.name}".
      Include details about their background, musical style, career highlights, influence on music, notable albums/songs, and any interesting trivia.
      Format the response in a conversational, engaging way, like you're enthusiastically sharing this information with a music fan.
      Keep the response concise (maximum 3 paragraphs).
    ''';
  }

  /// Builds a prompt for getting album information
  String _buildAlbumPrompt(dynamic album) {
    String albumName = album.name ?? 'Unknown Album';

    // Handle both Album and AlbumSimple types
    String artistNames = 'Unknown Artist';
    if (album.artists != null) {
      artistNames = album.artists
          .map((a) => a.name)
          .where((name) => name != null)
          .join(', ');

      if (artistNames.isEmpty) {
        artistNames = 'Unknown Artist';
      }
    }

    return '''
      Give me interesting information and facts about the album "$albumName" by $artistNames.
      Include details about its creation, reception, musical style, lyrical themes, chart performance, and any interesting trivia.
      Format the response in a conversational, engaging way, like you're enthusiastically sharing this information with a music fan.
      Keep the response concise (maximum 3 paragraphs).
    ''';
  }

  /// Makes an API call to OpenAI and returns the completion
  Future<String> _getCompletionFromOpenAI(String prompt) async {
    String? apiKey;

    // Print environment variables in a web-safe way
    debugPrint('Checking for compile-time environment variables:');
    final openaiKey = const String.fromEnvironment('OPENAI_API_KEY');
    debugPrint('OPENAI_API_KEY defined: ${openaiKey.isNotEmpty}');
    if (openaiKey.isNotEmpty) {
      // Only print first few characters for security
      final prefix =
          openaiKey.length > 4 ? openaiKey.substring(0, 4) : openaiKey;
      debugPrint('OPENAI_API_KEY prefix: $prefix...');
    }

    // Print dotenv variables (safe way)
    try {
      final envVars = dotenv.env.keys.toList();
      debugPrint('Dotenv variables available: ${envVars.join(', ')}');
    } catch (e) {
      debugPrint('Error accessing dotenv variables: $e');
    }

    // First try to get the API key from compile-time environment variable
    // This works on web and is the most secure for web apps
    const String compileTimeKey = String.fromEnvironment('OPENAI_API_KEY');
    if (compileTimeKey.isNotEmpty) {
      apiKey = compileTimeKey;
      debugPrint('Using API key from compile-time environment');
    }

    // Next try dotenv as fallback
    if (apiKey == null || apiKey.isEmpty) {
      try {
        apiKey = dotenv.env['OPENAI_API_KEY'];
        if (apiKey != null && apiKey.isNotEmpty) {
          debugPrint('Using API key from .env file');
        }
      } catch (e) {
        debugPrint('Error accessing dotenv: $e');
      }
    }

    if (apiKey == null || apiKey.isEmpty) {
      // For web apps, you could also consider retrieving the key from a secure backend service
      // or implementing a proxy API on your backend that forwards requests to OpenAI
      throw Exception(
          'OPENAI_API_KEY not found. For web apps, please add it using --dart-define=OPENAI_API_KEY=your_key when building/running the app.');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a knowledgeable music expert providing concise information about songs, artists, and albums.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception(
          'Failed to get response from OpenAI: ${response.statusCode} ${response.body}');
    }
  }
}
