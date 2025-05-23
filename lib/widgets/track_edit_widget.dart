import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class TrackEditWidget extends StatefulWidget {
  final Job job;
  final int jobIndex;

  const TrackEditWidget({
    Key? key,
    required this.jobIndex,
    required this.job,
  }) : super(key: key);

  @override
  _TrackEditWidgetState createState() => _TrackEditWidgetState();
}

class _TrackEditWidgetState extends State<TrackEditWidget> {
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
            widget.job.targetPlaylist == null
                ? 'Target Playlist: None selected'
                : 'Target Playlist: ${widget.job.targetPlaylist.name}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          // Future track editing UI will go here
          const Text('Swipe left to view recipe details'),
          const SizedBox(height: 8),
          _buildSwipeIndicator(),
        ],
      ),
    );
  }
  
  Widget _buildSwipeIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
