import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class PlaylistSelectionOptions extends StatelessWidget {
  final Function(PlaylistSimple) onPlaylistSelected;

  const PlaylistSelectionOptions({
    Key? key,
    required this.onPlaylistSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () => _createNewPlaylist(context),
          child: Text('Create a New Playlist'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _showPlaylistSearchBottomSheet(context),
          child: Text('Select Existing Playlist'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  void _createNewPlaylist(BuildContext context) async {
    final spotifyService = getIt<SpotifyService>();
    try {
      final newPlaylist = await spotifyService.createPlaylist(
        'New Playlist', // You might want to prompt the user for a name
        'Created by Spotkin',
        public: false,
      );
      onPlaylistSelected(newPlaylist);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create playlist: $e')),
      );
    }
  }

  void _showPlaylistSearchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SearchBottomSheet(
          onItemSelected: (dynamic item) {
            if (item is PlaylistSimple) {
              onPlaylistSelected(item);
            }
          },
          userPlaylistsOnly: true,
        );
      },
    );
  }
}
