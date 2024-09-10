import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';

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
