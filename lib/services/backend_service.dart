import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spotkin_flutter/app_core.dart';

class BackendService {
  final String backendUrl;

  BackendService({required this.backendUrl});

  Future<List<Job>> getJobs() async {
    print('backendService.getJobs');
    final spotifyService = getIt<SpotifyService>();
    final userId = await spotifyService.getUserId();
    final url = '$backendUrl/jobs/$userId';
    print('url: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: await _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      print('responseData: $responseData');
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

  Future<List<Map<String, dynamic>>> processJobs(
      List<Job> jobs, List<int> indexes) async {
    final spotifyService = getIt<SpotifyService>();
    final userId = await spotifyService.getUserId();
    final url = '$backendUrl/process_jobs/$userId';

    final jobsToProcess = indexes.map((index) => jobs[index].id).toList();

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: await _getAuthHeaders(),
            body: json.encode({'job_ids': jobsToProcess}),
          )
          .timeout(const Duration(minutes: 5));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to process jobs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error processing jobs: $e');
      rethrow;
    }
  }

  Future<Job> updateJob(Job job) async {
    final url = '$backendUrl/jobs/${job.id}';
    print('updateJob: $url');
    final response = await http.put(
      Uri.parse(url),
      headers: await _getAuthHeaders(),
      body: json.encode(job.toJsonForApiRequest()),
    );

    if (response.statusCode == 200) {
      return Job.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update job: ${response.statusCode}');
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

  Future<Map<String, String>> _getAuthHeaders() async {
    final spotifyService = getIt<SpotifyService>();

    final credentials = await spotifyService
        .retrieveCredentials(); // This method already handles refreshing the token
    if (credentials == null) {
      throw Exception("Failed to retrieve Spotify credentials");
    }

    return {
      'Authorization': 'Bearer ${credentials.accessToken}',
      'Content-Type': 'application/json',
    };
  }
}
