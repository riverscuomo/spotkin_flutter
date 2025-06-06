import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart' as spotify;
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/ui/widgets/cards/track_card.dart';

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
  List<spotify.Track> _allTracks = [];
  bool _isLoading = true;
  String? _errorMessage;

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

  // Handler for Source Track functionality
  void _handleSourceTrack(spotify.Track track) async {
    try {
      if (track.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Track ID is missing')),
        );
        return;
      }
      
      final backendService = getIt<BackendService>();
      final jobId = widget.job.id;
      final trackName = track.name ?? 'Unknown Track';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adding source based on track: $trackName')),
      );
      
      final updatedJob = await backendService.addSourceToJob(
        jobId, 'track', track.id!, trackName,
      );
      
      // Update the job in the provider
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      jobProvider.updateJob(widget.jobIndex, updatedJob);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added source based on track: $trackName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add source: $e')),
      );
    }
  }
  
  // Handler for Source Artist functionality
  void _handleSourceArtist(spotify.Track track) async {
    try {
      if (track.artists == null || track.artists!.isEmpty || track.artists!.first.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artist information is missing')),
        );
        return;
      }
      
      final artist = track.artists!.first;
      final backendService = getIt<BackendService>();
      final jobId = widget.job.id;
      final artistName = artist.name ?? 'Unknown Artist';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adding source based on artist: $artistName')),
      );
      
      final updatedJob = await backendService.addSourceToJob(
        jobId, 'artist', artist.id!, artistName,
      );
      
      // Update the job in the provider
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      jobProvider.updateJob(widget.jobIndex, updatedJob);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added source based on artist: $artistName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add source: $e')),
      );
    }
  }
  
  // Handler for Source Album functionality
  void _handleSourceAlbum(spotify.Track track) async {
    try {
      if (track.album == null || track.album!.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Album information is missing')),
        );
        return;
      }
      
      final album = track.album!;
      final backendService = getIt<BackendService>();
      final jobId = widget.job.id;
      final albumName = album.name ?? 'Unknown Album';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adding source based on album: $albumName')),
      );
      
      final updatedJob = await backendService.addSourceToJob(
        jobId, 'album', album.id!, albumName,
      );
      
      // Update the job in the provider
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      jobProvider.updateJob(widget.jobIndex, updatedJob);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added source based on album: $albumName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add source: $e')),
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

  Future<bool> _handleDismiss(DismissDirection direction, BuildContext context,
      spotify.Track track) async {
    // Now handling both directions the same way (both show tune menu)
    // Show menu options regardless of swipe direction
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Small padding before first option
                const SizedBox(height: 8),
                
                // Positive options
                ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.green),
                  title: const Text('Source Track'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleSourceTrack(track);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person, color: Colors.green),
                  title: const Text('Source Artist'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleSourceArtist(track);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.album, color: Colors.green),
                  title: const Text('Source Album'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleSourceAlbum(track);
                  },
                ),
                
                // Simple divider between source and ban options
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(),
                ),
                
                // Negative options (existing ban options)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Ban Song'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleBanTrack(track);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_off, color: Colors.red),
                  title: const Text('Ban Artist'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleBanArtist(track);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.album_outlined, color: Colors.red),
                  title: const Text('Ban Album'),
                  onTap: () {
                    Navigator.pop(context);
                    _handleBanAlbum(track);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: Colors.red),
                  title: const Text('Ban Genre'),
                  onTap: () {
                    Navigator.pop(context);
                    _showGenreSelectionDialog(context, track);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
        itemCount: _allTracks.length,
        itemBuilder: (context, index) {
          final track = _allTracks[index];
          return TrackCard(
            key: ValueKey(track.id ?? 'unknown-${index}'),
            track: track,
            onDismiss: _handleDismiss,
          );
        },
      );
    }
  }
}
