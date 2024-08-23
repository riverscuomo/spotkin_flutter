import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:spotkin_flutter/app_core.dart';

class BackupService {
  final StorageService _storageService;
  final Function(Job) addJob;
  final Function(int, Job) updateJob;

  BackupService(this._storageService, this.addJob, this.updateJob);

  String createBackup(Job job) {
    final jobJson = job.toJson();
    final jsonString = jsonEncode(jobJson);
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Generate filename with current date and job name
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    final String fileName =
        'SPOTKIN_${job.targetPlaylist.name}_${formatter.format(now)}.json';

    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    html.document.body!.children.add(anchor);

    // Trigger download
    anchor.click();

    // Cleanup
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    return 'Backup file "$fileName" created and download initiated.';
  }

  Future<Map<String, dynamic>> importBackup() async {
    print('Starting importBackup method');
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.json';
    uploadInput.click();

    print('Waiting for file selection');
    await uploadInput.onChange.first;

    if (uploadInput.files!.isNotEmpty) {
      print('File selected: ${uploadInput.files![0].name}');
      final file = uploadInput.files![0];
      final reader = html.FileReader();
      reader.readAsText(file);

      print('Reading file contents');
      await reader.onLoad.first;

      final contents = reader.result as String;
      try {
        print('Parsing JSON contents');
        final jobJson = jsonDecode(contents);
        Job importedJob = Job.fromJson(jobJson);
        print('Imported job: ${importedJob.targetPlaylist.name}');

        print('Fetching existing jobs');
        List<Job> existingJobs = _storageService.getJobs();
        print('Found ${existingJobs.length} existing jobs');

        int existingIndex = existingJobs.indexWhere(
            (job) => job.targetPlaylist.id == importedJob.targetPlaylist.id);

        if (existingIndex != -1) {
          print('Updating existing job at index $existingIndex');
          updateJob(existingIndex, importedJob);
          return {
            'success': true,
            'message':
                'Job "${importedJob.targetPlaylist.name}" updated successfully.',
            'action': 'updated',
          };
        } else if (existingJobs.length < maxJobs) {
          print('Adding new job');
          addJob(importedJob);
          return {
            'success': true,
            'message':
                'Job "${importedJob.targetPlaylist.name}" added successfully.',
            'action': 'added',
          };
        } else {
          print('Max jobs reached, cannot add new job');
          return {
            'success': false,
            'message':
                'Maximum number of jobs (${maxJobs}) reached. Please delete a job before importing a new one.',
            'maxJobsReached': true,
          };
        }
      } catch (e) {
        print('Error during import: $e');
        return {
          'success': false,
          'message': 'Error importing job from ${file.name}: $e',
        };
      }
    } else {
      print('No file selected');
      return {
        'success': false,
        'message': 'No file selected for import.',
      };
    }
  }
}
