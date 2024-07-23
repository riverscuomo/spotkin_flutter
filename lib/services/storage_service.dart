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
      // return [Job.empty()];
      return [];
    }
    List<Job> jobs = parseJobs(storedJobs);
    print("Loaded ${jobs.length} jobs from localStorage");
    for (var job in jobs) {
      print(
          "Job: ${job.targetPlaylist.name}, Playlist ID: ${job.targetPlaylist.id}, Recipe count: ${job.recipe.length}");
      for (var ingredient in job.recipe) {
        print(
            "  Ingredient: ${ingredient.playlist.id}, Quantity: ${ingredient.quantity}");
      }
    }
    return jobs;
  }

  void saveJobs(List<Job> jobs) {
    print("Saving ${jobs.length} jobs to localStorage");
    final String encodedJobs =
        jsonEncode(jobs.map((job) => job.toJson()).toList());
    html.window.localStorage[_storageKey] = encodedJobs;
    print("Jobs saved to localStorage");
    for (var job in jobs) {
      if (job.lastTrackIds.isNotEmpty) {
        // remove any empty strings from the list
        job.lastTrackIds.removeWhere((element) => element.isEmpty);
      }
      print(
          "Saved Job: ${job.targetPlaylist.name}, Playlist ID: ${job.targetPlaylist.id}, Recipe count: ${job.recipe.length}");
    }
  }

  void addJob(Job job) {
    print("Adding new job: ${job.targetPlaylist.name}");
    final jobs = getJobs();
    jobs.add(job);
    saveJobs(jobs);
  }

  void updateJob(Job job) {
    print("Updating job: ${job.targetPlaylist.name}");
    final jobs = getJobs();
    final index = jobs
        .indexWhere((job) => job.targetPlaylist.id == job.targetPlaylist.id);
    if (index != -1) {
      jobs[index] = job;
      saveJobs(jobs);
      print("Job updated successfully");
    } else {
      print("Job not found for updating");
    }
  }

  void deleteJob(String playlistId) {
    print("Deleting job with playlist ID: $playlistId");
    final jobs = getJobs();
    jobs.removeWhere((job) => job.targetPlaylist.id == playlistId);
    saveJobs(jobs);
  }

  Job? getJobByPlaylistId(String playlistId) {
    print("Searching for job with playlist ID: $playlistId");
    final jobs = getJobs();
    try {
      Job job = jobs.firstWhere((job) => job.targetPlaylist.id == playlistId);
      print(
          "Job found: ${job.targetPlaylist.name}, Recipe count: ${job.recipe.length}");
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
