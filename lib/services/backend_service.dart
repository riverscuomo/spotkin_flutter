import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spotkin_flutter/app_core.dart';

class BackendService {
  String _accessToken;
  final String backendUrl;

  BackendService({required String accessToken, required this.backendUrl})
      : _accessToken = accessToken;

  void updateAccessToken(String newToken) {
    _accessToken = newToken;
  }

  Future<List<Job>> getJobs() async {
    final response = await http.get(
      Uri.parse('$backendUrl/process_job'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonData = json.decode(response.body);
      List<Job> jobs = [];
      jsonData.forEach((key, value) {
        if (value['job'] != null) {
          jobs.add(Job.fromJson(value['job']));
        }
      });
      return jobs;
    } else {
      throw Exception('Failed to load jobs');
    }
  }

  Future<List<Map<String, dynamic>>> processJobs(
      List<Job> jobs, List<int> indexes) async {
    List<Map<String, dynamic>> results = [];

    for (final index in indexes) {
      try {
        final job = jobs[index];
        final url = '$backendUrl/process_job';

        var jobJson = job.toJsonForPostRequest();
        jobJson['index'] = index;

        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $_accessToken',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: json.encode(jobJson),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          results.add({
            'name': job.targetPlaylist.name,
            'status': 'Success',
            'result': responseData['message'],
          });
        } else {
          results.add({
            'name': job.targetPlaylist.name,
            'status': 'Error',
            'result': 'Status ${response.statusCode}: ${response.body}',
          });
        }
      } catch (e) {
        results.add({
          'name': jobs[index].targetPlaylist.name,
          'status': 'Error',
          'result': e.toString(),
        });
      }
    }

    return results;
  }

  Future<void> updateJob(Job job) async {
    final response = await http.post(
      Uri.parse('$backendUrl/process_job'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode([job.toJsonForPostRequest()]),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update job');
    }
  }

  Future<void> createJob(Job job) async {
    final response = await http.post(
      Uri.parse('$backendUrl/process_job'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode([job.toJsonForPostRequest()]),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create job');
    }
  }

  Future<void> deleteJob(String playlistId) async {
    final response = await http.delete(
      Uri.parse('$backendUrl/process_job/$playlistId'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete job');
    }
  }
}
