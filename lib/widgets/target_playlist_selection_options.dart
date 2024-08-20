import 'dart:js';

import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class TargetPlaylistSelectionOptions extends StatelessWidget {
  final Function(PlaylistSimple) onPlaylistSelected;
  final PlaylistSimple playlist;
  final Function() deleteJob;

  const TargetPlaylistSelectionOptions({
    super.key,
    required this.onPlaylistSelected,
    required this.playlist,
    required this.deleteJob,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 24,
        ),
        Text(
          'Select which playlist you want to use for Spotkin',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: ElevatedButton(
              onPressed: () => _createNewPlaylist(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
              child: const Text('Create a New Playlist'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'or',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: ElevatedButton(
              onPressed: () => _showPlaylistSearchBottomSheet(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
              child: const Text('Select Existing Playlist'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'or',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: ElevatedButton(
              onPressed: () => deleteJob(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete this Spotkin'),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _createNewPlaylist(BuildContext context) async {
    final spotifyService = getIt<SpotifyService>();
    try {
      final newPlaylist = await spotifyService.createPlaylist(
        'Spotkin',
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
