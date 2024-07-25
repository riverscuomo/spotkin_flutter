import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class JobForm extends StatelessWidget {
  final Job job;
  final int index;
  final Function(int, Job) updateJob;

  const JobForm({
    Key? key,
    required this.job,
    required this.index,
    required this.updateJob,
  }) : super(key: key);

  void _navigateToListScreen(
      BuildContext context, String title, List<String> items, String tooltip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListManagementScreen(
          title: title,
          items: items,
          tooltip: tooltip,
          onListUpdated: (updatedList) {
            Job updatedJob;
            switch (title) {
              case 'Banned Artists':
                updatedJob = job.copyWith(bannedArtistNames: updatedList);
                break;
              case 'Banned Songs':
                updatedJob = job.copyWith(bannedSongTitles: updatedList);
                break;
              case 'Banned Genres':
                updatedJob = job.copyWith(bannedGenres: updatedList);
                break;
              case 'Exceptions to Banned Genres':
                updatedJob =
                    job.copyWith(exceptionsToBannedGenres: updatedList);
                break;
              case 'Last Track IDs':
                updatedJob = job.copyWith(lastTrackIds: updatedList);
                break;
              default:
                return;
            }
            updateJob(index, updatedJob);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Banned Artists'),
          subtitle: Text(job.bannedArtistNames.join(', ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToListScreen(
            context,
            'Banned Artists',
            job.bannedArtistNames,
            'These artists will never appear in your Spotify playlist',
          ),
        ),
        ListTile(
          title: const Text('Banned Songs'),
          subtitle: Text(job.bannedSongTitles.join(', ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToListScreen(
            context,
            'Banned Songs',
            job.bannedSongTitles,
            'These songs will never appear in your Spotify playlist',
          ),
        ),
        ListTile(
          title: const Text('Banned Genres'),
          subtitle: Text(job.bannedGenres.join(', ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToListScreen(
            context,
            'Banned Genres',
            job.bannedGenres,
            'These genres will never appear in your Spotify playlist',
          ),
        ),
        ListTile(
          title: const Text('Exceptions to Banned Genres'),
          subtitle: Text(job.exceptionsToBannedGenres.join(', ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToListScreen(
            context,
            'Exceptions to Banned Genres',
            job.exceptionsToBannedGenres,
            'These artists will be admitted to your Spotify playlist even if their genre is banned',
          ),
        ),
        SwitchListTile(
          title: const Text('Remove Low Energy'),
          subtitle: const Text(
              'Tracks with low energy will be removed from your Spotify playlist'),
          value: job.removeLowEnergy,
          onChanged: (value) =>
              updateJob(index, job.copyWith(removeLowEnergy: value)),
        ),
        ListTile(
          title: const Text('Description'),
          subtitle: Text(job.description),
          trailing: const Icon(Icons.edit),
          onTap: () {
            // Navigate to a screen for editing the description
          },
        ),
        ListTile(
          title: const Text('Last Track IDs'),
          subtitle: Text(job.lastTrackIds.join(', ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToListScreen(
            context,
            'Last Track IDs',
            job.lastTrackIds,
            'These tracks will appear last in your Spotify playlist',
          ),
        ),
      ],
    );
  }
}
