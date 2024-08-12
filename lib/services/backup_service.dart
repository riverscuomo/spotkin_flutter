import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:spotkin_flutter/app_core.dart';

class BackupService {
  final StorageService _storageService;
  final Function(Job) addJob;
  final Function(int, Job) updateJob;

  BackupService(this._storageService, this.addJob, this.updateJob);

  void createBackup() {
    List<Job> jobs = _storageService.getJobs();
    final jobsJson = jobs.map((job) => job.toJson()).toList();
    final jsonString = jsonEncode(jobsJson);
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Generate filename with current date
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    final String fileName = 'spotkin_jobs_backup_${formatter.format(now)}.json';

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

    print('Backup file "$fileName" created and download initiated.');
  }

  Future<void> importBackup() async {
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '.json';
    uploadInput.click();

    await uploadInput.onChange.first;

    if (uploadInput.files!.isNotEmpty) {
      final file = uploadInput.files![0];
      final reader = html.FileReader();
      reader.readAsText(file);

      await reader.onLoad.first;

      final contents = reader.result as String;
      try {
        final List<dynamic> jsonList = jsonDecode(contents);
        List<Job> importedJobs =
            jsonList.map((json) => Job.fromJson(json)).toList();

        // Merge imported jobs with existing jobs
        List<Job> existingJobs = _storageService.getJobs();
        for (var importedJob in importedJobs) {
          int existingIndex = existingJobs.indexWhere(
              (job) => job.targetPlaylist.id == importedJob.targetPlaylist.id);
          if (existingIndex != -1) {
            // Update existing job
            updateJob(existingIndex, importedJob);
            existingJobs[existingIndex] = importedJob;
          } else {
            // Add new job
            addJob(importedJob);
            existingJobs.add(importedJob);
          }
        }

        // Save merged jobs
        _storageService.saveJobs(existingJobs);
        print(
            'Imported and merged ${importedJobs.length} jobs from ${file.name}.');
      } catch (e) {
        print('Error importing jobs from ${file.name}: $e');
      }
    } else {
      print('No file selected for import.');
    }
  }
}
