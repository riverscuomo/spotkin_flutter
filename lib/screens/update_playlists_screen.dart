import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UpdatePlaylistsScreen extends StatefulWidget {
  final String accessToken;
  final String backendUrl;
  final String sampleJobs;

  UpdatePlaylistsScreen({
    required this.accessToken,
    required this.backendUrl,
    required this.sampleJobs,
  });

  @override
  _UpdatePlaylistsScreenState createState() => _UpdatePlaylistsScreenState();
}

class _UpdatePlaylistsScreenState extends State<UpdatePlaylistsScreen> {
  List<Map<String, dynamic>> jobResults = [];
  bool isProcessing = false;

Future<void> _processJobs() async {
  setState(() {
    isProcessing = true;
    jobResults.clear();
  });

  List<dynamic> jobs = json.decode(widget.sampleJobs);
  
  for (var job in jobs) {
    try {
      final url = '${widget.backendUrl}/process_job';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(job),
      ).timeout(Duration(seconds: 60));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          jobResults.add({
            'name': job['name'],
            'status': 'Success',
            'result': responseData['message']
          });
        });
      } else {
        setState(() {
          jobResults.add({
            'name': job['name'],
            'status': 'Error',
            'result': 'Status ${response.statusCode}: ${response.body}'
          });
        });
      }
    } catch (e) {
      setState(() {
        jobResults.add({
          'name': job['name'],
          'status': 'Error',
          'result': e.toString()
        });
      });
    }
  }

  setState(() {
    isProcessing = false;
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Playlists')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: isProcessing ? null : _processJobs,
              child: Text(isProcessing ? 'Processing...' : 'Update Playlists'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: jobResults.isEmpty
                ? Center(child: Text('No jobs processed yet.'))
                : ListView.builder(
                    itemCount: jobResults.length,
                    itemBuilder: (context, index) {
                      final result = jobResults[index];
                      return ListTile(
                        title: Text(result['name']),
                        subtitle: Text(result['result']),
                        leading: Icon(
                          result['status'] == 'Success' ? Icons.check_circle : Icons.error,
                          color: result['status'] == 'Success' ? Colors.green : Colors.red,
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}



