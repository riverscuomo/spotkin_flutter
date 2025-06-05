import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' as spotify;
import 'package:audioplayers/audioplayers.dart';
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/services/openai_service.dart';
import 'package:spotkin_flutter/ui/widgets/dialogs/ai_info_dialog.dart';

class TrackCard extends StatefulWidget {
  final spotify.Track track;
  final Future<bool> Function(DismissDirection, BuildContext, spotify.Track)
      onDismiss;

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
  final OpenAIService _openAIService = getIt<OpenAIService>();
  bool _isPlaying = false;
  bool _hasPreview = false;
  bool _isLoadingAIInfo = false;
  String? _loadingAIType; // 'track', 'artist', or 'album'

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
    final artistName = widget.track.artists?.isNotEmpty == true &&
            widget.track.artists!.first.name != null
        ? widget.track.artists!.first.name!
        : 'Unknown Artist';

    return Dismissible(
      key: Key(widget.track.id ??
          'unknown-${widget.track.name ?? 'unknown'}-$artistName'),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.tune, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.green,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.tune, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        try {
          return await widget.onDismiss(direction, context, widget.track);
        } catch (e) {
          debugPrint('Error in dismiss handler: $e');
          return false;
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: InkWell(
          onTap: _togglePlayPause, // Restored play toggle functionality
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
                      InkWell(
                        onTap: () => _showTrackAIInfo(context, widget.track),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _isLoadingAIInfo && _loadingAIType == 'track'
                                ? _buildLoadingIndicator()
                                : Text(
                                  widget.track.name ?? 'Unknown Track',
                                  style: Theme.of(context).textTheme.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (widget.track.artists != null && widget.track.artists!.isNotEmpty) {
                            _showArtistAIInfo(context, widget.track.artists!.first);
                          }
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: _isLoadingAIInfo && _loadingAIType == 'artist'
                                ? _buildLoadingIndicator(height: 16)
                                : Text(
                                  artistName,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.track.album != null)
                        InkWell(
                          onTap: () => _showAlbumAIInfo(context, widget.track.album!),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _isLoadingAIInfo && _loadingAIType == 'album'
                                  ? _buildLoadingIndicator(height: 14)
                                  : Text(
                                    widget.track.album!.name ?? 'Unknown Album',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // No duration or play button
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build a loading indicator with appropriate size
  Widget _buildLoadingIndicator({double height = 20}) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            height: height,
            width: height,
            child: CircularProgressIndicator(
              strokeWidth: height / 8,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading...',
            style: TextStyle(fontSize: height * 0.75),
          ),
        ],
      ),
    );
  }

  // Shows AI-generated track info in a dialog
  Future<void> _showTrackAIInfo(BuildContext context, spotify.Track track) async {
    if (_isLoadingAIInfo) return;

    // Store the context before starting async work
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigatorContext = Navigator.of(context).context;

    setState(() {
      _isLoadingAIInfo = true;
      _loadingAIType = 'track';
    });

    try {
      final trackInfo = await _openAIService.getTrackInfo(track);

      // Show info dialog using the stored context
      if (mounted) {
        // Use navigatorContext to show dialog after awaiting
        showDialog(
          context: navigatorContext,
          builder: (BuildContext dialogContext) {
            return AIInfoDialog(
              title: 'About "${track.name}"',
              content: trackInfo,
              imageUrl: track.album?.images?.isNotEmpty == true
                  ? track.album!.images!.first.url
                  : null,
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error showing track AI info: $e');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to get track information: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAIInfo = false;
          _loadingAIType = null;
        });
      }
    }
  }

  // Shows AI-generated artist info in a dialog
  Future<void> _showArtistAIInfo(BuildContext context, spotify.Artist artist) async {
    if (_isLoadingAIInfo) return;

    setState(() {
      _isLoadingAIInfo = true;
      _loadingAIType = 'artist';
    });

    try {
      final artistInfo = await _openAIService.getArtistInfo(artist);

      if (mounted) {
        // Show info dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AIInfoDialog(
              title: 'About ${artist.name}',
              content: artistInfo,
              imageUrl: artist.images?.isNotEmpty == true
                  ? artist.images!.first.url
                  : null,
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error showing artist AI info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get artist information: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAIInfo = false;
          _loadingAIType = null;
        });
      }
    }
  }

  // Shows AI-generated album info in a dialog
  Future<void> _showAlbumAIInfo(BuildContext context, spotify.AlbumSimple album) async {
    if (_isLoadingAIInfo) return;

    // Store the context before starting async work
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigatorContext = Navigator.of(context).context;

    setState(() {
      _isLoadingAIInfo = true;
      _loadingAIType = 'album';
    });

    try {
      final albumInfo = await _openAIService.getAlbumInfo(album);

      if (mounted) {
        // Show info dialog using the stored context
        showDialog(
          context: navigatorContext,
          builder: (BuildContext dialogContext) {
            return AIInfoDialog(
              title: 'About "${album.name}"',
              content: albumInfo,
              imageUrl: album.images?.isNotEmpty == true
                  ? album.images!.first.url
                  : null,
            );
          },
        );
      }
    } catch (e) {
      debugPrint('Error showing album AI info: $e');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to get album information: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAIInfo = false;
          _loadingAIType = null;
        });
      }
    }
  }
}
