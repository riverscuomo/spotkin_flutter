import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';
import '../screens/edit_description_screen.dart';
import '../screens/setting_management_screen.dart';
import 'settings_row_title.dart';

class SettingsCard extends StatefulWidget {
  final int index;

  const SettingsCard({
    Key? key,
    required this.index,
  }) : super(key: key);

  @override
  _SettingsCardState createState() => _SettingsCardState();
}

class _SettingsCardState extends State<SettingsCard> {
  Timer? _debounce;
  late RangeValues _energyValues;
  late RangeValues _danceabilityValues;
  late RangeValues _acousticnessValues;
  late RangeValues _durationValues;
  late RangeValues _popularityValues;

  @override
  void initState() {
    super.initState();
    final job =
        Provider.of<JobProvider>(context, listen: false).jobs[widget.index];
    _energyValues = RangeValues(
      (job.minEnergy ?? 0).toDouble(),
      (job.maxEnergy ?? 100).toDouble(),
    );
    _danceabilityValues = RangeValues(
      (job.minDanceability ?? 0).toDouble(),
      (job.maxDanceability ?? 100).toDouble(),
    );
    _acousticnessValues = RangeValues(
      (job.minAcousticness ?? 0).toDouble(),
      (job.maxAcousticness ?? 100).toDouble(),
    );
    _durationValues = RangeValues(
      (job.minDuration ?? 0) / 60000,
      (job.maxDuration ?? 600000) / 60000,
    );
    _popularityValues = RangeValues(
      (job.minPopularity?.toDouble() ?? 0),
      (job.maxPopularity?.toDouble() ?? 100),
    );
  }

  void _onSliderChangeDebounced(
      Function(RangeValues) updateJobCallback, RangeValues values) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      updateJobCallback(values);
    });
  }

  String _formatDuration(double value) {
    int minutes = value.floor();
    int seconds = ((value - minutes) * 60).round();
    return '${minutes}m ${seconds}s';
  }

  Widget _buildRangeSlider(
    BuildContext context,
    String title,
    double min,
    double max,
    RangeValues values,
    Function(RangeValues) onChanged, {
    String Function(double)? valueFormatter,
    required Function(RangeValues) updateState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontSize: 16,
                    ),
            ), 
            if (title == 'Acousticness') // add button for acousticness info
              const AcousticnessInfoButton(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              valueFormatter?.call(values.start) ??
                  values.start.toStringAsFixed(0),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              valueFormatter?.call(values.end) ?? values.end.toStringAsFixed(0),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          min: min,
          max: max,
          values: values,
          onChanged: (newValues) {
            setState(() {
              updateState(newValues);
            });
            _onSliderChangeDebounced(onChanged, newValues);
          },
          divisions: 100,
          labels: RangeLabels(
            valueFormatter?.call(values.start) ??
                values.start.toStringAsFixed(0),
            valueFormatter?.call(values.end) ?? values.end.toStringAsFixed(0),
          ),
          activeColor: Colors.green,
          inactiveColor: Colors.grey[800],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
          jobIndex: widget.index,
          fieldName: fieldName,
          tooltip: tooltip,
          searchTypes: searchTypes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        final job = jobProvider.jobs[widget.index];

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
                  title: SettingsRowTitle(
                      'Banned Albums', job.bannedAlbums.length),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _navigateSettingManagementScreen(
                    context,
                    'Banned Albums',
                    'bannedAlbums',
                    'These albums will never appear in your Spotify playlist',
                    [SearchType.album],
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
                    jobProvider.updateJob(
                        widget.index, job.copyWith(banSkits: value));
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
                          jobIndex: widget.index,
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
                        jobProvider.updateJob(
                            widget.index, job.copyWith(scheduledTime: utcHour));
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
                const SizedBox(height: 10),
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text('Audio Features',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      _buildRangeSlider(
                        context,
                        'Energy',
                        0,
                        100,
                        _energyValues,
                        (values) => jobProvider.updateJob(
                          widget.index,
                          job.copyWith(
                            minEnergy: values.start.round(),
                            maxEnergy: values.end.round(),
                          ),
                        ),
                        updateState: (newValues) {
                          _energyValues = newValues;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildRangeSlider(
                        context,
                        'Danceability',
                        0,
                        100,
                        _danceabilityValues,
                        (values) => jobProvider.updateJob(
                          widget.index,
                          job.copyWith(
                            minDanceability: values.start.round(),
                            maxDanceability: values.end.round(),
                          ),
                        ),
                        updateState: (newValues) {
                          _danceabilityValues = newValues;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildRangeSlider(
                        context,
                        'Acousticness',
                        0,
                        100,
                        _acousticnessValues,
                        (values) => jobProvider.updateJob(
                          widget.index,
                          job.copyWith(
                            minAcousticness: values.start.round(),
                            maxAcousticness: values.end.round(),
                          ),
                        ),
                        updateState: (newValues) {
                          _acousticnessValues = newValues;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildRangeSlider(
                        context,
                        'Duration',
                        0,
                        10,
                        _durationValues,
                        (values) => jobProvider.updateJob(
                          widget.index,
                          job.copyWith(
                            minDuration: (values.start * 60000).round(),
                            maxDuration: (values.end * 60000).round(),
                          ),
                        ),
                        valueFormatter:
                            _formatDuration, // Format using minutes and seconds
                        updateState: (newValues) {
                          _durationValues = newValues;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildRangeSlider(
                        context,
                        'Popularity',
                        0,
                        100,
                        _popularityValues,
                        (values) => jobProvider.updateJob(
                          widget.index,
                          job.copyWith(
                            minPopularity: values.start.round(),
                            maxPopularity: values.end.round(),
                          ),
                        ),
                        updateState: (newValues) {
                          _popularityValues = newValues;
                        },
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
}
