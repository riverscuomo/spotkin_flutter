import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';

class IngredientRow {
  final TextEditingController quantityController;
  PlaylistSimple? playlist;

  IngredientRow({
    required this.quantityController,
    this.playlist,
  });
}
