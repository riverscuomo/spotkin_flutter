import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' hide Image;
import 'package:spotkin_flutter/app_core.dart';

class SpotifyStylePlaylistTile extends StatelessWidget {
  final PlaylistSimple playlist;
  final Widget? trailingButton;
  final VoidCallback? onTileTapped;
  final bool active;

  const SpotifyStylePlaylistTile({
    super.key,
    required this.playlist,
    this.trailingButton,
    this.onTileTapped,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    var style = Theme.of(context).textTheme.titleSmall;
    if (!active) style = style!.copyWith(color: Colors.grey[600]);
    return InkWell(
      onTap: () {
        final url = playlist.externalUrls!.spotify;
        if (url != null) {
          Utils.myLaunch(url);
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
                  playlistTitle(
                    context,
                    playlist,
                    style: style,
                  ),
                  playlistSubtitle(playlist, context),
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
  final PlaylistSimple playlist;
  final double size;

  const PlaylistImageIcon({
    Key? key,
    required this.playlist,
    this.size = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? imageUrl;
    if (size > 100) {
      imageUrl = playlist.images?.isNotEmpty == true
          ? playlist.images?.first.url
          : null;
    } else {
      imageUrl = playlist.images?.isNotEmpty == true
          ? playlist.images?.last.url
          : null;
    }

    return InkWell(
      onTap: () {
        if (playlist.externalUrls?.spotify != null) {
          Utils.myLaunch(playlist.externalUrls!.spotify ?? '');
        }
      },
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl != null
              ? Image.network(
                  imageUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Log the error without breaking
                    debugPrint('Error loading image: $imageUrl');
                    debugPrint('Error details: $error');
                    return _buildPlaceholder();
                  },
                  // frameBuilder:
                  //     (context, child, frame, wasSynchronouslyLoaded) {
                  //   if (frame == null) {
                  //     return _buildLoadingIndicator();
                  //   }
                  //   return child;
                  // },
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[300],
      child: Icon(
        Icons.music_note,
        size: size * 0.5,
        color: Colors.grey[600],
      ),
    );
  }
}

// class PlaylistImageIcon extends StatelessWidget {
//   const PlaylistImageIcon({super.key, required this.playlist, this.size = 56});

//   final PlaylistSimple playlist;
//   final double? size;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         color: Colors.grey[800],
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Utils.getPlaylistImageOrIcon(playlist),
//     );
//   }
// }
