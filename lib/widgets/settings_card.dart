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
            Tooltip(
              message: 'This description will appear in your Spotify playlist',
              child: TextFormField(
                initialValue: job.description,
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) =>
                    updateJob(index, job.copyWith(description: value)),
              ),
            ),
            
            Tooltip(
              message: 'These tracks will appear last in your Spotify playlist',
              child: TextFormField(
                initialValue: job.lastTrackIds.join(', '),
                decoration: const InputDecoration(labelText: 'Last Track IDs'),
                onChanged: (value) => updateJob(
                    index,
                    job.copyWith(
                        lastTrackIds:
                            value.split(',').map((e) => e.trim()).toList())),
              ),
            ),
            Tooltip(
              message: 'These artists will never appear in your Spotify playlist',
              child: TextFormField(
                initialValue: job.bannedArtistNames.join(', '),
                decoration:
                    const InputDecoration(labelText: 'Banned Artist Names'),
                onChanged: (value) => updateJob(
                    index,
                    job.copyWith(
                        bannedArtistNames:
                            value.split(',').map((e) => e.trim()).toList())),
              ),
            ),
            Tooltip(
              message: 'These songs will never appear in your Spotify playlist',
              child: TextFormField(
                initialValue: job.bannedSongTitles.join(', '),
                decoration:
                    const InputDecoration(labelText: 'Banned Song Titles'),
                onChanged: (value) => updateJob(
                    index,
                    job.copyWith(
                        bannedSongTitles:
                            value.split(',').map((e) => e.trim()).toList())),
              ),
            ),
            Tooltip(
              message: 'These tracks will never appear in your Spotify playlist',
              child: TextFormField(
                initialValue: job.bannedTrackIds.join(', '),
                decoration: const InputDecoration(labelText: 'Banned Track IDs'),
                onChanged: (value) => updateJob(
                    index,
                    job.copyWith(
                        bannedTrackIds:
                            value.split(',').map((e) => e.trim()).toList())),
              ),
            ),
            Tooltip(
              message: 'These genres will never appear in your Spotify playlist',
              child: TextFormField(
                initialValue: job.bannedGenres.join(', '),
                decoration: const InputDecoration(labelText: 'Banned Genres'),
                onChanged: (value) => updateJob(
                    index,
                    job.copyWith(
                        bannedGenres:
                            value.split(',').map((e) => e.trim()).toList())),
              ),
            ),
            Tooltip(
              message: 'These artists will be admitted to your Spotify playlist even if their genre is banned',
              child: TextFormField(
                initialValue: job.exceptionsToBannedGenres.join(', '),
                decoration: const InputDecoration(
                    labelText: 'Exceptions to Banned Genres'),
                onChanged: (value) => updateJob(
                    index,
                    job.copyWith(
                        exceptionsToBannedGenres:
                            value.split(',').map((e) => e.trim()).toList())),
              ),
            ),
            Tooltip(
              message: 'Tracks with low energy will be removed from your Spotify playlist (useful for workouts, parties, etc.)',
              child: SwitchListTile(
                title: const Text('Remove Low Energy'),
                value: job.removeLowEnergy,
                onChanged: (bool value) =>
                    updateJob(index, job.copyWith(removeLowEnergy: value)),
              ),
            ),
          ],
        ),

      ),
    );
  }
}


class TrackIdsInput extends StatefulWidget {
  final Job job;
  final int index;
  final Function(int, Job) updateJob;

  TrackIdsInput({required this.job, required this.index, required this.updateJob});

  @override
  _TrackIdsInputState createState() => _TrackIdsInputState();
}

class _TrackIdsInputState extends State<TrackIdsInput> {
  late TextEditingController _controller;
  List<String> _currentIds = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.job.lastTrackIds.join(', '));
    _currentIds = widget.job.lastTrackIds;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateIds(String value) {
    setState(() {
      _currentIds = value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      widget.updateJob(
        widget.index,
        widget.job.copyWith(lastTrackIds: _currentIds),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Last Track IDs',
            hintText: 'Enter track IDs separated by commas',
          ),
          onChanged: _updateIds,
        ),
        SizedBox(height: 8),
        Text('Current IDs: ${_currentIds.join(", ")}'),
      ],
    );
  }
}