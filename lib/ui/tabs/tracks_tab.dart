import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart' as spotify;
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/services/openai_service.dart';
import 'package:spotkin_flutter/ui/widgets/cards/track_card.dart';
import 'package:spotkin_flutter/ui/widgets/dialogs/ai_info_dialog.dart';

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

class _TracksTabState extends State<TracksTab>
    with AutomaticKeepAliveClientMixin {
  final SpotifyService spotifyService = getIt<SpotifyService>();
  final OpenAIService _openAIService = getIt<OpenAIService>();
  List<spotify.Track> _allTracks = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLoadingAIInfo = false;

  @override
  void initState() {
    super.initState();
    _loadTracks();

    // Listen for job updates to refresh tracks
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.addListener(_onJobsUpdated);
  }

  @override
  void dispose() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.removeListener(_onJobsUpdated);
    super.dispose();
  }

  void _onJobsUpdated() {
    // Check if we need to refresh the tracks list
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    if (jobProvider.jobs.length > widget.jobIndex) {
      final updatedJob = jobProvider.jobs[widget.jobIndex];

      // If this is our job and it's been updated, refresh the tracks
      if (updatedJob.id == widget.job.id && updatedJob != widget.job) {
        debugPrint('TracksTab: Job updated, refreshing tracks...');
        _loadTracks();
      }
    }
  }

  Future<void> _loadTracks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      debugPrint('TracksTab: Starting to fetch tracks from recipe...');
      final tracks = await _fetchTracksFromRecipe();
      debugPrint('TracksTab: Fetched ${tracks.length} tracks successfully');

      setState(() {
        _allTracks = tracks;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('TracksTab: Error loading tracks: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load tracks: ${e.toString()}';
      });
    }
  }

  Future<List<spotify.Track>> _fetchTracksFromRecipe() async {
    // Instead of recipe playlists, we'll load tracks from the target playlist
    if (widget.job.targetPlaylist.id == null) {
      debugPrint(
          'TracksTab: Target playlist ID is null, returning empty track list');
      return [];
    }

    debugPrint(
        'TracksTab: Fetching tracks from target playlist ${widget.job.targetPlaylist.name}');

    try {
      // Add a timeout to prevent hanging if the Spotify API is slow
      final playlistTracks = await spotifyService
          .getPlaylistTracks(widget.job.targetPlaylist.id!)
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('TracksTab: Timeout fetching tracks from target playlist');
          return <spotify.Track>[];
        },
      );

      debugPrint(
          'TracksTab: Retrieved ${playlistTracks.length} tracks from target playlist');
      return playlistTracks.toList();
    } catch (e, stackTrace) {
      debugPrint('TracksTab: Error fetching tracks from target playlist: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  void _handleBanTrack(spotify.Track track) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    // Add to banned tracks if not already banned
    if (!widget.job.bannedTracks
        .any((bannedTrack) => bannedTrack.id == track.id)) {
      final updatedBannedTracks = [...widget.job.bannedTracks, track];
      final updatedJob = widget.job.copyWith(bannedTracks: updatedBannedTracks);
      jobProvider.updateJob(widget.jobIndex, updatedJob);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Banned track: ${track.name}')),
      );
    }
  }

  void _handleBanArtist(spotify.Track track) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    if (track.artists != null && track.artists!.isNotEmpty) {
      final artist = track.artists!.first;

      // Add to banned artists if not already banned
      if (!widget.job.bannedArtists
          .any((bannedArtist) => bannedArtist.id == artist.id)) {
        final updatedBannedArtists = [...widget.job.bannedArtists, artist];
        final updatedJob =
            widget.job.copyWith(bannedArtists: updatedBannedArtists);
        jobProvider.updateJob(widget.jobIndex, updatedJob);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banned artist: ${artist.name}')),
        );
      }
    }
  }

  void _handleBanAlbum(spotify.Track track) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    if (track.album != null) {
      final album = track.album!;

      // Add to banned albums if not already banned
      if (!widget.job.bannedAlbums
          .any((bannedAlbum) => bannedAlbum.id == album.id)) {
        final updatedBannedAlbums = [...widget.job.bannedAlbums, album];
        final updatedJob =
            widget.job.copyWith(bannedAlbums: updatedBannedAlbums);
        jobProvider.updateJob(widget.jobIndex, updatedJob);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banned album: ${album.name}')),
        );
      }
    }
  }

  void _handleBanGenre(spotify.Track track, String genre) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    // Add to banned genres if not already banned
    if (!widget.job.bannedGenres.contains(genre)) {
      final updatedBannedGenres = [...widget.job.bannedGenres, genre];
      final updatedJob = widget.job.copyWith(bannedGenres: updatedBannedGenres);
      jobProvider.updateJob(widget.jobIndex, updatedJob);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Banned genre: $genre')),
      );
    }
  }

  // Show a dialog with the artist's genres for selection
  void _showGenreSelectionDialog(
      BuildContext context, spotify.Track track) async {
    if (track.artists == null ||
        track.artists!.isEmpty ||
        track.artists!.first.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No artist information available for this track')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the artist details including genres
      final artistId = track.artists!.first.id!;
      final artists = await spotifyService.getArtists([artistId]);

      setState(() {
        _isLoading = false;
      });

      if (artists.isEmpty ||
          artists.first.genres == null ||
          artists.first.genres!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No genres found for this artist')),
        );
        return;
      }

      final artist = artists.first;
      final genres = artist.genres!;

      // Filter out already banned genres
      final availableGenres = genres
          .where((genre) => !widget.job.bannedGenres.contains(genre))
          .toList();

      if (availableGenres.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('All genres for this artist are already banned')),
        );
        return;
      }

      // Sort alphabetically
      availableGenres.sort();

      // Show the dialog with artist's genres
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select genre to ban from ${artist.name}'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                children: [
                  if (artist.images?.isNotEmpty == true)
                    CircleAvatar(
                      backgroundImage: NetworkImage(artist.images!.first.url!),
                      radius: 40,
                    ),
                  const SizedBox(height: 16),
                  Text('Artist: ${artist.name}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableGenres.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(availableGenres[index]),
                          onTap: () {
                            Navigator.pop(context);
                            _handleBanGenre(track, availableGenres[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading artist genres: ${e.toString()}')),
      );
    }
  }

  // Method removed since it's been replaced by _showTrackInfoData

  Widget _buildInfoRow(String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  '$label:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(value),
              ),
              if (onTap != null) const Icon(Icons.info_outline, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Shows loading dialog while waiting for AI response
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Getting information...'),
              ],
            ),
          ),
        );
      },
    );
  }

  // Shows AI-generated track info in a dialog
  Future<void> _showTrackAIInfo(
      BuildContext context, spotify.Track track) async {
    if (_isLoadingAIInfo) return;

    // Store the context before starting async work
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigatorContext = Navigator.of(context).context;

    setState(() {
      _isLoadingAIInfo = true;
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
        });
      }
    }
  }

  // Shows AI-generated artist info in a dialog
  Future<void> _showArtistAIInfo(
      BuildContext context, spotify.Artist artist) async {
    if (_isLoadingAIInfo) return;

    setState(() {
      _isLoadingAIInfo = true;
    });

    // _showLoadingDialog(context);

    try {
      final artistInfo = await _openAIService.getArtistInfo(artist);

      // Close loading dialog
      if (mounted) {
        // Navigator.of(context).pop();

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
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get artist information: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAIInfo = false;
        });
      }
    }
  }

  // Shows AI-generated album info in a dialog
  Future<void> _showAlbumAIInfo(
      BuildContext context, spotify.AlbumSimple album) async {
    if (_isLoadingAIInfo) return;

    // Store the context before starting async work
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigatorContext = Navigator.of(context).context;

    setState(() {
      _isLoadingAIInfo = true;
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
        });
      }
    }
  }

  Future<bool> _handleDismiss(DismissDirection direction, BuildContext context,
      spotify.Track track) async {
    if (direction == DismissDirection.endToStart) {
      // Negative options (ban)
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.block),
                  title: const Text('Ban Song'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleBanTrack(track);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_off),
                  title: const Text('Ban Artist'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleBanArtist(track);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.album_outlined),
                  title: const Text('Ban Album'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleBanAlbum(track);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Ban Genre'),
                  onTap: () {
                    Navigator.pop(context);
                    _showGenreSelectionDialog(context, track);
                  },
                ),
              ],
            ),
          );
        },
      );
    } else if (direction == DismissDirection.startToEnd) {
      // Show track info and options in a single modal sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Track Info Section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Album Image
                            if (track.album?.images?.isNotEmpty == true)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  track.album!.images!.first.url!,
                                  height: 150,
                                  width: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 150,
                                      width: 150,
                                      color: Colors.grey,
                                      child: const Icon(Icons.music_note,
                                          size: 64, color: Colors.white),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 16),
                            // Track Details - now each row is tappable
                            _buildInfoRow('Name', track.name ?? 'Unknown',
                                onTap: () {
                              // Navigator.pop(context); // Close the bottom sheet
                              _showTrackAIInfo(context, track);
                            }),
                            if (track.artists != null &&
                                track.artists!.isNotEmpty)
                              _buildInfoRow(
                                'Artist',
                                track.artists!
                                    .map((a) => a.name ?? 'Unknown Artist')
                                    .join(', '),
                                onTap: () {
                                  // Navigator.pop(context); // Close the bottom sheet
                                  if (track.artists != null &&
                                      track.artists!.isNotEmpty) {
                                    _showArtistAIInfo(
                                        context, track.artists!.first);
                                  }
                                },
                              ),
                            if (track.album != null)
                              _buildInfoRow(
                                'Album',
                                track.album!.name ?? 'Unknown',
                                onTap: () {
                                  // Navigator.pop(context); // Close the bottom sheet
                                  if (track.album != null) {
                                    _showAlbumAIInfo(context, track.album!);
                                  }
                                },
                              ),
                            _buildInfoRow('Duration',
                                _formatDuration(track.durationMs ?? 0)),
                            if (track.popularity != null)
                              _buildInfoRow(
                                  'Popularity', '${track.popularity}/100'),
                          ],
                        ),
                      ),
                      // Add some spacing at the bottom
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
    return false; // Don't actually remove the item
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTracks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_allTracks.isEmpty) {
      return const Center(
        child: Text(
          'No tracks found. Add playlists to your recipe first.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    } else {
      // Use the simplest ListView implementation for maximum compatibility
      return ListView.builder(
        // No custom physics or other parameters that might cause issues
        itemCount: _allTracks.length,
        itemBuilder: (context, index) {
          final track = _allTracks[index];
          return TrackCard(
            track: track,
            onDismiss: _handleDismiss,
          );
        },
      );
    }
  }
}
