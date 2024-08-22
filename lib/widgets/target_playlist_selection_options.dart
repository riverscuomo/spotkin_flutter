import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class TargetPlaylistSelectionOptions extends StatelessWidget {
  final Function(PlaylistSimple) onPlaylistSelected;
  final PlaylistSimple playlist;
  final Function() deleteJob;
  final StorageService storageService = StorageService();
  late final BackupService backupService;

  TargetPlaylistSelectionOptions({
    super.key,
    required this.onPlaylistSelected,
    required this.playlist,
    required this.deleteJob,
  });

  void _createBackup(BuildContext context) {
    String message = backupService.createBackup();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _importBackup(BuildContext context) async {
    String message = await backupService.importBackup();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Provider.of<JobProvider>(context, listen: false).loadJobs();
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    // Initialize backupService here to have access to the context
    backupService = BackupService(
      storageService,
      jobProvider.addJob,
      jobProvider.updateJob,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 24,
        ),
        const Divider(),
        Text(
          'Select which playlist to update with this Spotkin',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text('Select One of Your Playlists'),
            ),
            ElevatedButton(
              onPressed: () => _showPlaylistSearchBottomSheet(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(50, 50),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.playlist_play),
            ),
          ],
        ),

        const SizedBox(
            height: 16), // Add some vertical spacing between the rows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text('Create a New Playlist'),
            ),
            ElevatedButton(
              onPressed: () => _createNewPlaylist(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(50, 50),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        Text(
          'Backup and Restore',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Import Backup'),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _importBackup(context),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Icon(Icons.restore),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Create Backup'),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _createBackup(context),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Icon(Icons.backup),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text('Delete this Spotkin'),
            const Spacer(),
            ElevatedButton(
              onPressed: () => deleteJob(),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: Colors.red,
              ),
              child: const Icon(Icons.delete),
            ),
          ],
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
