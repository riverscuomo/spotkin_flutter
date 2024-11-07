import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
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
    print('Loading jobs...');
    _isLoading = true;
    notifyListeners();

    try {
      _jobs = await _backendService.getJobs();

      print('Jobs loaded: ${_jobs.length}');
      // if (_jobs.isEmpty) {
      //   print('Adding empty job');
      //   _jobs.add(Job.empty());
      // }
    } catch (e) {
      print('Error loading jobs: $e');
      if (e.runtimeType == ClientException) {
        print('Did you forget to run the backend server locally?');
      }
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
    // Store the original job in case we need to revert
    final originalJob = _jobs[index];

    try {
      // Update local state immediately
      _jobs[index] = updatedJob;
      notifyListeners();

      // Then update backend
      await _backendService.updateJob(updatedJob);
    } catch (e) {
      // If backend update fails, revert to original state
      print('Error updating job: $e');
      _jobs[index] = originalJob;
      notifyListeners();

      // Optionally show an error message to the user
      // You'll need to have access to a BuildContext or use a different state management
      // solution for showing errors
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
