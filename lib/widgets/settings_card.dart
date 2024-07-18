import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class SettingsCard extends StatelessWidget {
  final int index;
  final Job job;
  final Function updateJob;
  const SettingsCard({
    super.key,
    required this.index,
    required this.job,
    required this.updateJob,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: job.description,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) =>
                  updateJob(index, job.copyWith(description: value)),
            ),
            SwitchListTile(
              title: const Text('Remove Low Energy'),
              value: job.removeLowEnergy,
              onChanged: (bool value) =>
                  updateJob(index, job.copyWith(removeLowEnergy: value)),
            ),
            TextFormField(
              initialValue: job.lastTrackIds.join(', '),
              decoration: const InputDecoration(labelText: 'Last Track IDs'),
              onChanged: (value) => updateJob(
                  index,
                  job.copyWith(
                      lastTrackIds:
                          value.split(',').map((e) => e.trim()).toList())),
            ),
            TextFormField(
              initialValue: job.bannedArtistNames.join(', '),
              decoration:
                  const InputDecoration(labelText: 'Banned Artist Names'),
              onChanged: (value) => updateJob(
                  index,
                  job.copyWith(
                      bannedArtistNames:
                          value.split(',').map((e) => e.trim()).toList())),
            ),
            TextFormField(
              initialValue: job.bannedSongTitles.join(', '),
              decoration:
                  const InputDecoration(labelText: 'Banned Song Titles'),
              onChanged: (value) => updateJob(
                  index,
                  job.copyWith(
                      bannedSongTitles:
                          value.split(',').map((e) => e.trim()).toList())),
            ),
            TextFormField(
              initialValue: job.bannedTrackIds.join(', '),
              decoration: const InputDecoration(labelText: 'Banned Track IDs'),
              onChanged: (value) => updateJob(
                  index,
                  job.copyWith(
                      bannedTrackIds:
                          value.split(',').map((e) => e.trim()).toList())),
            ),
            TextFormField(
              initialValue: job.bannedGenres.join(', '),
              decoration: const InputDecoration(labelText: 'Banned Genres'),
              onChanged: (value) => updateJob(
                  index,
                  job.copyWith(
                      bannedGenres:
                          value.split(',').map((e) => e.trim()).toList())),
            ),
            TextFormField(
              initialValue: job.exceptionsToBannedGenres.join(', '),
              decoration: const InputDecoration(
                  labelText: 'Exceptions to Banned Genres'),
              onChanged: (value) => updateJob(
                  index,
                  job.copyWith(
                      exceptionsToBannedGenres:
                          value.split(',').map((e) => e.trim()).toList())),
            ),
          ],
        ),
      ),
    );
  }
}
