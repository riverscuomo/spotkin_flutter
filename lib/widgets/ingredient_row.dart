import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';

class IngredientRow {
  // final TextEditingController playlistController;
  final TextEditingController quantityController;
  PlaylistSimple? playlist;

  IngredientRow({
    // required this.playlistController,
    required this.quantityController,
    this.playlist,
  });
}
