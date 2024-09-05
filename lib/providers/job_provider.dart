import 'package:flutter/foundation.dart';
import 'package:spotkin_flutter/app_core.dart';

class JobProvider extends ChangeNotifier {
  List<Job> _jobs = [];
  bool _isLoading = false;
  final _backendService = getIt<BackendService>();

  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;

  JobProvider() {
    loadJobs();
  }

  Future<void> loadJobs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _jobs = await _backendService.getJobs();
    } catch (e) {
      print('Error loading jobs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addJob(Job job) async {
    try {
      final newJob = await _backendService.addJob(job);
      _jobs.add(newJob);
      notifyListeners();
    } catch (e) {
      print('Error adding job: $e');
    }
  }

  Future<void> updateJob(int index, Job updatedJob) async {
    try {
      final job = await _backendService.updateJob(updatedJob);
      _jobs[index] = job;
      notifyListeners();
    } catch (e) {
      print('Error updating job: $e');
    }
  }

  Future<void> deleteJob(int index) async {
    try {
      await _backendService.deleteJob(_jobs[index].id);
      _jobs.removeAt(index);
      notifyListeners();
    } catch (e) {
      print('Error deleting job: $e');
    }
  }
}
