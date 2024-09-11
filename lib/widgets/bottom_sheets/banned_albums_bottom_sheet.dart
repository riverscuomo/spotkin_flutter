import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart' hide Image;
import 'package:spotkin_flutter/app_core.dart';

class BannedAlbumsBottomSheet extends StatefulWidget {
  final int jobIndex;

  const BannedAlbumsBottomSheet({
    Key? key,
    required this.jobIndex,
  }) : super(key: key);

  @override
  _BannedAlbumsBottomSheetState createState() =>
      _BannedAlbumsBottomSheetState();
}

class _BannedAlbumsBottomSheetState extends State<BannedAlbumsBottomSheet> {
  late List<AlbumSimple> _bannedAlbums;
  Map<String, List<Track>> _tracksByAlbum =
      {}; // Map of album ID to list of tracks
  Map<String, AlbumSimple> _albumDetails =
      {}; // Map to store album details by album ID
  bool _isLoading = true;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _initBannedAlbums();
    _getPlaylistTracks();
  }

  void _initBannedAlbums() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    _bannedAlbums = List.from(job.bannedAlbums);
  }

  void _addAlbumToBanned(AlbumSimple album) {
    if (!_bannedAlbums.contains(album)) {
      setState(() {
        _bannedAlbums.add(album);
        _updateJob();
        _feedbackMessage = '${album.name} added to banned albums';
      });
      print(
          'Album added: ${album.name}. Total banned albums: ${_bannedAlbums.length}');
    }
  }

  void _updateJob() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    final updatedJob = job.copyWith(bannedAlbums: _bannedAlbums);
    jobProvider.updateJob(widget.jobIndex, updatedJob);
    print(
        'Job updated. Banned albums count: ${updatedJob.bannedAlbums.length}');
  }

  Widget _buildAlbumWidget(AlbumSimple? album, List<Track>? tracks) {
    if (album == null || tracks == null) {
      return const SizedBox(); // Safeguard: if the album or tracks are null, return an empty widget
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row with album image, title, and artist name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Square Album Image
                album.images?.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: Image.network(
                          album.images!.first.url!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const SizedBox(
                        width: 60,
                        height: 60,
                        child: Icon(Icons.album, size: 40),
                      ),
                const SizedBox(width: 16),

                // Album title and artist name
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Album title limited to one line with overflow ellipsis
                      Text(
                        album.name ?? 'Unknown Album',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // Add overflow
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // Show "Album - Artist" like Spotify
                        'Album • ${album.artists?.map((artist) => artist.name).join(', ') ?? 'Unknown Artist'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Ban Album button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _addAlbumToBanned(album),
                  child: const Text('Ban'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row with all song titles separated by a separator
            Text(
              tracks.map((track) => track.name ?? 'Unknown Track').join(' • '),
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _getPlaylistTracks() async {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    final spotifyService = getIt<SpotifyService>();
    final targetPlaylistId = job.targetPlaylist.id;

    if (targetPlaylistId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Fetch playlist tracks
      final playlistTracks =
          await spotifyService.getPlaylistTracks(targetPlaylistId);

      // Group tracks by album ID and store album details
      _tracksByAlbum = {};
      _albumDetails = {};

      for (var track in playlistTracks) {
        final album = track.album;
        if (album != null && album.id != null) {
          final albumId = album.id!;

          // Group tracks by their album
          if (_tracksByAlbum.containsKey(albumId)) {
            _tracksByAlbum[albumId]!.add(track);
          } else {
            _tracksByAlbum[albumId] = [track];
            _albumDetails[albumId] = album; // Store album details
          }
        }
      }

      // Sort the albums by artist name in _albumDetails
      final sortedAlbumEntries = _tracksByAlbum.entries.toList()
        ..sort((a, b) {
          final artistA = _albumDetails[a.key]
                  ?.artists
                  ?.map((artist) => artist.name)
                  .join(', ') ??
              '';
          final artistB = _albumDetails[b.key]
                  ?.artists
                  ?.map((artist) => artist.name)
                  .join(', ') ??
              '';
          return artistA.compareTo(artistB);
        });

      // Reassign sorted albums to _tracksByAlbum
      _tracksByAlbum = Map.fromEntries(sortedAlbumEntries);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching playlist tracks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: const Text('Albums in your Spotkin Playlist'),
      content: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_tracksByAlbum.isEmpty)
          const Center(
              child: Text('No albums or tracks found in the playlist.'))
        else
          // Create widgets from sorted _tracksByAlbum
          ..._tracksByAlbum.entries.map((entry) {
            final albumId = entry.key;
            final tracks = entry.value;
            final album = _albumDetails[albumId];
            return _buildAlbumWidget(album, tracks);
          }).toList(),
      ],
    );
  }
}
