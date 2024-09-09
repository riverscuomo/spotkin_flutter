import 'dart:convert';
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/models/ingredient.dart';
import 'package:spotify/spotify.dart';
import 'package:uuid/uuid.dart';

class Job {
  final String id;
  final PlaylistSimple targetPlaylist;
  final String description;
  final bool banSkits;
  final List<Track> lastTracks;
  final List<Artist> bannedArtists;
  final List<Track> bannedTracks;
  final List<String> bannedGenres;
  final List<Artist> exceptionsToBannedGenres;
  final List<Ingredient> recipe;
  final int scheduledTime;

  // Updated properties
  final int? minPopularity;
  final int? maxPopularity;
  final int? minDuration;
  final int? maxDuration;
  final int? minDanceability;
  final int? maxDanceability;
  final int? minEnergy;
  final int? maxEnergy;
  final int? minAcousticness;
  final int? maxAcousticness;

  Job({
    required this.id,
    required this.targetPlaylist,
    this.description = '',
    this.banSkits = false,
    this.lastTracks = const [],
    this.bannedArtists = const [],
    this.bannedTracks = const [],
    this.bannedGenres = const [],
    this.exceptionsToBannedGenres = const [],
    this.recipe = const [],
    int? scheduledTime,
    this.minPopularity,
    this.maxPopularity,
    this.minDuration,
    this.maxDuration,
    this.minDanceability,
    this.maxDanceability,
    this.minEnergy,
    this.maxEnergy,
    this.minAcousticness,
    this.maxAcousticness,
  }) : scheduledTime = scheduledTime ?? _getLocalMidnightInUTC();

  static int _getLocalMidnightInUTC() {
    final now = DateTime.now();
    final localOffset = now.timeZoneOffset.inHours;
    return (24 - localOffset) % 24;
  }

  bool get isNull => targetPlaylist.id == null;

  factory Job.fromJson(Map<String, dynamic> json) {
    print('Job.fromJson: ${json['target_playlist']['name']}');
    return Job(
      id: json['id'],
      targetPlaylist: PlaylistSimple.fromJson(
          json['target_playlist'] as Map<String, dynamic>),
      description: json['description'] ?? '',
      scheduledTime: json['scheduled_time'] ?? _getLocalMidnightInUTC(),
      banSkits: json['ban_skits'] == true,
      lastTracks: List<Track>.from(
          json['last_tracks']?.map((x) => Track.fromJson(x)) ?? []),
      bannedArtists: List<Artist>.from(
          json['banned_artists']?.map((x) => Artist.fromJson(x)) ?? []),
      bannedTracks: List<Track>.from(
          json['banned_tracks']?.map((x) => Track.fromJson(x)) ?? []),
      bannedGenres: [json['banned_genres']],
      exceptionsToBannedGenres:
          List<Artist>.from(json['exceptions_to_banned_genres']?.map((x) {
                return Artist.fromJson(x);
              }) ??
              []),
      recipe: (json['recipe'] as List<dynamic>?)
              ?.map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      minPopularity: json['min_popularity'],
      maxPopularity: json['max_popularity'],
      minDuration: json['min_duration'],
      maxDuration: json['max_duration'],
      minDanceability: json['min_danceability'],
      maxDanceability: json['max_danceability'],
      minEnergy: json['min_energy'],
      maxEnergy: json['max_energy'],
      minAcousticness: json['min_acousticness'],
      maxAcousticness: json['max_acousticness'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'target_playlist': targetPlaylist.toJson(),
      'description': description,
      'scheduled_time': scheduledTime,
      'ban_skits': banSkits,
      'last_tracks': lastTracks,
      'banned_artists': bannedArtists,
      'banned_tracks': bannedTracks,
      'banned_genres': bannedGenres,
      'exceptions_to_banned_genres': exceptionsToBannedGenres,
      'recipe': recipe.map((r) => r.toJson()).toList(),
      'min_popularity': minPopularity,
      'max_popularity': maxPopularity,
      'min_duration': minDuration,
      'max_duration': maxDuration,
      'min_danceability': minDanceability,
      'max_danceability': maxDanceability,
      'min_energy': minEnergy,
      'max_energy': maxEnergy,
      'min_acousticness': minAcousticness,
      'max_acousticness': maxAcousticness,
    };
  }

  // Map<String, dynamic> toJsonForApiRequest() {

  //   Map<String, dynamic> json = {
  //     'target_playlist': targetPlaylist.toJson(),
  //   };

  //   void addIfNotEmpty(String key, dynamic value) {
  //     if (value != null) {
  //       if (value is String && value.isNotEmpty) {
  //         json[key] = value;
  //       } else if (value is List && value.isNotEmpty) {
  //         json[key] = value;
  //       } else if (value is int || value is bool) {
  //         json[key] = value;
  //       } else if (value is Track) {
  //         json[key] = value.toJson();
  //       } else if (value is Artist) {
  //         json[key] = value.toJson();
  //       }
  //     }
  //   }

  //   void addIfNotDefault(String key, dynamic value, dynamic defaultValue) {
  //     if (value != null && value != defaultValue) {
  //       json[key] = value;
  //     }
  //   }

  //   addIfNotEmpty('name', targetPlaylist.name);
  //   addIfNotDefault('scheduled_time', scheduledTime, 0);
  //   addIfNotEmpty('description', description);
  //   addIfNotDefault('ban_skits', banSkits, false);

  //   addIfNotEmpty('last_tracks', lastTracks);
  //   addIfNotEmpty('banned_artists', bannedArtists);
  //   addIfNotEmpty('banned_tracks', bannedTracks);

  //   addIfNotEmpty('recipe', recipe.map((r) => r.toJsonForPost()).toList());

  //   addIfNotEmpty('banned_genres', bannedGenres);
  //   addIfNotEmpty('exceptions_to_banned_genres',
  //       exceptionsToBannedGenres.map((a) => a.id).toList());

  //   addIfNotDefault('min_popularity', minPopularity, null);
  //   addIfNotDefault('max_popularity', maxPopularity, null);
  //   addIfNotDefault('min_duration', minDuration, null);
  //   addIfNotDefault('max_duration', maxDuration, null);
  //   addIfNotDefault('min_danceability', minDanceability, null);
  //   addIfNotDefault('max_danceability', maxDanceability, null);
  //   addIfNotDefault('min_energy', minEnergy, null);
  //   addIfNotDefault('max_energy', maxEnergy, null);
  //   addIfNotDefault('min_acousticness', minAcousticness, null);
  //   addIfNotDefault('max_acousticness', maxAcousticness, null);

  //   return json;
  // }

  // Empty constructor with a generated ID
  Job.empty() : this(id: const Uuid().v4(), targetPlaylist: PlaylistSimple());

  Job copyWith({
    String? id,
    PlaylistSimple? targetPlaylist,
    String? description,
    int? scheduledTime,
    bool? banSkits,
    List<Track>? lastTracks,
    List<Artist>? bannedArtists,
    List<Track>? bannedTracks,
    List<String>? bannedGenres,
    List<Artist>? exceptionsToBannedGenres,
    List<Ingredient>? recipe,
    int? minPopularity,
    int? maxPopularity,
    int? minDuration,
    int? maxDuration,
    int? minDanceability,
    int? maxDanceability,
    int? minEnergy,
    int? maxEnergy,
    int? minAcousticness,
    int? maxAcousticness,
  }) {
    return Job(
      id: id ?? this.id,
      targetPlaylist: targetPlaylist ?? this.targetPlaylist,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      banSkits: banSkits ?? this.banSkits,
      lastTracks: lastTracks ?? this.lastTracks,
      bannedArtists: bannedArtists ?? this.bannedArtists,
      bannedTracks: bannedTracks ?? this.bannedTracks,
      bannedGenres: bannedGenres ?? this.bannedGenres,
      exceptionsToBannedGenres:
          exceptionsToBannedGenres ?? this.exceptionsToBannedGenres,
      recipe: recipe ?? this.recipe,
      minPopularity: minPopularity ?? this.minPopularity,
      maxPopularity: maxPopularity ?? this.maxPopularity,
      minDuration: minDuration ?? this.minDuration,
      maxDuration: maxDuration ?? this.maxDuration,
      minDanceability: minDanceability ?? this.minDanceability,
      maxDanceability: maxDanceability ?? this.maxDanceability,
      minEnergy: minEnergy ?? this.minEnergy,
      maxEnergy: maxEnergy ?? this.maxEnergy,
      minAcousticness: minAcousticness ?? this.minAcousticness,
      maxAcousticness: maxAcousticness ?? this.maxAcousticness,
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
// class Job {
//   final PlaylistSimple targetPlaylist;
//   final String description;
//   final bool removeLowEnergy;
//   final List<Track> lastTracks;
//   final List<Artist> bannedArtists;
//   final List<Track> bannedTracks;
//   final List<String> bannedGenres;
//   final List<Artist> exceptionsToBannedGenres;
//   final List<Ingredient> recipe;
//   final int scheduledTime;

//   Job({
//     required this.targetPlaylist,
//     this.description = '',
//     this.removeLowEnergy = false,
//     this.lastTracks = const [],
//     this.bannedArtists = const [],
//     this.bannedTracks = const [],
//     this.bannedGenres = const [],
//     this.exceptionsToBannedGenres = const [],
//     this.recipe = const [],
//     this.scheduledTime = 0,
//   });

//   factory Job.fromJson(Map<String, dynamic> json) {
//     return Job(
//       targetPlaylist: PlaylistSimple.fromJson(
//           json['target_playlist'] as Map<String, dynamic>),
//       description: json['description'] ?? '',
//       scheduledTime: json['scheduled_time'] ?? 0,
//       removeLowEnergy: json['remove_low_energy'] == true,
//       lastTracks: List<Track>.from(
//           json['last_tracks']?.map((x) => Track.fromJson(x)) ?? []),
//       bannedArtists: List<Artist>.from(
//           json['banned_artists']?.map((x) => Artist.fromJson(x)) ?? []),
//       bannedTracks: List<Track>.from(
//           json['banned_tracks']?.map((x) => Track.fromJson(x)) ?? []),
//       bannedGenres: List<String>.from(json['banned_genres'] ?? []),
//       exceptionsToBannedGenres:
//           List<Artist>.from(json['exceptions_to_banned_genres']?.map((x) {
//                 return Artist.fromJson(x);
//               }) ??
//               []),
//       recipe: (json['recipe'] as List<dynamic>?)
//               ?.map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
//               .toList() ??
//           [],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'target_playlist': targetPlaylist.toJson(),
//       'description': description,
//       'scheduled_time': scheduledTime,
//       'remove_low_energy': removeLowEnergy,
//       'last_tracks': lastTracks,
//       'banned_artists': bannedArtists,
//       'banned_tracks': bannedTracks,
//       'banned_genres': bannedGenres,
//       'exceptions_to_banned_genres': exceptionsToBannedGenres,
//       'recipe': recipe.map((r) => r.toJson()).toList(),
//     };
//   }

//   Map<String, dynamic> toJsonForApiRequest() {
//     return {
//       'name': targetPlaylist.name,
//       'playlist_id': targetPlaylist.id,
//       'scheduled_time': scheduledTime,
//       'description': description,
//       'remove_low_energy': removeLowEnergy,
//       'last_track_ids': lastTracks.map((t) => t.id).toList(),
//       'banned_artists': bannedArtists.map((a) => a.id).toList(),
//       'banned_tracks': bannedTracks.map((t) => t.id).toList(),
//       'banned_genres': bannedGenres,
//       'exceptions_to_banned_genres':
//           exceptionsToBannedGenres.map((a) => a.id).toList(),
//       'recipe': recipe.map((r) => r.toJsonForPost()).toList(),
//     };
//   }

//   Job.empty() : this(targetPlaylist: PlaylistSimple());

//   Job copyWith({
//     PlaylistSimple? targetPlaylist,
//     String? description,
//     int? scheduledTime,
//     bool? removeLowEnergy,
//     List<Track>? lastTracks,
//     List<Artist>? bannedArtists,
//     List<Track>? bannedTracks,
//     List<String>? bannedGenres,
//     List<Artist>? exceptionsToBannedGenres,
//     List<Ingredient>? recipe,
//   }) {
//     return Job(
//       targetPlaylist: targetPlaylist ?? this.targetPlaylist,
//       description: description ?? this.description,
//       scheduledTime: scheduledTime ?? this.scheduledTime,
//       removeLowEnergy: removeLowEnergy ?? this.removeLowEnergy,
//       lastTracks: lastTracks ?? this.lastTracks,
//       bannedArtists: bannedArtists ?? this.bannedArtists,
//       bannedTracks: bannedTracks ?? this.bannedTracks,
//       bannedGenres: bannedGenres ?? this.bannedGenres,
//       exceptionsToBannedGenres:
//           exceptionsToBannedGenres ?? this.exceptionsToBannedGenres,
//       recipe: recipe ?? this.recipe,
//     );
//   }
// }

// // Helper function to parse a list of Jobs from JSON string
// List<Job> parseJobs(String jsonString) {
//   final List<dynamic> jsonList = json.decode(jsonString);
//   return jsonList
//       .map((jobJson) => Job.fromJson(jobJson as Map<String, dynamic>))
//       .toList();
// }
