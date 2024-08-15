import 'dart:async';
import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class BackendService {
  final String accessToken;
  final String backendUrl;

  BackendService({required this.accessToken, required this.backendUrl});

  Future<List<Map<String, dynamic>>> processJobs(
      List<Job> jobs, List<int> indexes) async {
    List<Map<String, dynamic>> results = [];
    final spotifyService = GetIt.instance<SpotifyService>();

    for (final index in indexes) {
      try {
        final url = '$backendUrl/process_job';
        final job = jobs[index];

        // Use SpotifyService to get the tokens
        final credentials = await spotifyService.retrieveCredentials();

        if (credentials == null ||
            credentials.accessToken == null ||
            credentials.refreshToken == null) {
          throw Exception('Spotify credentials are missing or incomplete');
        }

        var jobJson = job.toJsonForPostRequest();
        jobJson['index'] = index;
        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer ${credentials.accessToken}',
                'Refresh-Token': credentials.refreshToken!,
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: json.encode(jobJson),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          // Check if a new access token was returned
          if (responseData['new_access_token'] != null) {
            // Update the credentials with the new access token
            final newCredentials = SpotifyApiCredentials(
              credentials.clientId,
              credentials.clientSecret,
              accessToken: responseData['new_access_token'],
              refreshToken: credentials.refreshToken,
              expiration: DateTime.now()
                  .add(const Duration(hours: 1)), // Assuming 1 hour validity
              scopes: credentials.scopes,
            );
            await spotifyService.saveCredentials(newCredentials);
          }

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
          'name': jobs[index].isNull
              ? 'Unknown job'
              : jobs[index].targetPlaylist.name,
          'status': 'Error',
          'result': e.toString(),
        });
      }
    }

    return results;
  }
}
