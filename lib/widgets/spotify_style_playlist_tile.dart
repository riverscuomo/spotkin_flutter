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
          Utils.launchUrl(url);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            PlaylistImageIcon(playlist: playlist),
            const SizedBox(width: 16),
            // Playlist name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name ?? 'Unknown Playlist',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  playlist.owner != null
                      ? Text(
                          'Playlist • ${playlist.owner!.displayName}',
                          style: Theme.of(context).textTheme.labelSmall,
                        )
                      : Container(),
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

class PlaylistImageIcon extends StatelessWidget {
  const PlaylistImageIcon({
    super.key,
    required this.playlist,
  });

  final PlaylistSimple playlist;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Utils.getPlaylistImageOrIcon(playlist),
    );
  }
}
