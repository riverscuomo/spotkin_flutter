import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart' as spotify;
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
  List<spotify.Track> _allTracks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final tracks = await _fetchTracksFromRecipe();
      
      setState(() {
        _allTracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load tracks: ${e.toString()}';
      });
    }
  }

  Future<List<spotify.Track>> _fetchTracksFromRecipe() async {
    if (widget.job.recipe.isEmpty) {
      return [];
    }

    final allTracks = <spotify.Track>[];
    
    // Fetch tracks from each playlist in the recipe
    for (final ingredient in widget.job.recipe) {
      if (ingredient.playlist.id != null) {
        try {
          final playlistTracks = await spotifyService.getPlaylistTracks(ingredient.playlist.id!);
          // The quantity in the recipe determines how many tracks we take from each playlist
          final tracksToAdd = playlistTracks.take(ingredient.quantity).toList();
          allTracks.addAll(tracksToAdd);
        } catch (e) {
          print('Error fetching tracks from playlist ${ingredient.playlist.name}: $e');
        }
      }
    }

    return allTracks;
  }

  void _handleBanTrack(spotify.Track track) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    
    // Add to banned tracks if not already banned
    if (!widget.job.bannedTracks.any((bannedTrack) => bannedTrack.id == track.id)) {
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
      if (!widget.job.bannedArtists.any((bannedArtist) => bannedArtist.id == artist.id)) {
        final updatedBannedArtists = [...widget.job.bannedArtists, artist];
        final updatedJob = widget.job.copyWith(bannedArtists: updatedBannedArtists);
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
      if (!widget.job.bannedAlbums.any((bannedAlbum) => bannedAlbum.id == album.id)) {
        final updatedBannedAlbums = [...widget.job.bannedAlbums, album];
        final updatedJob = widget.job.copyWith(bannedAlbums: updatedBannedAlbums);
        jobProvider.updateJob(widget.jobIndex, updatedJob);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banned album: ${album.name}')),
        );
      }
    }
  }

  void _showTrackInfo(spotify.Track track) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  Text(
                    'Track Information',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Name', track.name ?? 'Unknown'),
                  if (track.artists != null && track.artists!.isNotEmpty)
                    _buildInfoRow('Artist', track.artists!.map((a) => a.name ?? 'Unknown Artist').join(', ')),
                  if (track.album != null)
                    _buildInfoRow('Album', track.album!.name ?? 'Unknown'),
                  _buildInfoRow('Duration', _formatDuration(track.durationMs ?? 0)),
                  if (track.popularity != null)
                    _buildInfoRow('Popularity', '${track.popularity}/100'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
        ],
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<bool> _handleDismiss(
      DismissDirection direction, spotify.Track track) async {
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
                  title: const Text('Ban Track'),
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
              ],
            ),
          );
        },
      );
    } else if (direction == DismissDirection.startToEnd) {
      // Positive options (info)
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.music_note),
                  title: const Text('Track Info'),
                  onTap: () {
                    Navigator.pop(context);
                    _showTrackInfo(track);
                  },
                ),
                if (track.artists != null && track.artists!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Artist Info'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement artist info view
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Artist info coming soon')),
                      );
                    },
                  ),
                if (track.album != null)
                  ListTile(
                    leading: const Icon(Icons.album),
                    title: const Text('Album Info'),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement album info view
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Album info coming soon')),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      );
    }
    return false; // Don't actually remove the item
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tracks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Swipe left to ban, swipe right for info',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        if (_isLoading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          Expanded(
            child: Center(
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
            ),
          )
        else if (_allTracks.isEmpty)
          const Expanded(
            child: Center(
              child: Text(
                'No tracks found. Add playlists to your recipe first.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _allTracks.length,
              itemBuilder: (context, index) {
                final track = _allTracks[index];
                return _buildTrackCard(track);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTrackCard(spotify.Track track) {
    String? albumImageUrl;
    if (track.album?.images?.isNotEmpty == true && track.album!.images!.first.url != null) {
      albumImageUrl = track.album!.images!.first.url!;
    }
    final artistName = track.artists?.isNotEmpty == true && track.artists!.first.name != null
        ? track.artists!.first.name!
        : 'Unknown Artist';

    return Dismissible(
      key: Key(track.id ?? 'unknown-${track.name}-$artistName'),
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
      confirmDismiss: (direction) => _handleDismiss(direction, track),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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
                            child: const Icon(Icons.music_note, color: Colors.white),
                          );
                        },
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey,
                        child: const Icon(Icons.music_note, color: Colors.white),
                      ),
              ),
              const SizedBox(width: 12),
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.name ?? 'Unknown Track',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      artistName,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (track.album != null)
                      Text(
                        track.album!.name ?? 'Unknown Album',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Duration
              Text(
                _formatDuration(track.durationMs ?? 0),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
