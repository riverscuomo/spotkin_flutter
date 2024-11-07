import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart' hide Image;
import 'package:spotkin_flutter/app_core.dart';

abstract class BannedItemsBottomSheet<ItemType> extends StatefulWidget {
  final int jobIndex;

  const BannedItemsBottomSheet({
    Key? key,
    required this.jobIndex,
  }) : super(key: key);
}

abstract class BannedItemsBottomSheetState<
    T extends BannedItemsBottomSheet<ItemType>, ItemType> extends State<T> {
  late List<ItemType> _bannedItems;
  bool _isLoading = true;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _initBannedItems();
    _fetchItems();
  }

  void _initBannedItems();

  void _fetchItems();

  void _addItemToBanned(ItemType item);

  void _updateJob();

  String _getItemName(ItemType item);

  Widget _buildItemWidget(ItemType item);

  String _getTitle();

  List<ItemType> get _items;

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: Text(_getTitle()),
      content: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_items.isEmpty)
          const Center(child: Text('No items found in the playlist.'))
        else
          ..._items.map((item) => _buildItemWidget(item)).toList(),
      ],
    );
  }
}

class BannedAlbumsBottomSheet extends BannedItemsBottomSheet<AlbumSimple> {
  const BannedAlbumsBottomSheet({
    Key? key,
    required int jobIndex,
  }) : super(key: key, jobIndex: jobIndex);

  @override
  _BannedAlbumsBottomSheetState createState() =>
      _BannedAlbumsBottomSheetState();
}

class _BannedAlbumsBottomSheetState
    extends BannedItemsBottomSheetState<BannedAlbumsBottomSheet, AlbumSimple> {
  Map<String, List<Track>> _tracksByAlbum = {};
  Map<String, AlbumSimple> _albumDetails = {};

  @override
  void _initBannedItems() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    _bannedItems = List<AlbumSimple>.from(job.bannedAlbums);
  }

  @override
  void _fetchItems() async {
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
      final playlistTracks =
          await spotifyService.getPlaylistTracks(targetPlaylistId);

      _tracksByAlbum = {};
      _albumDetails = {};

      for (var track in playlistTracks) {
        final album = track.album;
        if (album != null && album.id != null) {
          final albumId = album.id!;

          if (_tracksByAlbum.containsKey(albumId)) {
            _tracksByAlbum[albumId]!.add(track);
          } else {
            _tracksByAlbum[albumId] = [track];
            _albumDetails[albumId] = album;
          }
        }
      }

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
  void _addItemToBanned(AlbumSimple item) {
    if (!_bannedItems.contains(item)) {
      setState(() {
        _bannedItems.add(item);
        _updateJob();
        _feedbackMessage = '${item.name} added to banned albums';

        // Show a feedback message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_feedbackMessage!),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
  }

  @override
  void _updateJob() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    final updatedJob = job.copyWith(bannedAlbums: _bannedItems);
    jobProvider.updateJob(widget.jobIndex, updatedJob);
  }

  @override
  String _getItemName(AlbumSimple item) {
    return item.name ?? 'Unknown Album';
  }

  @override
  Widget _buildItemWidget(AlbumSimple item) {
    final albumId = item.id;
    final tracks = _tracksByAlbum[albumId];
    return _buildAlbumWidget(item, tracks);
  }

  Widget _buildAlbumWidget(AlbumSimple? album, List<Track>? tracks) {
    if (album == null || tracks == null) {
      return const SizedBox();
    }

    // Check if this album is already banned
    bool isAlreadyBanned =
        _bannedItems.any((bannedAlbum) => bannedAlbum.id == album.id);

    Widget albumCard = Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name ?? 'Unknown Album',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Album • ${album.artists?.map((artist) => artist.name).join(', ') ?? 'Unknown Artist'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isAlreadyBanned ? Colors.grey[800] : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (isAlreadyBanned) {
                      // Remove from banned items
                      setState(() {
                        _bannedItems.removeWhere(
                            (bannedAlbum) => bannedAlbum.id == album.id);
                        _updateJob();
                        _feedbackMessage =
                            '${album.name} removed from banned albums';
                      });
                    } else {
                      // Add to banned items
                      _addItemToBanned(album);
                    }
                  },
                  child: Text(isAlreadyBanned ? 'Banned' : 'Ban'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              tracks.map((track) => track.name ?? 'Unknown Track').join(' • '),
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    if (isAlreadyBanned) {
      return Opacity(
        opacity: 0.6,
        child: albumCard,
      );
    }

    return albumCard;
  }

  @override
  String _getTitle() {
    return 'Albums in your Spotkin Playlist';
  }

  @override
  List<AlbumSimple> get _items {
    return _albumDetails.values.toList();
  }
}

class BannedArtistsBottomSheet extends BannedItemsBottomSheet<Artist> {
  const BannedArtistsBottomSheet({
    Key? key,
    required int jobIndex,
  }) : super(key: key, jobIndex: jobIndex);

  @override
  _BannedArtistsBottomSheetState createState() =>
      _BannedArtistsBottomSheetState();
}

class _BannedArtistsBottomSheetState
    extends BannedItemsBottomSheetState<BannedArtistsBottomSheet, Artist> {
  Map<String, List<Track>> _tracksByArtist = {};
  Map<String, Artist> _artistDetails = {};

  @override
  void _initBannedItems() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    _bannedItems = List<Artist>.from(job.bannedArtists);
  }

  @override
  void _fetchItems() async {
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
      final playlistTracks =
          await spotifyService.getPlaylistTracks(targetPlaylistId);

      _tracksByArtist = {};
      _artistDetails = {};
      Set<String> artistIds = {};

      for (var track in playlistTracks) {
        final artists = track.artists;
        if (artists != null) {
          for (var artist in artists) {
            if (artist.id != null) {
              final artistId = artist.id!;

              if (_tracksByArtist.containsKey(artistId)) {
                _tracksByArtist[artistId]!.add(track);
              } else {
                _tracksByArtist[artistId] = [track];
                artistIds.add(artistId);
              }
            }
          }
        }
      }

      // Fetch full artist details for the collected artist IDs
      if (artistIds.isNotEmpty) {
        final fullArtists = await spotifyService.getArtists(artistIds.toList());
        for (var artist in fullArtists) {
          if (artist.id != null) {
            _artistDetails[artist.id!] = artist;
          }
        }
      }

      final sortedArtistEntries = _tracksByArtist.entries.toList()
        ..sort((a, b) {
          final artistNameA = _artistDetails[a.key]?.name ?? '';
          final artistNameB = _artistDetails[b.key]?.name ?? '';
          return artistNameA.compareTo(artistNameB);
        });

      _tracksByArtist = Map.fromEntries(sortedArtistEntries);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching playlist tracks or artist details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void _addItemToBanned(Artist item) {
    if (!_bannedItems.contains(item)) {
      setState(() {
        _bannedItems.add(item);
        _updateJob();
        _feedbackMessage = '${item.name} added to banned artists';

        // Show a feedback message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_feedbackMessage!),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
  }

  @override
  void _updateJob() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    final updatedJob = job.copyWith(bannedArtists: _bannedItems);
    jobProvider.updateJob(widget.jobIndex, updatedJob);
  }

  @override
  String _getItemName(Artist item) {
    return item.name ?? 'Unknown Artist';
  }

  @override
  Widget _buildItemWidget(Artist item) {
    final artistId = item.id;
    final tracks = _tracksByArtist[artistId];
    return _buildArtistWidget(item, tracks);
  }

// In _BannedArtistsBottomSheetState
  Widget _buildArtistWidget(Artist? artist, List<Track>? tracks) {
    if (artist == null || tracks == null) {
      return const SizedBox();
    }

    bool isAlreadyBanned =
        _bannedItems.any((bannedArtist) => bannedArtist.id == artist.id);

    Widget artistCard = Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                artist.images?.isNotEmpty == true
                    ? CircleAvatar(
                        backgroundImage:
                            NetworkImage(artist.images!.first.url!),
                        radius: 30,
                      )
                    : const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.person, size: 40),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Text(
                    artist.name ?? 'Unknown Artist',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isAlreadyBanned ? Colors.grey[800] : Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (isAlreadyBanned) {
                      setState(() {
                        _bannedItems.removeWhere(
                            (bannedArtist) => bannedArtist.id == artist.id);
                        _updateJob();
                        _feedbackMessage =
                            '${artist.name} removed from banned artists';
                      });
                    } else {
                      _addItemToBanned(artist);
                    }
                  },
                  child: Text(isAlreadyBanned ? 'Banned' : 'Ban'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              tracks.map((track) => track.name ?? 'Unknown Track').join(' • '),
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );

    if (isAlreadyBanned) {
      return Opacity(
        opacity: 0.6,
        child: artistCard,
      );
    }

    return artistCard;
  }

  @override
  String _getTitle() {
    return 'Artists in your Spotkin Playlist';
  }

  @override
  List<Artist> get _items {
    return _artistDetails.values.toList();
  }
}

class BannedTracksBottomSheet extends BannedItemsBottomSheet<Track> {
  const BannedTracksBottomSheet({
    Key? key,
    required int jobIndex,
  }) : super(key: key, jobIndex: jobIndex);

  @override
  _BannedTracksBottomSheetState createState() =>
      _BannedTracksBottomSheetState();
}

class _BannedTracksBottomSheetState
    extends BannedItemsBottomSheetState<BannedTracksBottomSheet, Track> {
  List<Track> _playlistTracks = [];

  @override
  void _initBannedItems() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    _bannedItems = List<Track>.from(job.bannedTracks);
  }

  @override
  void _fetchItems() async {
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
      _playlistTracks =
          (await spotifyService.getPlaylistTracks(targetPlaylistId)).toList();

      // Sort tracks by artist name
      _playlistTracks.sort((a, b) {
        final artistA = a.artists?.first.name ?? '';
        final artistB = b.artists?.first.name ?? '';
        return artistA.compareTo(artistB);
      });

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
  void _addItemToBanned(Track item) {
    if (!_bannedItems.contains(item)) {
      setState(() {
        _bannedItems.add(item);
        _updateJob();
        _feedbackMessage = '${item.name} added to banned tracks';

        // Show a feedback message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_feedbackMessage!),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
  }

  @override
  void _updateJob() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    final updatedJob = job.copyWith(bannedTracks: _bannedItems);
    jobProvider.updateJob(widget.jobIndex, updatedJob);
  }

  @override
  String _getItemName(Track item) {
    return item.name ?? 'Unknown Track';
  }

  @override
  Widget _buildItemWidget(Track item) {
    return _buildTrackWidget(item);
  }

  Widget _buildTrackWidget(Track track) {
    bool isAlreadyBanned =
        _bannedItems.any((bannedTrack) => bannedTrack.id == track.id);

    Widget trackCard = ListTile(
      leading: track.album?.images?.isNotEmpty == true
          ? Image.network(
              track.album!.images!.first.url!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            )
          : const Icon(Icons.music_note),
      title: Text(
        track.name ?? 'Unknown Track',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artists?.map((artist) => artist.name).join(', ') ??
            'Unknown Artist',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isAlreadyBanned ? Colors.grey[800] : Colors.red,
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          if (isAlreadyBanned) {
            setState(() {
              _bannedItems
                  .removeWhere((bannedTrack) => bannedTrack.id == track.id);
              _updateJob();
              _feedbackMessage = '${track.name} removed from banned tracks';
            });
          } else {
            _addItemToBanned(track);
          }
        },
        child: Text(isAlreadyBanned ? 'Banned' : 'Ban'),
      ),
    );

    if (isAlreadyBanned) {
      return Opacity(
        opacity: 0.6,
        child: trackCard,
      );
    }

    return trackCard;
  }

  @override
  String _getTitle() {
    return 'Tracks in your Spotkin Playlist';
  }

  @override
  List<Track> get _items {
    return _playlistTracks;
  }
}
