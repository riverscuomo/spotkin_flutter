import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' as spotify;
import 'package:audioplayers/audioplayers.dart';


class TrackCard extends StatefulWidget {
  final spotify.Track track;
  final Future<bool> Function(DismissDirection, BuildContext, spotify.Track) onDismiss;

  const TrackCard({
    Key? key, 
    required this.track,
    required this.onDismiss,
  }) : super(key: key);
  
  @override
  State<TrackCard> createState() => _TrackCardState();
}

class _TrackCardState extends State<TrackCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _hasPreview = false;
  
  @override
  void initState() {
    super.initState();
    _hasPreview = widget.track.previewUrl != null && widget.track.previewUrl!.isNotEmpty;
    
    // Listen for player state changes
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  
  Future<void> _togglePlayPause() async {
    if (!_hasPreview) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No preview available for this track')),
      );
      return;
    }
    
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(widget.track.previewUrl!));
      }
      
      setState(() {
        _isPlaying = !_isPlaying;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing preview: ${e.toString()}')),
      );
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? albumImageUrl;
    if (widget.track.album?.images?.isNotEmpty == true &&
        widget.track.album!.images!.first.url != null) {
      albumImageUrl = widget.track.album!.images!.first.url!;
    }
    final artistName =
        widget.track.artists?.isNotEmpty == true && widget.track.artists!.first.name != null
            ? widget.track.artists!.first.name!
            : 'Unknown Artist';

    return Dismissible(
      key: Key(widget.track.id ?? 'unknown-${widget.track.name ?? 'unknown'}-$artistName'),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.info_outline, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.block, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        try {
          return await widget.onDismiss(direction, context, widget.track);
        } catch (e) {
          print('Error in dismiss handler: $e');
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: InkWell(
          onTap: _togglePlayPause,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
            children: [
              // Album artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: albumImageUrl != null
                    ? Image.network(
                        albumImageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey,
                            child: const Icon(Icons.music_note,
                                color: Colors.white),
                          );
                        },
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey,
                        child:
                            const Icon(Icons.music_note, color: Colors.white),
                      ),
              ),
              const SizedBox(width: 12),
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.track.name ?? 'Unknown Track',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      artistName,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.track.album != null)
                      Text(
                        widget.track.album!.name ?? 'Unknown Album',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Play/Pause icon and Duration
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasPreview)
                    Icon(
                      _isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      color: _isPlaying ? Theme.of(context).primaryColor : Colors.grey.shade600,
                      size: 24,
                    ),
                  if (widget.track.durationMs != null)
                    Text(
                      _formatDuration(widget.track.durationMs!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    if (milliseconds <= 0) return '0:00';
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
