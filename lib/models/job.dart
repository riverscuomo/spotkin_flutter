import 'dart:convert';
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/models/ingredient.dart';
import 'dart:convert';
import 'package:spotkin_flutter/models/ingredient.dart';

class Job {
  final String name;
  final String playlistId;
  final String description;
  final bool removeLowEnergy;
  final List<String> lastTrackIds;
  final List<String> bannedArtistNames;
  final List<String> bannedSongTitles;
  final List<String> bannedTrackIds;
  final List<String> bannedGenres;
  final List<String> exceptionsToBannedGenres;
  final List<Ingredient> recipe;

  Job({
    required this.name,
    required this.playlistId,
     this.description = '',
     this.removeLowEnergy = false,
     this.lastTrackIds  = const [],
     this.bannedArtistNames = const [],
     this.bannedSongTitles  = const [],
     this.bannedTrackIds = const [],
     this.bannedGenres  = const [],
     this.exceptionsToBannedGenres = const [],
     this.recipe = const [],
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      name: json['name'] ?? '',
      playlistId: json['playlist_id'] ?? '',
      description: json['description'] ?? '',
      removeLowEnergy: json['remove_low_energy'] == true,
      lastTrackIds: List<String>.from(json['last_track_ids'] ?? []),
      bannedArtistNames: List<String>.from(json['banned_artist_names'] ?? []),
      bannedSongTitles: List<String>.from(json['banned_song_titles'] ?? []),
      bannedTrackIds: List<String>.from(json['banned_track_ids'] ?? []),
      bannedGenres: List<String>.from(json['banned_genres'] ?? []),
      exceptionsToBannedGenres: List<String>.from(json['exceptions_to_banned_genres'] ?? []),
      recipe: (json['recipe'] as List<dynamic>?)
          ?.map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'playlist_id': playlistId,
      'description': description,
      'remove_low_energy': removeLowEnergy,
      'last_track_ids': lastTrackIds,
      'banned_artist_names': bannedArtistNames,
      'banned_song_titles': bannedSongTitles,
      'banned_track_ids': bannedTrackIds,
      'banned_genres': bannedGenres,
      'exceptions_to_banned_genres': exceptionsToBannedGenres,
      'recipe': recipe.map((r) => r.toJson()).toList(),
    };
  }

  Job copyWith({
    String? name,
    String? playlistId,
    String? description,
    bool? removeLowEnergy,
    List<String>? lastTrackIds,
    List<String>? bannedArtistNames,
    List<String>? bannedSongTitles,
    List<String>? bannedTrackIds,
    List<String>? bannedGenres,
    List<String>? exceptionsToBannedGenres,
    List<Ingredient>? recipe,
  }) {
    return Job(
      name: name ?? this.name,
      playlistId: playlistId ?? this.playlistId,
      description: description ?? this.description,
      removeLowEnergy: removeLowEnergy ?? this.removeLowEnergy,
      lastTrackIds: lastTrackIds ?? List.from(this.lastTrackIds),
      bannedArtistNames: bannedArtistNames ?? List.from(this.bannedArtistNames),
      bannedSongTitles: bannedSongTitles ?? List.from(this.bannedSongTitles),
      bannedTrackIds: bannedTrackIds ?? List.from(this.bannedTrackIds),
      bannedGenres: bannedGenres ?? List.from(this.bannedGenres),
      exceptionsToBannedGenres: exceptionsToBannedGenres ?? List.from(this.exceptionsToBannedGenres),
      recipe: recipe ?? List.from(this.recipe),
    );
  }
}

// Helper function to parse a list of Jobs from JSON string
List<Job> parseJobs(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList.map((jobJson) => Job.fromJson(jobJson as Map<String, dynamic>)).toList();
}