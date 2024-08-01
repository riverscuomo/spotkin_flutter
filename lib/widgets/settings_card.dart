import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';
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
  late StorageService _storageService;
  late Job _job;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  void updateJob(Job updatedJob) {
    setState(() {
      _job = updatedJob;
    });
    widget.updateJob(widget.index, updatedJob);
  }

  void _navigateToListScreen(BuildContext context, String title,
      String fieldName, String tooltip, List<SearchType> searchTypes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListManagementScreen(
          title: title,
          job: _job,
          jobIndex: widget.index,
          fieldName: fieldName,
          tooltip: tooltip,
          updateJob: widget.updateJob, // Pass the function from the widget
          searchTypes: searchTypes,
        ),
      ),
    );
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
    final job = _job;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title:
                  SettingsRowTitle('Banned Artists', job.bannedArtists.length),
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
              value: job.removeLowEnergy,
              inactiveTrackColor: Colors.grey,
              onChanged: (value) => updateJob(
                _job.copyWith(removeLowEnergy: value),
              ),
            ),
            ListTile(
              title: const Text('Description'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                _navigateToEditDescriptionScreen(context, job);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EditDescriptionScreen extends StatefulWidget {
  final Job job;
  final int jobIndex;
  final Function(int, Job) updateJob;

  const EditDescriptionScreen({
    Key? key,
    required this.job,
    required this.jobIndex,
    required this.updateJob,
  }) : super(key: key);

  @override
  State<EditDescriptionScreen> createState() => _EditDescriptionScreenState();
}

class _EditDescriptionScreenState extends State<EditDescriptionScreen> {
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.job.description);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveDescription() {
    final updatedJob =
        widget.job.copyWith(description: _descriptionController.text);
    widget.updateJob(widget.jobIndex, updatedJob);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Description'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveDescription,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
      ),
    );
  }
}
