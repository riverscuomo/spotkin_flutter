import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class PlaylistNameField extends StatelessWidget {
  const PlaylistNameField({
    Key? key,
    required this.playlistController,
    this.playlistName,
    this.quantityController,
  }) : super(key: key);

  final TextEditingController playlistController;
  final String? playlistName;
  final TextEditingController? quantityController;

  @override
  Widget build(BuildContext context) {
    return playlistName != null
        ? Text(playlistName!, style: TextStyle(fontWeight: FontWeight.bold))
        : TextFormField(
            controller: playlistController,
            decoration: const InputDecoration(
              labelText: 'Source playlist link',
              hintText: 'Enter Spotify playlist link or ID',
            ),
            validator: Utils.validateSpotifyPlaylistInput,
          );
  }
}

Widget playlistSubtitle(PlaylistSimple playlist, BuildContext context) {
  return playlist.owner != null
      ? Text(
          'Playlist • ${playlist.owner!.displayName}',
          style: Theme.of(context).textTheme.labelMedium,
        )
      : const SizedBox();
}

Text PlaylistTitle(BuildContext context, PlaylistSimple playlist) {
  return Text(
    playlist.name ?? 'Unknown Playlist',
    style: Theme.of(context).textTheme.titleMedium,
    overflow: TextOverflow.ellipsis,
  );
}
