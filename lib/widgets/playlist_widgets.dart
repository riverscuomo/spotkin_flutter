import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

// class TargetPlaylistName extends StatelessWidget {
//   const TargetPlaylistName({
//     Key? key,
//     required this.playlistController,
//     this.playlistName,
//     this.quantityController,
//   }) : super(key: key);

//   final TextEditingController playlistController;
//   final String? playlistName;
//   final TextEditingController? quantityController;

//   @override
//   Widget build(BuildContext context) {
//     return playlistName != null
//         ? Text(
//             playlistName!,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           )
//         : TextFormField(
//             controller: playlistController,
//             decoration: const InputDecoration(
//               labelText: 'Source playlist link',
//               hintText: 'Enter Spotify playlist link or ID',
//             ),
//             validator: Utils.validateSpotifyPlaylistInput,
//           );
//   }
// }

Widget playlistSubtitle(PlaylistSimple playlist, BuildContext context) {
  return playlist.owner != null
      ? Text(
          '${playlist.owner?.displayName ?? playlist.owner?.id} • ${playlist.tracksLink?.total ?? 0} tracks',
          style: Theme.of(context).textTheme.labelMedium,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        )
      : const SizedBox();
}

Text playlistTitle(BuildContext context, PlaylistSimple playlist,
    {TextStyle? style}) {
  return Text(
    playlist.name ?? 'Unknown Playlist',
    style: style,
    overflow: TextOverflow.ellipsis,
    maxLines: 1,
  );
}
