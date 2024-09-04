import 'dart:async';
import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class BackendService {
  final String backendUrl;
  final SpotifyService spotifyService;

  BackendService({required this.backendUrl, required this.spotifyService});

  Future<List<Job>> getJobs() async {
    final userId = await spotifyService.getUserId();
    final url = '$backendUrl/jobs/$userId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      return responseData.map((data) => Job.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load jobs: ${response.statusCode}');
    }
  }

  Future<Job> addJob(Job job) async {
    final url = '$backendUrl/jobs';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
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
    final userId = await spotifyService.getUserId();
    final url = '$backendUrl/process_jobs/$userId';

    final jobsToProcess = indexes.map((index) => jobs[index].id).toList();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${await spotifyService.retrieveAccessToken()}',
        },
        body: json.encode({
          'job_ids': jobsToProcess,
        }),
      );

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
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(job.toJson()),
    );

    if (response.statusCode == 200) {
      return Job.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update job: ${response.statusCode}');
    }
  }

  Future<void> deleteJob(String jobId) async {
    final url = '$backendUrl/jobs/$jobId';
    final response = await http.delete(Uri.parse(url));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete job: ${response.statusCode}');
    }
  }
}



// class BackendService {
//   final String accessToken;
//   final String backendUrl;

//   BackendService({required this.accessToken, required this.backendUrl});

//   Future<List<Map<String, dynamic>>> processJobs(
//       List<Job> jobs, List<int> indexes) async {
//     List<Map<String, dynamic>> results = [];
//     final spotifyService = GetIt.instance<SpotifyService>();

//     print('Processing jobs: ${jobs.length}, Indexes: $indexes');

//     for (final index in indexes) {
//       try {
//         print('Processing job at index: $index');

//         if (index >= jobs.length) {
//           throw RangeError(
//               'Index $index is out of range for jobs list of length ${jobs.length}');
//         }

//         final job = jobs[index];
//         final url = '$backendUrl/process_job';

//         print(
//             'Job details: ${job.targetPlaylist.name}, ${job.targetPlaylist.id}');

//         // Use SpotifyService to get the tokens
//         print('Retrieving Spotify credentials...');
//         final credentials = await spotifyService.retrieveCredentials();

//         if (credentials == null ||
//             credentials.accessToken == null ||
//             credentials.refreshToken == null) {
//           throw Exception('Spotify credentials are missing or incomplete');
//         }

//         print('Credentials retrieved successfully');

//         var jobJson = job.toJsonForPostRequest();
//         jobJson['index'] = index;

//         print('Preparing to send request to $url');
//         print('Request body: ${json.encode(jobJson)}');

//         try {
//           print('Sending request...');
//           final response = await http
//               .post(
//                 Uri.parse(url),
//                 headers: {
//                   'Authorization': 'Bearer ${credentials.accessToken}',
//                   'Refresh-Token': credentials.refreshToken!,
//                   'Content-Type': 'application/json',
//                   'Accept': 'application/json',
//                 },
//                 body: json.encode(jobJson),
//               )
//               .timeout(const Duration(seconds: 60));

//           print('Response received. Status: ${response.statusCode}');
//           print('Response body: ${response.body}');

//           if (response.statusCode == 200) {
//             final responseData = json.decode(response.body);

//             if (responseData['new_access_token'] != null) {
//               // Handle token refresh...
//             }

//             results.add({
//               'name': job.targetPlaylist.name,
//               'status': 'Success',
//               'result': responseData['message'],
//             });
//           } else {
//             results.add({
//               'name': job.targetPlaylist.name,
//               'status': 'Error',
//               'result': 'Status ${response.statusCode}: ${response.body}',
//             });
//           }
//         } catch (e) {
//           print('Error sending request: $e');
//           results.add({
//             'name': job.targetPlaylist.name,
//             'status': 'Error',
//             'result': 'Request error: ${e.toString()}',
//           });
//         }
//       } catch (e, stackTrace) {
//         print('Error processing job: $e');
//         print('Stack trace: $stackTrace');

//         results.add({
//           'name': index < jobs.length
//               ? jobs[index].targetPlaylist.name
//               : 'Unknown job',
//           'status': 'Error',
//           'result': e.toString(),
//         });
//       }
//     }

//     print('Processed jobs results: $results');
//     return results;
//   }
// }

// import 'dart:async';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:spotkin_flutter/app_core.dart';

// class BackendService {
//   final String backendUrl;
//   final SpotifyService spotifyService;

//   BackendService({required this.backendUrl, required this.spotifyService});

//   Future<List<Job>> getJobs() async {
//     final url = '$backendUrl/jobs/$userId';
//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final List<dynamic> responseData = json.decode(response.body);
//       return responseData.map((data) => Job.fromJson(data)).toList();
//     } else {
//       throw Exception('Failed to load jobs: ${response.statusCode}');
//     }
//   }

//   Future<List<Map<String, dynamic>>> processJobs(
//       List<Job> jobs, List<int> indexes) async {
//     List<Map<String, dynamic>> results = [];

//     for (final index in indexes) {
//       try {
//         if (index >= jobs.length) {
//           throw RangeError(
//               'Index $index is out of range for jobs list of length ${jobs.length}');
//         }

//         final job = jobs[index];
//         final url = '$backendUrl/process_job/${job.id}';

//         final credentials = await spotifyService.retrieveCredentials();
//         if (credentials == null ||
//             credentials.accessToken == null ||
//             credentials.refreshToken == null) {
//           throw Exception('Spotify credentials are missing or incomplete');
//         }

//         final response = await http.post(
//           Uri.parse(url),
//           headers: {
//             'Authorization': 'Bearer ${credentials.accessToken}',
//             'Refresh-Token': credentials.refreshToken!,
//             'Content-Type': 'application/json',
//             'Accept': 'application/json',
//           },
//         ).timeout(const Duration(minutes: 5));

//         if (response.statusCode == 200) {
//           final responseData = json.decode(response.body);
//           results.add({
//             'name': job.targetPlaylist.name,
//             'status': 'Success',
//             'result': responseData['message'],
//           });
//         } else {
//           results.add({
//             'name': job.targetPlaylist.name,
//             'status': 'Error',
//             'result': 'Status ${response.statusCode}: ${response.body}',
//           });
//         }
//       } catch (e) {
//         results.add({
//           'name': index < jobs.length
//               ? jobs[index].targetPlaylist.name
//               : 'Unknown job',
//           'status': 'Error',
//           'result': e.toString(),
//         });
//       }
//     }

//     return results;
//   }
// }
