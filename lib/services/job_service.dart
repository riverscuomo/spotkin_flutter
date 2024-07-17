import 'dart:convert';
import 'dart:html' as html;
import 'package:spotkin_flutter/app_core.dart';




class JobService {
  static const String _storageKey = 'jobs';

  List<Job> getJobs() {
    final String? storedJobs = html.window.localStorage[_storageKey];
    if (storedJobs == null) return [];
    return parseJobs(storedJobs);
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
    final index = jobs.indexWhere((job) => job.playlistId == updatedJob.playlistId);
    if (index != -1) {
      jobs[index] = updatedJob;
      saveJobs(jobs);
    }
  }

  void deleteJob(String playlistId) {
    final jobs = getJobs();
    jobs.removeWhere((job) => job.playlistId == playlistId);
    saveJobs(jobs);
  }

  Job? getJobByPlaylistId(String playlistId) {
    final jobs = getJobs();
    try {
      return jobs.firstWhere((job) => job.playlistId == playlistId);
    } catch (e) {
      return null; // Return null if no job is found with the given playlistId
    }
  }
}