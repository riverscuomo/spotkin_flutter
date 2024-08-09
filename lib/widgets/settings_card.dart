import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';
import '../screens/edit_description_screen.dart';
import 'settings_row_title.dart';

class SettingsCard extends StatefulWidget {
  final int index;
  final Job job;
  final Function(int, Job) updateJob;

  const SettingsCard({
    Key? key,
    required this.index,
    required this.job,
    required this.updateJob,
  }) : super(key: key);

  @override
  State<SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  late Job _job;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  @override
  void didUpdateWidget(SettingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.job != oldWidget.job) {
      setState(() {
        _job = widget.job;
      });
    }
  }

  void updateJob(Job updatedJob) {
    setState(() {
      _job = updatedJob;
    });
    widget.updateJob(widget.index, updatedJob);
  }

  void _navigateSettingManagementScreen(BuildContext context, String title,
      String fieldName, String tooltip, List<SearchType> searchTypes) {
    Navigator.push<Job>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingManagementScreen(
          title: title,
          job: _job,
          jobIndex: widget.index,
          fieldName: fieldName,
          tooltip: tooltip,
          updateJob: (index, updatedJob) {
            widget.updateJob(index, updatedJob);
            setState(() {
              _job = updatedJob;
            });
          },
          searchTypes: searchTypes,
        ),
      ),
    ).then((updatedJob) {
      if (updatedJob != null) {
        setState(() {
          _job = updatedJob;
        });
        widget.updateJob(widget.index, updatedJob);
      }
    });
  }

  void _navigateToEditDescriptionScreen(BuildContext context, Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDescriptionScreen(
          job: job,
          jobIndex: widget.index,
          updateJob: widget.updateJob,
        ),
      ),
    );
  }

  Widget _buildRangeSlider({
    required String title,
    required double min,
    required double max,
    required RangeValues values,
    required Function(RangeValues) onChanged,
    String Function(double)? valueFormatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        RangeSlider(
          min: min,
          max: max,
          values: values,
          onChanged: onChanged,
          divisions: 100,
          labels: RangeLabels(
            valueFormatter?.call(values.start) ??
                values.start.toStringAsFixed(2),
            valueFormatter?.call(values.end) ?? values.end.toStringAsFixed(2),
          ),
          activeColor: Colors.green,
          inactiveColor: Colors.grey[800],
        ),
      ],
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
              title:
                  SettingsRowTitle('Banned Artists', _job.bannedArtists.length),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateSettingManagementScreen(
                context,
                'Banned Artists',
                'bannedArtists',
                'These artists will never appear in your Spotify playlist',
                [SearchType.artist],
              ),
            ),
            ListTile(
              title: SettingsRowTitle('Banned Songs', _job.bannedTracks.length),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateSettingManagementScreen(
                context,
                'Banned Songs',
                'bannedTracks',
                'These songs will never appear in your Spotify playlist',
                [SearchType.track],
              ),
            ),
            ListTile(
              title:
                  SettingsRowTitle('Banned Genres', _job.bannedGenres.length),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateSettingManagementScreen(
                context,
                'Banned Genres',
                'bannedGenres',
                'These genres will never appear in your Spotify playlist',
                [SearchType.artist],
              ),
            ),
            ListTile(
              title: SettingsRowTitle('Exceptions to Banned Genres',
                  _job.exceptionsToBannedGenres.length),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateSettingManagementScreen(
                context,
                'Exceptions to Banned Genres',
                'exceptionsToBannedGenres',
                'These artists will be admitted to your Spotify playlist even if their genre is banned',
                [SearchType.artist],
              ),
            ),
            ListTile(
              title: SettingsRowTitle('Last Songs', _job.lastTracks.length),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _navigateSettingManagementScreen(
                context,
                'Last Songs',
                'lastTracks',
                'These tracks will always appear last in your Spotify playlist',
                [SearchType.track],
              ),
            ),
            SwitchListTile(
              title: Text('Ban Skits',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white)),
              value: _job.banSkits,
              onChanged: (bool value) {
                updateJob(_job.copyWith(banSkits: value));
              },
              inactiveThumbColor: Colors.grey[600],
              inactiveTrackColor: Colors.grey[800],
            ),
            ListTile(
              title: const Text('Description'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                _navigateToEditDescriptionScreen(context, _job);
              },
            ),
            ListTile(
              title: const Text('Scheduled Update Time'),
              trailing: DropdownButton<int>(
                value: Utils.utcToLocal(_job.scheduledTime),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    int utcHour = Utils.localToUtc(newValue);
                    updateJob(_job.copyWith(scheduledTime: utcHour));
                  }
                },
                items: List.generate(24, (index) {
                  return DropdownMenuItem<int>(
                    value: index,
                    child: Text(Utils.formatTime(Utils.localToUtc(index))),
                  );
                }),
              ),
            ),
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  Text('Audio Features',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildRangeSlider(
                    title: 'Energy',
                    min: 1,
                    max: 100,
                    values: RangeValues(
                      (_job.minEnergy ?? 1).toDouble(),
                      (_job.maxEnergy ?? 100).toDouble(),
                    ),
                    onChanged: (RangeValues values) {
                      updateJob(_job.copyWith(
                        minEnergy: values.start.round(),
                        maxEnergy: values.end.round(),
                      ));
                    },
                    valueFormatter: (value) => value.round().toString(),
                  ),
                  const SizedBox(height: 16),
                  _buildRangeSlider(
                    title: 'Danceability',
                    min: 1,
                    max: 100,
                    values: RangeValues(
                      (_job.minDanceability ?? 1).toDouble(),
                      (_job.maxDanceability ?? 100).toDouble(),
                    ),
                    onChanged: (RangeValues values) {
                      updateJob(_job.copyWith(
                        minDanceability: values.start.round(),
                        maxDanceability: values.end.round(),
                      ));
                    },
                    valueFormatter: (value) => value.round().toString(),
                  ),
                  const SizedBox(height: 16),
                  _buildRangeSlider(
                    title: 'Acousticness',
                    min: 1,
                    max: 100,
                    values: RangeValues(
                      (_job.minAcousticness ?? 1).toDouble(),
                      (_job.maxAcousticness ?? 100).toDouble(),
                    ),
                    onChanged: (RangeValues values) {
                      updateJob(_job.copyWith(
                        minAcousticness: values.start.round(),
                        maxAcousticness: values.end.round(),
                      ));
                    },
                    valueFormatter: (value) => value.round().toString(),
                  ),
                  const SizedBox(height: 16),
                  _buildRangeSlider(
                    title: 'Duration (minutes)',
                    min: 0,
                    max: 10,
                    values: RangeValues(
                      (_job.minDuration ?? 0) / 60000,
                      (_job.maxDuration ?? 600000) / 60000,
                    ),
                    onChanged: (RangeValues values) {
                      updateJob(_job.copyWith(
                        minDuration: (values.start * 60000).round(),
                        maxDuration: (values.end * 60000).round(),
                      ));
                    },
                    valueFormatter: (value) => value.toStringAsFixed(1),
                  ),
                  const SizedBox(height: 16),
                  _buildRangeSlider(
                    title: 'Popularity',
                    min: 0,
                    max: 100,
                    values: RangeValues(_job.minPopularity?.toDouble() ?? 0,
                        _job.maxPopularity?.toDouble() ?? 100),
                    onChanged: (RangeValues values) {
                      updateJob(_job.copyWith(
                        minPopularity: values.start.round(),
                        maxPopularity: values.end.round(),
                      ));
                    },
                    valueFormatter: (value) => value.round().toString(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
