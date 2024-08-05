import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class BannedGenresBottomSheet extends StatefulWidget {
  final Job job;
  final int jobIndex;
  final Function(int, Job) updateJob;

  const BannedGenresBottomSheet({
    Key? key,
    required this.job,
    required this.jobIndex,
    required this.updateJob,
  }) : super(key: key);

  @override
  _BannedGenresBottomSheetState createState() =>
      _BannedGenresBottomSheetState();
}

class _BannedGenresBottomSheetState extends State<BannedGenresBottomSheet> {
  List<String> _bannedGenres = [];
  List<Artist> _artistsInTargetPlaylist = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bannedGenres = widget.job.bannedGenres;
    _getPlaylistArtists();
  }

  void _getPlaylistArtists() async {
    final spotifyService = getIt<SpotifyService>();
    final targetPlaylistId = widget.job.targetPlaylist?.id;

    if (targetPlaylistId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final playlistTracks =
          await spotifyService.getPlaylistTracks(targetPlaylistId);
      final artistIds = playlistTracks
          .map((track) => track.artists?.first.id)
          .where((id) => id != null)
          .cast<String>()
          .toSet()
          .toList();

      _artistsInTargetPlaylist = await spotifyService.getArtists(artistIds);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching playlist artists: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addGenreToBanned(String genre) {
    if (!_bannedGenres.contains(genre)) {
      setState(() {
        _bannedGenres.add(genre);
        _updateJob();
      });
    }
  }

  void _updateJob() {
    final updatedJob = widget.job.copyWith(bannedGenres: _bannedGenres);
    widget.updateJob(widget.jobIndex, updatedJob);
  }

  Widget _buildArtistWidget(Artist artist) {
    final genres = artist.genres ?? [];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: artist.images?.isNotEmpty == true
                ? CircleAvatar(
                    backgroundImage: NetworkImage(artist.images!.first.url!))
                : const CircleAvatar(child: Icon(Icons.person)),
            title: Text(artist.name ?? 'Unknown Artist'),
            subtitle: Text('Popularity: ${artist.popularity ?? 'N/A'}'),
          ),
          if (genres.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: genres
                    .take(3)
                    .map((genre) => ElevatedButton.icon(
                          icon: const Icon(Icons.close, size: 18),
                          label: Text(genre),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _addGenreToBanned(genre),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9, // 90% of screen height
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Banned Genres'),
          automaticallyImplyLeading: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _artistsInTargetPlaylist.isEmpty
                ? const Center(
                    child: Text(
                        'Run Spotkin to generate a list of bannable genres.'))
                : ListView.builder(
                    itemCount: _artistsInTargetPlaylist.length,
                    itemBuilder: (context, index) =>
                        _buildArtistWidget(_artistsInTargetPlaylist[index]),
                  ),
      ),
    );
  }
}
