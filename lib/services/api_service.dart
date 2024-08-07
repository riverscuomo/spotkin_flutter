import 'dart:async';
import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class ApiService {
  final String accessToken;
  final String backendUrl;

  ApiService({required this.accessToken, required this.backendUrl});

  Future<List<Map<String, dynamic>>> processJobs(List<Job> jobs) async {
    List<Map<String, dynamic>> results = [];
    final spotifyService = GetIt.instance<SpotifyService>();

    for (var job in jobs) {
      try {
        final url = '$backendUrl/process_job';

        // Use SpotifyService to get the access token
        final accessToken = await spotifyService.retrieveAccessToken();
        final credentials = await spotifyService.retrieveCredentials();

        if (accessToken == null || credentials == null) {
          throw Exception('Access token or credentials are missing');
        }

        final response = await http
            .post(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Refresh-Token': credentials.refreshToken ?? '',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: json.encode(job.toJsonForPostRequest()),
            )
            .timeout(Duration(seconds: 60));

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
                  .add(Duration(hours: 1)), // Assuming 1 hour validity
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
          'name': job.targetPlaylist.name,
          'status': 'Error',
          'result': e.toString(),
        });
      }
    }

    return results;
  }
}
