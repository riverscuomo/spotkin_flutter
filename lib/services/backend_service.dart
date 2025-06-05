import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spotkin_flutter/app_core.dart';

class BackendService {
  final String backendUrl;

  BackendService({required this.backendUrl});

  Future<List<Job>> getJobs() async {
    debugPrint('backendService.getJobs');
    final spotifyService = getIt<SpotifyService>();
    final userId = await spotifyService.getUserId();
    final url = '$backendUrl/jobs/$userId';
    debugPrint('url: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      debugPrint('responseData: ${responseData.length}');
      if (responseData.isEmpty) {
        return [Job.empty()];
      }
      return responseData.map((data) => Job.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load jobs: ${response.statusCode}');
    }
  }

  Future<Job> addJob(Job job) async {
    final spotifyService = getIt<SpotifyService>();
    final userId = await spotifyService.getUserId();
    final url = '$backendUrl/jobs/$userId'; // Add the userId to the URL

    final response = await http.post(
      Uri.parse(url),
      headers: await _getAuthHeaders(),
      body: json.encode(job.toJson()),
    );

    if (response.statusCode == 201) {
      return Job.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add job: ${response.statusCode}');
    }
  }

  Future<void> deleteJob(String jobId) async {
    final url = '$backendUrl/jobs/$jobId';
    final response = await http.delete(
      Uri.parse(url),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete job: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> processJob(String jobId) async {
    final url = '$backendUrl/process_job/$jobId';
    try {
      final headers = await _getAuthHeaders();
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: json.encode(await _getRequestBody()),
          )
          .timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        final Map responseData = json.decode(response.body);
        return responseData as Map<String, dynamic>;
      } else {
        throw Exception('Failed to process jobs: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error processing jobs: $e');
      rethrow;
    }
  }

  Future<Job> updateJob(Job job) async {
    final url = '$backendUrl/jobs/${job.id}';
    debugPrint('updateJob: $url');
    final response = await http.put(
      Uri.parse(url),
      headers: await _getAuthHeaders(),
      body: json.encode(job.toJson()),
    );

    if (response.statusCode == 200) {
      return Job.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update job: ${response.statusCode}');
    }
  }

  /// Add a source to a job based on a track, artist, or album
  /// Type should be one of: 'track', 'artist', or 'album'
  Future<Job> addSourceToJob(String jobId, String type, String itemId, String itemName) async {
    final url = '$backendUrl/jobs/$jobId/sources';
    debugPrint('Adding source to job: $type:$itemName');
    
    // Get user ID from SpotifyService
    final spotifyService = getIt<SpotifyService>();
    final spotifyUser = await spotifyService.getCurrentUser();
    final userId = spotifyUser?.id;
    
    if (userId == null) {
      throw Exception('Failed to get Spotify user ID');
    }
    
    final payload = {
      'type': type,
      'item_id': itemId,
      'item_name': itemName,
      'user_id': userId,
    };
    
    final response = await http.post(
      Uri.parse(url),
      headers: await _getAuthHeaders(),
      body: json.encode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Job.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add source to job: ${response.statusCode}');
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final spotifyService = getIt<SpotifyService>();

    final credentials = await spotifyService.retrieveCredentials();

    if (credentials == null) {
      throw Exception("Failed to retrieve Spotify credentials");
    }

    // Send only the authorization header here
    return {
      'Authorization': 'Bearer ${credentials.accessToken}',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> _getRequestBody() async {
    final spotifyService = getIt<SpotifyService>();

    final credentials = await spotifyService.retrieveCredentials();

    if (credentials == null) {
      throw Exception("Failed to retrieve Spotify credentials");
    }

    final expirationString =
        (credentials.expiration?.millisecondsSinceEpoch ?? 0) ~/ 1000;

    // Send refresh token and expiration in the body
    return {
      'refresh_token': credentials.refreshToken ?? '',
      'expires_at': expirationString,
    };
  }
}
