class Ingredient {
  final String sourcePlaylistName;
  final String sourcePlaylistId;
  final int quantity;

  Ingredient({
    required this.sourcePlaylistName,
    required this.sourcePlaylistId,
    required this.quantity,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      sourcePlaylistName: json['source_playlist_name'] ?? '',
      sourcePlaylistId: json['source_playlist_id'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_playlist_name': sourcePlaylistName,
      'source_playlist_id': sourcePlaylistId,
      'quantity': quantity,
    };
  }

  Ingredient copyWith({
    String? sourcePlaylistName,
    String? sourcePlaylistId,
    int? quantity,
  }) {
    return Ingredient(
      sourcePlaylistName: sourcePlaylistName ?? this.sourcePlaylistName,
      sourcePlaylistId: sourcePlaylistId ?? this.sourcePlaylistId,
      quantity: quantity ?? this.quantity,
    );
  }
}
