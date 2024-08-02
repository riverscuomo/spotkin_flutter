import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class SpotifyStylePlaylistTile extends StatelessWidget {
  final PlaylistSimple playlist;
  final Widget? trailingButton;
  final VoidCallback? onTileTapped;

  const SpotifyStylePlaylistTile({
    Key? key,
    required this.playlist,
    this.trailingButton,
    this.onTileTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final url = playlist.externalUrls!.spotify;
        if (url != null) {
          Utils.myLaunch(url);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: [
            PlaylistImageIcon(playlist: playlist),
            const SizedBox(width: 16),
            // Playlist name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlaylistTitle(context, playlist),
                  playlistSubtitle(playlist, context)
                ],
              ),
            ),

            // Edit button
            trailingButton ?? const SizedBox(),
          ],
        ),
      ),
    );
  }
}
