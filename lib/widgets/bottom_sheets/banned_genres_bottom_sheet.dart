import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

class BannedGenresBottomSheet extends StatefulWidget {
  final Job job;
  final int jobIndex;
  final Function(Job) updateJob;

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
  late List<String> _bannedGenres;
  List<Artist> _artistsInTargetPlaylist = [];
  bool _isLoading = true;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    _bannedGenres = List.from(widget.job.bannedGenres);
    _getPlaylistArtists();
  }

  void _addGenreToBanned(String genre) {
    if (!_bannedGenres.contains(genre)) {
      setState(() {
        _bannedGenres.add(genre);
        _updateJob();
        _feedbackMessage = '$genre added to banned genres';
      });
    }
  }

  void _updateJob() {
    final updatedJob = widget.job.copyWith(bannedGenres: _bannedGenres);
    widget.updateJob(updatedJob);
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

  Widget _buildArtistWidget(Artist artist) {
    final genres = artist.genres ?? [];
    return ListTile(
      leading: artist.images?.isNotEmpty == true
          ? CircleAvatar(
              backgroundImage: NetworkImage(artist.images!.first.url!),
            )
          : const CircleAvatar(
              child: Icon(Icons.person),
            ),
      title: Row(
        children: [
          Text(artist.name ?? 'Unknown Artist'),
          genres.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: genres
                        // .take(3)
                        .map((genre) {
                      return ElevatedButton(
                        style: _bannedGenres.contains(genre)
                            ? ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[900],
                                foregroundColor: Colors.white,
                              )
                            : ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                        onPressed: () => _addGenreToBanned(genre),
                        child: Text(genre),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: const Text('Genres in your Spotkin'),
      content: [
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_artistsInTargetPlaylist.isEmpty)
          const Center(
              child: Text('Run Spotkin to generate a list of bannable genres.'))
        else
          ..._artistsInTargetPlaylist.map(_buildArtistWidget),
      ],
    );
  }
}
