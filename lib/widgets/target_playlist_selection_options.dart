import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class TargetPlaylistSelectionOptions extends StatelessWidget {
  final Function(PlaylistSimple) onPlaylistSelected;
  final Job job;
  final Function() deleteJob;
  final StorageService storageService = StorageService();
  late final BackupService backupService;

  TargetPlaylistSelectionOptions({
    Key? key,
    required this.onPlaylistSelected,
    required this.job,
    required this.deleteJob,
  }) : super(key: key);

  void _createBackup(BuildContext context) {
    String message = backupService.createBackup(job);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _importBackup(BuildContext context) async {
    final result = await backupService.importBackup();

    if (result['maxJobsReached'] == true) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Maximum Jobs Reached'),
            content: Text(result['message']),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }

    if (result['success']) {
      // Refresh the job list
      Provider.of<JobProvider>(context, listen: false).loadJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    // Initialize backupService here to have access to the context
    backupService = BackupService(
      storageService,
      jobProvider.addJob,
      (_, updatedJob) => jobProvider.updateJob(
          jobProvider.jobs.indexWhere(
              (j) => j.targetPlaylist.id == updatedJob.targetPlaylist.id),
          updatedJob),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
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
        const SizedBox(height: 16),
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
            const Text('Import a Spotkin'),
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
            const Text('Export this Spotkin'),
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
