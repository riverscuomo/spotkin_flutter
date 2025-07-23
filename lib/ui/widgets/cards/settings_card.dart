import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';
import '../../screens/edit_description_screen.dart';
import '../../screens/setting_management_screen.dart';
import '../settings_row_title.dart';

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


  @override
  void initState() {
    super.initState();
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
                  child: Container(),  // Empty container since we removed the audio features
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
