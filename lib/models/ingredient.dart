import 'package:spotify/spotify.dart';

class Ingredient {
  // final String sourcePlaylistName;
  // final String sourcePlaylistId;
  final PlaylistSimple playlist;
  final int quantity;

  Ingredient({
    // required this.playlistName,
    // required this.playlistId,
    required this.playlist,
    required this.quantity,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      // playlistName: json['source_playlist_name'] ?? '',
      // playlistId: json['source_playlist_id'] ?? '',
      playlist: PlaylistSimple.fromJson(json['playlist']),
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // 'source_playlist_name': playlistName,
      // 'source_playlist_id': playlistId,
      'playlist': playlist.toJson(),
      'quantity': quantity,
    };
  }

  Map<String, dynamic> toJsonForPost() {
    return {
      'source_playlist_name': playlist.name,
      'source_playlist_id': playlist.id,
      'quantity': quantity,
    };
  }

  Ingredient copyWith({
    // String? playlistName,
    // String? playlistId,
    PlaylistSimple? playlist,
    int? quantity,
  }) {
    return Ingredient(
      // playlistName: playlistName ?? this.playlistName,
      // playlistId: playlistId ?? this.playlistId,
      playlist: playlist ?? this.playlist,
      quantity: quantity ?? this.quantity,
    );
  }
}
