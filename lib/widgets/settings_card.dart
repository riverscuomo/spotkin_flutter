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
              title: const Text('Remove Low Energy'),
              subtitle: Text(
                'Tracks with low energy will be removed from your Spotify playlist',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              value: _job.removeLowEnergy,
              inactiveTrackColor: Colors.grey,
              onChanged: (value) => updateJob(
                _job.copyWith(removeLowEnergy: value),
              ),
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
          ],
        ),
      ),
    );
  }
}
