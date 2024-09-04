import 'package:flutter/foundation.dart';
import 'package:spotkin_flutter/app_core.dart';

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


// class JobProvider extends ChangeNotifier {
//   List<Job> _jobs = [];
//   bool _isLoading = false;
//   final StorageService _storageService;
//   final BackendService _backendService;

//   List<Job> get jobs => _jobs;
//   bool get isLoading => _isLoading;

//   JobProvider(this._backendService, this._storageService) {
//     loadJobs();
//   }

//   Future<void> loadJobs() async {
//     _isLoading = true;
//     notifyListeners();

//     // _jobs = _storageService.getJobs();
//     _jobs = await _backendService.getJobs();
//     _isLoading = false;
//     notifyListeners();
//   }

//   void addJob(Job job) {
//     _jobs.add(job);
//     _storageService.saveJobs(_jobs);
//     notifyListeners();
//   }

//   void updateJob(int index, Job updatedJob) {
//     if (index >= 0 && index < _jobs.length) {
//       _jobs[index] = updatedJob;
//       _storageService.saveJobs(_jobs);
//       notifyListeners();
//     }
//   }

//   void deleteJob(int index) {
//     if (index >= 0 && index < _jobs.length) {
//       _jobs.removeAt(index);
//       _storageService.saveJobs(_jobs);
//       notifyListeners();
//     }
//   }
// }
