import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';
import '../screens/edit_description_screen.dart';
import '../screens/setting_management_screen.dart';
import 'settings_row_title.dart';

class SettingsCard extends StatelessWidget {
  final int index;

  const SettingsCard({
    Key? key,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        final job = jobProvider.jobs[index];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: SettingsRowTitle(
                      'Banned Artists', job.bannedArtists.length),
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
                  title:
                      SettingsRowTitle('Banned Songs', job.bannedTracks.length),
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
                  title: SettingsRowTitle(
                      'Banned Genres', job.bannedGenres.length),
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
                      job.exceptionsToBannedGenres.length),
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
                  title: SettingsRowTitle('Last Songs', job.lastTracks.length),
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
                  value: job.banSkits,
                  onChanged: (bool value) {
                    jobProvider.updateJob(index, job.copyWith(banSkits: value));
                  },
                  inactiveThumbColor: Colors.grey[600],
                  inactiveTrackColor: Colors.grey[800],
                ),
                ListTile(
                  title: const Text('Description'),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditDescriptionScreen(
                          jobIndex: index,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Scheduled Update Time'),
                  trailing: DropdownButton<int>(
                    value: Utils.utcToLocal(job.scheduledTime),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        int utcHour = Utils.localToUtc(newValue);
                        print(
                            'Selected local time: $newValue, Converted to UTC: $utcHour');
                        jobProvider.updateJob(
                            index, job.copyWith(scheduledTime: utcHour));
                      }
                    },
                    items: List.generate(24, (index) {
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(
                            '${Utils.formatTime(index)} (UTC: ${Utils.localToUtc(index)})'),
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
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      _buildRangeSlider(
                        context,
                        'Energy',
                        1,
                        100,
                        RangeValues(
                          (job.minEnergy ?? 1).toDouble(),
                          (job.maxEnergy ?? 100).toDouble(),
                        ),
                        (values) => jobProvider.updateJob(
                          index,
                          job.copyWith(
                            minEnergy: values.start.round(),
                            maxEnergy: values.end.round(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRangeSlider(
                        context,
                        'Danceability',
                        1,
                        100,
                        RangeValues(
                          (job.minDanceability ?? 1).toDouble(),
                          (job.maxDanceability ?? 100).toDouble(),
                        ),
                        (values) => jobProvider.updateJob(
                          index,
                          job.copyWith(
                            minDanceability: values.start.round(),
                            maxDanceability: values.end.round(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRangeSlider(
                        context,
                        'Acousticness',
                        1,
                        100,
                        RangeValues(
                          (job.minAcousticness ?? 1).toDouble(),
                          (job.maxAcousticness ?? 100).toDouble(),
                        ),
                        (values) => jobProvider.updateJob(
                          index,
                          job.copyWith(
                            minAcousticness: values.start.round(),
                            maxAcousticness: values.end.round(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRangeSlider(
                        context,
                        'Duration (minutes)',
                        0,
                        10,
                        RangeValues(
                          (job.minDuration ?? 0) / 60000,
                          (job.maxDuration ?? 600000) / 60000,
                        ),
                        (values) => jobProvider.updateJob(
                          index,
                          job.copyWith(
                            minDuration: (values.start * 60000).round(),
                            maxDuration: (values.end * 60000).round(),
                          ),
                        ),
                        valueFormatter: (value) => value.toStringAsFixed(1),
                      ),
                      const SizedBox(height: 16),
                      _buildRangeSlider(
                        context,
                        'Popularity',
                        0,
                        100,
                        RangeValues(
                          job.minPopularity?.toDouble() ?? 0,
                          job.maxPopularity?.toDouble() ?? 100,
                        ),
                        (values) => jobProvider.updateJob(
                          index,
                          job.copyWith(
                            minPopularity: values.start.round(),
                            maxPopularity: values.end.round(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateSettingManagementScreen(
    BuildContext context,
    String title,
    String fieldName,
    String tooltip,
    List<SearchType> searchTypes,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingManagementScreen(
          title: title,
          jobIndex: index,
          fieldName: fieldName,
          tooltip: tooltip,
          searchTypes: searchTypes,
        ),
      ),
    );
  }

  Widget _buildRangeSlider(
    BuildContext context,
    String title,
    double min,
    double max,
    RangeValues values,
    Function(RangeValues) onChanged, {
    String Function(double)? valueFormatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontSize: 16,
              ),
        ),
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
}
