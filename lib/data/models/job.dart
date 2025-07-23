import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/data/models/ingredient.dart';
import 'package:spotify/spotify.dart';
import 'package:uuid/uuid.dart';

// Freeze status information for a job returned by the backend
class FreezeStatus {
  final double daysSinceUpdate;
  final double daysUntilFreeze;
  final int freezeThresholdDays;
  final bool isFrozen;

  const FreezeStatus({
    required this.daysSinceUpdate,
    required this.daysUntilFreeze,
    required this.freezeThresholdDays,
    required this.isFrozen,
  });

  factory FreezeStatus.fromJson(Map<String, dynamic> json) {
    return FreezeStatus(
      daysSinceUpdate: (json['days_since_update'] as num?)?.toDouble() ?? 0.0,
      daysUntilFreeze: (json['days_until_freeze'] as num?)?.toDouble() ?? 0.0,
      freezeThresholdDays: json['freeze_threshold_days'] ?? 21,
      isFrozen: json['is_frozen'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'days_since_update': daysSinceUpdate,
        'days_until_freeze': daysUntilFreeze,
        'freeze_threshold_days': freezeThresholdDays,
        'is_frozen': isFrozen,
      };

  FreezeStatus copyWith({
    double? daysSinceUpdate,
    double? daysUntilFreeze,
    int? freezeThresholdDays,
    bool? isFrozen,
  }) {
    return FreezeStatus(
      daysSinceUpdate: daysSinceUpdate ?? this.daysSinceUpdate,
      daysUntilFreeze: daysUntilFreeze ?? this.daysUntilFreeze,
      freezeThresholdDays: freezeThresholdDays ?? this.freezeThresholdDays,
      isFrozen: isFrozen ?? this.isFrozen,
    );
  }
}


class Job {
  final String id;
  final PlaylistSimple targetPlaylist;
  final String description;
  final bool banSkits;
  final bool banExplicitLyrics;
  final List<Track> lastTracks;
  final List<Artist> bannedArtists;
  final List<AlbumSimple> bannedAlbums;
  final List<Track> bannedTracks;
  final List<String> bannedGenres;
  final List<Artist> exceptionsToBannedGenres;
  final List<Ingredient> recipe;

  // Freeze status provided by backend
  final FreezeStatus freezeStatus;
  final int scheduledTime;



  Job({
    required this.id,
    required this.targetPlaylist,
    this.description = '',
    this.banSkits = false,
    this.banExplicitLyrics = false,
    this.lastTracks = const [],
    this.bannedArtists = const [],
    this.bannedAlbums = const [],
    this.bannedTracks = const [],
    this.bannedGenres = const [],
    this.exceptionsToBannedGenres = const [],
    this.freezeStatus = const FreezeStatus(
        daysSinceUpdate: 0,
        daysUntilFreeze: 21,
        freezeThresholdDays: 21,
        isFrozen: false),
    this.recipe = const [],
    int? scheduledTime,

  }) : scheduledTime = scheduledTime ?? _getLocalMidnightInUTC();

  static int _getLocalMidnightInUTC() {
    final now = DateTime.now();
    final localOffset = now.timeZoneOffset.inHours;
    return (24 - localOffset) % 24;
  }

  bool get isNull => targetPlaylist.id == null;

  factory Job.fromJson(Map<String, dynamic> json) {
    debugPrint('Job.fromJson: ${json['target_playlist']['name']}');
    return Job(
      id: json['id'],
      targetPlaylist: PlaylistSimple.fromJson(
          json['target_playlist'] as Map<String, dynamic>),
      description: json['description'] ?? '',
      scheduledTime: json['scheduled_time'] ?? _getLocalMidnightInUTC(),
      banSkits: json['ban_skits'] == true,
      banExplicitLyrics: json['banExplicitLyrics'] == true, // Default to false unless explicitly set to true
      lastTracks: List<Track>.from(
          json['last_tracks']?.map((x) => Track.fromJson(x)) ?? []),
      bannedArtists: List<Artist>.from(
          json['banned_artists']?.map((x) => Artist.fromJson(x)) ?? []),
      bannedAlbums: List<AlbumSimple>.from(
          json['banned_albums']?.map((x) => AlbumSimple.fromJson(x)) ?? []),
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

      freezeStatus: FreezeStatus.fromJson(json['freeze_status'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'target_playlist': targetPlaylist.toJson(),
      'description': description,
      'scheduled_time': scheduledTime,
      'ban_skits': banSkits,
      'banExplicitLyrics': banExplicitLyrics,
      'last_tracks': lastTracks,
      'banned_artists': bannedArtists,
      'banned_albums': bannedAlbums,
      'banned_tracks': bannedTracks,
      'banned_genres': bannedGenres,
      'exceptions_to_banned_genres': exceptionsToBannedGenres,
      'recipe': recipe.map((r) => r.toJson()).toList(),

      'freeze_status': freezeStatus.toJson(),
    };
  }

  // Empty constructor with a generated ID
  Job.empty()
      : this(
          id: const Uuid().v4(),
          targetPlaylist: PlaylistSimple(),
          freezeStatus: const FreezeStatus(
              daysSinceUpdate: 0,
              daysUntilFreeze: 21,
              freezeThresholdDays: 21,
              isFrozen: false),
        );

  Job copyWith({
    String? id,
    PlaylistSimple? targetPlaylist,
    String? description,
    int? scheduledTime,
    bool? banSkits,
    bool? banExplicitLyrics,
    List<Track>? lastTracks,
    List<Artist>? bannedArtists,
    List<AlbumSimple>? bannedAlbums,
    List<Track>? bannedTracks,
    List<String>? bannedGenres,
    List<Artist>? exceptionsToBannedGenres,
    List<Ingredient>? recipe,

    FreezeStatus? freezeStatus,
  }) {
    return Job(
      id: id ?? this.id,
      targetPlaylist: targetPlaylist ?? this.targetPlaylist,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      banSkits: banSkits ?? this.banSkits,
      banExplicitLyrics: banExplicitLyrics ?? this.banExplicitLyrics,
      lastTracks: lastTracks ?? this.lastTracks,
      bannedArtists: bannedArtists ?? this.bannedArtists,
      bannedAlbums: bannedAlbums ?? this.bannedAlbums,
      bannedTracks: bannedTracks ?? this.bannedTracks,
      bannedGenres: bannedGenres ?? this.bannedGenres,
      exceptionsToBannedGenres:
          exceptionsToBannedGenres ?? this.exceptionsToBannedGenres,
      recipe: recipe ?? this.recipe,

      freezeStatus: freezeStatus ?? this.freezeStatus,
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
