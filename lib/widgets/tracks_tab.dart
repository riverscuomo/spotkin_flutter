import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class TracksTab extends StatefulWidget {
  final Job job;
  final int jobIndex;

  const TracksTab({
    Key? key,
    required this.jobIndex,
    required this.job,
  }) : super(key: key);

  @override
  _TracksTabState createState() => _TracksTabState();
}

class _TracksTabState extends State<TracksTab> {
  final SpotifyService spotifyService = getIt<SpotifyService>();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track Editor',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Target Playlist: ${widget.job.targetPlaylist.name}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          // Future track editing UI will go here
          const Text('Track editing interface coming soon'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
