import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class SettingsCard extends StatelessWidget {
  final int index;
  final Job job;
  final Function(int, Job) updateJob; // Specify the function type here

  const SettingsCard({
    Key? key,
    required this.index,
    required this.job,
    required this.updateJob,
  }) : super(key: key);
  void _navigateToListScreen(BuildContext context, String title,
      String fieldName, String tooltip, List<SearchType> searchTypes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListManagementScreen(
          title: title,
          job: job,
          jobIndex: index,
          fieldName: fieldName,
          tooltip: tooltip,
          updateJob: updateJob,
          searchTypes: searchTypes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Banned Artists'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToListScreen(
                context,
                'Banned Artists',
                'bannedArtistNames',
                'These artists will never appear in your Spotify playlist',
                [SearchType.artist],
              ),
            ),
            ListTile(
              title: const Text('Banned Songs'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToListScreen(
                context,
                'Banned Songs',
                'bannedSongTitles',
                'These songs will never appear in your Spotify playlist',
                [SearchType.track],
              ),
            ),
            ListTile(
              title: const Text('Banned Genres'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToListScreen(
                context,
                'Banned Genres',
                'bannedGenres',
                'These genres will never appear in your Spotify playlist',
                [SearchType.artist],
              ),
            ),
            ListTile(
              title: const Text('Exceptions to Banned Genres'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToListScreen(
                context,
                'Exceptions to Banned Genres',
                'exceptionsToBannedGenres',
                'These artists will be admitted to your Spotify playlist even if their genre is banned',
                [SearchType.artist],
              ),
            ),
            ListTile(
              title: const Text('Last Track IDs'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToListScreen(
                context,
                'Last Track IDs',
                'lastTrackIds',
                'These tracks will appear last in your Spotify playlist',
                [SearchType.track],
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
              trailing: const Icon(Icons.edit),
              onTap: () {
                // Navigate to a screen for editing the description
                // You can implement this similarly to the list management screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
