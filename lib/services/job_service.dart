import 'dart:convert';
import 'dart:html' as html;

class Job {
  String id;
  String title;
  String description;

  Job({required this.id, required this.title, required this.description});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
  };

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    id: json['id'],
    title: json['title'],
    description: json['description'],
  );
}

class JobService {
  static const String _storageKey = 'jobs';

  List<Job> getJobs() {
    final String? storedJobs = html.window.localStorage[_storageKey];
    if (storedJobs == null) return [];
    final List<dynamic> decodedJobs = jsonDecode(storedJobs);
    return decodedJobs.map((job) => Job.fromJson(job)).toList();
  }

  void saveJobs(List<Job> jobs) {
    final String encodedJobs = jsonEncode(jobs.map((job) => job.toJson()).toList());
    html.window.localStorage[_storageKey] = encodedJobs;
  }

  void addJob(Job job) {
    final jobs = getJobs();
    jobs.add(job);
    saveJobs(jobs);
  }

  void updateJob(Job updatedJob) {
    final jobs = getJobs();
    final index = jobs.indexWhere((job) => job.id == updatedJob.id);
    if (index != -1) {
      jobs[index] = updatedJob;
      saveJobs(jobs);
    }
  }

  void deleteJob(String id) {
    final jobs = getJobs();
    jobs.removeWhere((job) => job.id == id);
    saveJobs(jobs);
  }
}