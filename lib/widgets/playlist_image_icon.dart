import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class PlaylistImageIcon extends StatelessWidget {
  const PlaylistImageIcon({super.key, required this.playlist, this.size = 56});

  final PlaylistSimple playlist;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Utils.getPlaylistImageOrIcon(playlist),
    );
  }
}
