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
    backupService.createBackup();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Backup file created. Check your downloads.')),
    );
  }

  Future<void> _importBackup(BuildContext context) async {
    await backupService.importBackup();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup imported and jobs updated.')),
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
        // const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        // const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: ElevatedButton(
              onPressed: () => _showPlaylistSearchBottomSheet(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
              child: const Text('Select One of Your Playlists'),
            ),
          ),
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
                minimumSize: const Size(50, 50),
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
