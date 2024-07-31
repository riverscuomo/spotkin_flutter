import 'dart:convert';
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/models/ingredient.dart';
import 'package:spotify/spotify.dart';

class Job {
  final PlaylistSimple targetPlaylist;
  final String description;
  final bool removeLowEnergy;
  final List<Track> lastTracks;
  final List<Artist> bannedArtists;
  final List<Track> bannedTracks;
  final List<String> bannedGenres;
  final List<Artist> exceptionsToBannedGenres;
  final List<Ingredient> recipe;

  Job({
    required this.targetPlaylist,
    this.description = '',
    this.removeLowEnergy = false,
    this.lastTracks = const [],
    this.bannedArtists = const [],
    this.bannedTracks = const [],
    this.bannedGenres = const [],
    this.exceptionsToBannedGenres = const [],
    this.recipe = const [],
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      targetPlaylist: PlaylistSimple.fromJson(
          json['target_playlist'] as Map<String, dynamic>),
      description: json['description'] ?? '',
      removeLowEnergy: json['remove_low_energy'] == true,
      lastTracks: List<Track>.from(json['last_tracks'] ?? []),
      bannedArtists: List<Artist>.from(
          json['banned_artists']?.map((x) => Artist.fromJson(x)) ?? []),
      bannedTracks: List<Track>.from(
          json['banned_tracks']?.map((x) => Track.fromJson(x)) ?? []),
      bannedGenres: List<String>.from(json['banned_genres'] ?? []),
      exceptionsToBannedGenres:
          List<Artist>.from(json['exceptions_to_banned_genres']?.map((x) {
                return Artist.fromJson(x);
              }) ??
              []),
      recipe: (json['recipe'] as List<dynamic>?)
              ?.map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'target_playlist': targetPlaylist.toJson(),
      'description': description,
      'remove_low_energy': removeLowEnergy,
      'last_tracks': lastTracks,
      'banned_artists': bannedArtists,
      'banned_tracks': bannedTracks,
      'banned_genres': bannedGenres,
      'exceptions_to_banned_genres': exceptionsToBannedGenres,
      'recipe': recipe.map((r) => r.toJson()).toList(),
    };
  }

  Map<String, dynamic> toJsonForPostRequest() {
    return {
      'name': targetPlaylist.name,
      'playlist_id': targetPlaylist.id,
      'description': description,
      'remove_low_energy': removeLowEnergy,
      'last_track_ids': lastTracks.map((t) => t.id).toList(),
      'banned_artists': bannedArtists,
      'banned_tracks': bannedTracks.map((t) => t.id).toList(),
      'banned_genres': bannedGenres,
      'exceptions_to_banned_genres': exceptionsToBannedGenres,
      'recipe': recipe.map((r) => r.toJsonForPost()).toList(),
    };
  }

  Job.empty() : this(targetPlaylist: PlaylistSimple());

  Job copyWith({
    PlaylistSimple? targetPlaylist,
    String? description,
    bool? removeLowEnergy,
    List<Track>? lastTracks,
    List<Artist>? bannedArtists,
    List<Track>? bannedTracks,
    List<String>? bannedGenres,
    List<Artist>? exceptionsToBannedGenres,
    List<Ingredient>? recipe,
  }) {
    return Job(
      targetPlaylist: targetPlaylist ?? this.targetPlaylist,
      description: description ?? this.description,
      removeLowEnergy: removeLowEnergy ?? this.removeLowEnergy,
      lastTracks: lastTracks ?? this.lastTracks,
      bannedArtists: bannedArtists ?? this.bannedArtists,
      bannedTracks: bannedTracks ?? this.bannedTracks,
      bannedGenres: bannedGenres ?? this.bannedGenres,
      exceptionsToBannedGenres:
          exceptionsToBannedGenres ?? this.exceptionsToBannedGenres,
      recipe: recipe ?? this.recipe,
    );
  }
}

// Helper function to parse a list of Jobs from JSON string
List<Job> parseJobs(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString);
  return jsonList
      .map((jobJson) => Job.fromJson(jobJson as Map<String, dynamic>))
      .toList();
}
