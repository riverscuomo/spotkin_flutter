import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spotkin_flutter/app_core.dart';

class ApiService {
  final String accessToken;
  final String backendUrl;

  ApiService({required this.accessToken, required this.backendUrl});

  Future<List<Map<String, dynamic>>> processJobs(List<Job> jobs) async {
    List<Map<String, dynamic>> results = [];

    for (var job in jobs) {
      try {
        final url = '$backendUrl/process_job';
        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: json.encode(job.toJsonForPostRequest()),
            )
            .timeout(Duration(seconds: 60));

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          results.add({
            'name': job.targetPlaylist.name,
            'status': 'Success',
            'result': responseData['message']
          });
        } else {
          results.add({
            'name': job.targetPlaylist.name,
            'status': 'Error',
            'result': 'Status ${response.statusCode}: ${response.body}'
          });
        }
      } catch (e) {
        results.add({
          'name': job.targetPlaylist.name,
          'status': 'Error',
          'result': e.toString()
        });
      }
    }

    return results;
  }
}
