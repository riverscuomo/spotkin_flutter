import 'dart:convert';
import 'dart:html' as html;
import 'package:spotkin_flutter/app_core.dart';

class StorageService {
  static const String _storageKey = 'jobs';

  List<Job> getJobs() {
    print("Attempting to load jobs from localStorage");
    final String? storedJobs = html.window.localStorage[_storageKey];
    if (storedJobs == null) {
      print("No jobs found in localStorage");
      return [];
    }
    List<Job> jobs = parseJobs(storedJobs);
    print("Loaded ${jobs.length} jobs from localStorage");
    for (var job in jobs) {
      print("Job: ${job.name}, Playlist ID: ${job.playlistId}, Recipe count: ${job.recipe.length}");
      for (var ingredient in job.recipe) {
        print("  Ingredient: ${ingredient.sourcePlaylistId}, Quantity: ${ingredient.quantity}");
      }
    }
    return jobs;
  }

  void saveJobs(List<Job> jobs) {
    print("Saving ${jobs.length} jobs to localStorage");
    final String encodedJobs = jsonEncode(jobs.map((job) => job.toJson()).toList());
    html.window.localStorage[_storageKey] = encodedJobs;
    print("Jobs saved to localStorage");
    for (var job in jobs) {
      print("Saved Job: ${job.name}, Playlist ID: ${job.playlistId}, Recipe count: ${job.recipe.length}");
    }
  }

  void addJob(Job job) {
    print("Adding new job: ${job.name}");
    final jobs = getJobs();
    jobs.add(job);
    saveJobs(jobs);
  }

  void updateJob(Job updatedJob) {
    print("Updating job: ${updatedJob.name}");
    final jobs = getJobs();
    final index = jobs.indexWhere((job) => job.playlistId == updatedJob.playlistId);
    if (index != -1) {
      jobs[index] = updatedJob;
      saveJobs(jobs);
      print("Job updated successfully");
    } else {
      print("Job not found for updating");
    }
  }

  void deleteJob(String playlistId) {
    print("Deleting job with playlist ID: $playlistId");
    final jobs = getJobs();
    jobs.removeWhere((job) => job.playlistId == playlistId);
    saveJobs(jobs);
  }

  Job? getJobByPlaylistId(String playlistId) {
    print("Searching for job with playlist ID: $playlistId");
    final jobs = getJobs();
    try {
      Job job = jobs.firstWhere((job) => job.playlistId == playlistId);
      print("Job found: ${job.name}, Recipe count: ${job.recipe.length}");
      return job;
    } catch (e) {
      print("No job found with playlist ID: $playlistId");
      return null;
    }
  }

  List<Job> parseJobs(String storedJobs) {
    try {
      final List<dynamic> decodedJobs = jsonDecode(storedJobs);
      return decodedJobs.map((jobJson) => Job.fromJson(jobJson)).toList();
    } catch (e) {
      print("Error parsing jobs: $e");
      return [];
    }
  }
}