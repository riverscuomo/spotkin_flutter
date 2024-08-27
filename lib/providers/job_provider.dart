import 'package:flutter/foundation.dart';
import 'package:spotkin_flutter/services/backend_service.dart';
import 'package:spotkin_flutter/models/job.dart';

class JobProvider extends ChangeNotifier {
  List<Job> _jobs = [];
  bool _isLoading = false;
  final BackendService _backendService;

  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;

  JobProvider(this._backendService) {
    loadJobs();
  }

  Future<void> loadJobs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _jobs = await _backendService.getJobs();
      if (_jobs.isEmpty) {
        _jobs.add(Job.empty()); // Add an empty job if there are no jobs
      }
    } catch (e) {
      print('Error loading jobs: $e');
      _jobs = [Job.empty()]; // Ensure there's always at least one job
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> processJobs(List<int> indexes) async {
    try {
      final results = await _backendService.processJobs(_jobs, indexes);
      await loadJobs(); // Reload jobs after processing
      return results;
    } catch (e) {
      print('Error processing jobs: $e');
      return [];
    }
  }

  Future<void> updateJob(int index, Job updatedJob) async {
    try {
      await _backendService.updateJob(updatedJob);
      _jobs[index] = updatedJob;
      notifyListeners();
    } catch (e) {
      print('Error updating job: $e');
    }
  }

  Future<void> addJob(Job job) async {
    try {
      await _backendService.createJob(job);
      await loadJobs(); // Reload jobs to get the newly created job
    } catch (e) {
      print('Error adding job: $e');
    }
  }

  Future<void> deleteJob(int index) async {
    try {
      await _backendService.deleteJob(_jobs[index].targetPlaylist.id!);
      await loadJobs(); // Reload jobs to reflect the deletion
    } catch (e) {
      print('Error deleting job: $e');
    }
  }

  Job? getJobByPlaylistId(String playlistId) {
    return _jobs.firstWhere(
      (job) => job.targetPlaylist.id == playlistId,
      orElse: () => null as Job,
    );
  }

  Job getJob(int index) {
    if (index >= 0 && index < _jobs.length) {
      return _jobs[index];
    }
    return Job.empty(); // Return an empty job if index is out of range
  }
}
