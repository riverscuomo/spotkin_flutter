import 'package:flutter/foundation.dart';
import 'package:spotkin_flutter/app_core.dart';

class JobProvider extends ChangeNotifier {
  List<Job> _jobs = [];
  bool _isLoading = false;
  final StorageService _storageService;

  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;

  JobProvider(this._storageService) {
    loadJobs();
  }

  Future<void> loadJobs() async {
    _isLoading = true;
    notifyListeners();

    _jobs = _storageService.getJobs();
    _isLoading = false;
    notifyListeners();
  }

  void addJob(Job job) {
    _jobs.add(job);
    _storageService.saveJobs(_jobs);
    notifyListeners();
  }

  void updateJob(int index, Job updatedJob) {
    if (index >= 0 && index < _jobs.length) {
      _jobs[index] = updatedJob;
      _storageService.saveJobs(_jobs);
      notifyListeners();
    }
  }

  void deleteJob(int index) {
    if (index >= 0 && index < _jobs.length) {
      _jobs.removeAt(index);
      _storageService.saveJobs(_jobs);
      notifyListeners();
    }
  }
}
