import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';

class IngredientFormRow {
  // final TextEditingController playlistController;
  final TextEditingController quantityController;
  PlaylistSimple? playlist;

  IngredientFormRow({
    // required this.playlistController,
    required this.quantityController,
    this.playlist,
  });
}
