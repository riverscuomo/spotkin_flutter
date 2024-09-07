import 'package:spotify/spotify.dart';

class Ingredient {
  final PlaylistSimple playlist;
  final int quantity;

  Ingredient({
    required this.playlist,
    required this.quantity,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      playlist: PlaylistSimple.fromJson(json['playlist']),
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playlist': playlist.toJson(),
      'quantity': quantity,
    };
  }

  Map<String, dynamic> toJsonForPost() {
    return {
      'playlist_name': playlist.name,
      'playlist_id': playlist.id,
      'quantity': quantity,
    };
  }

  Ingredient copyWith({
    PlaylistSimple? playlist,
    int? quantity,
  }) {
    return Ingredient(
      playlist: playlist ?? this.playlist,
      quantity: quantity ?? this.quantity,
    );
  }
}
