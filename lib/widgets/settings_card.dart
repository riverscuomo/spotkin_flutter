import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

import 'quantity_circle.dart';

class SettingsCard extends StatelessWidget {
  final int index;
  final Job job;
  final Function(int, Job) updateJob;

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
    final bannedArtists = job.bannedArtists;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: SettingsRowTitle('Banned Artists', bannedArtists.length),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToListScreen(
                context,
                'Banned Artists',
                'bannedArtists',
                'These artists will never appear in your Spotify playlist',
                [SearchType.artist],
              ),
            ),
            ListTile(
              title: SettingsRowTitle('Banned Songs', job.bannedTracks.length),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToListScreen(
                context,
                'Banned Songs',
                'bannedTracks',
                'These songs will never appear in your Spotify playlist',
                [SearchType.track],
              ),
            ),
            ListTile(
              title: SettingsRowTitle('Banned Genres', job.bannedGenres.length),
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
              title: SettingsRowTitle('Exceptions to Banned Genres',
                  job.exceptionsToBannedGenres.length),
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
              title: SettingsRowTitle('Last Songs', job.lastTracks.length),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateToListScreen(
                context,
                'Last Songs',
                'lastTracks',
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

class SettingsRowTitle extends StatelessWidget {
  const SettingsRowTitle(
    this.title,
    this.quantity,
  );

  final String title;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title),
        const SizedBox(width: 8),
        QuantityCircle(quantity: quantity),
      ],
    );
  }
}
