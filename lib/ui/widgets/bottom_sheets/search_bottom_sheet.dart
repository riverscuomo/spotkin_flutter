import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' hide Image;
import 'package:spotkin_flutter/app_core.dart';

class SearchBottomSheet extends StatefulWidget {
  final Function(dynamic) onItemSelected;
  final List<SearchType>? searchTypes;
  final bool userPlaylistsOnly;
  final String? title;
  final String? subtitle;

  const SearchBottomSheet({
    Key? key,
    required this.onItemSelected,
    this.searchTypes,
    this.userPlaylistsOnly = false,
    this.title,
    this.subtitle,
  })  : assert(
          !(userPlaylistsOnly && (searchTypes != null)),
          'searchTypes should not be provided when userPlaylistsOnly is true',
        ),
        super(key: key);

  @override
  _SearchBottomSheetState createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final SpotifyService spotifyService = getIt<SpotifyService>();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  // late List<Artist> artistsInTargetPlaylist = [];
  // late List<AlbumSimple> albumsInTargetPlaylist = [];

  @override
  void initState() {
    super.initState();
    if (widget.userPlaylistsOnly) {
      _fetchUserPlaylists();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchController.addListener(() {
          if (_searchController.text.isNotEmpty) {
            _debounceSearch();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debounceSearch() {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  void _fetchUserPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final playlists = await spotifyService.getUserPlaylists();
      setState(() {
        _searchResults = playlists;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching user playlists: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      // You might want to show an error message to the user here
    }
  }

  void _performSearch() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await spotifyService.search(
        query,
        types: widget.searchTypes ??
            [
              SearchType.track,
              SearchType.artist,
              SearchType.playlist,
              SearchType.album
            ],
        limit: 20,
      );

      // If the type is SimplePlaylist, if it contains "tracks" key, if "tracks" contains "href" key,
      // and if the "tracks"["total"] is 0, arbirtraitly set the total to 50. This is a 'For You' generated playlist?
      for (var element in results) {
        if (element is PlaylistSimple) {
          if (element.tracksLink != null) {
            if (element.tracksLink!.href != null) {
              if (element.tracksLink!.total == 0) {
                element.tracksLink!.total = 50;
              }
            }
          }
        }
      }

      setState(() {
        _searchResults = results.toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error performing search: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      // You might want to show an error message to the user here
    }
  }

  Widget _buildListItem(dynamic item) {
    String title = 'Unknown';
    String subtitle = 'Unknown Type';
    String? imageUrl = '';
    bool isArtist = false;

    if (item is Track) {
      title = item.name ?? 'Unknown Track';
      subtitle =
          '${item.artists?.isNotEmpty == true ? item.artists!.first.name : 'Unknown Artist'} • Track';
      imageUrl = item.album?.images?.isNotEmpty == true
          ? item.album!.images!.first.url
          : '';
    } else if (item is Artist) {
      title = item.name ?? 'Unknown Artist';
      subtitle = 'Artist';
      imageUrl = item.images?.isNotEmpty == true ? item.images!.first.url : '';
      isArtist = true;
    } else if (item is AlbumSimple) {
      title = item.name ?? 'Unknown Album';
      subtitle =
          '${item.artists?.isNotEmpty == true ? item.artists!.first.name : 'Unknown Artist'} • ${item.releaseDate ?? 'Unknown Release Date'}';
      imageUrl = item.images?.isNotEmpty == true ? item.images!.first.url : '';
    } else if (item is PlaylistSimple) {
      title = item.name ?? 'Unknown Playlist';
      subtitle =
          '${item.owner?.displayName} • ${item.tracksLink?.total ?? 0} tracks';
      imageUrl = item.images?.isNotEmpty == true ? item.images!.first.url : '';
    }

    Widget leadingWidget;
    if (imageUrl!.isNotEmpty) {
      if (isArtist) {
        leadingWidget = CircleAvatar(
          radius: 25,
          backgroundImage: NetworkImage(imageUrl),
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Error loading image: $exception');
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        );
      } else {
        leadingWidget = ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.music_note, size: 50),
          ),
        );
      }
    } else {
      leadingWidget = const Icon(Icons.music_note, size: 50);
    }

    return ListTile(
      leading: leadingWidget,
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.labelSmall,
      ),
      onTap: () {
        widget.onItemSelected(item);
        Navigator.pop(context);
      },
    );
  }

  String title = 'Search';

  @override
  Widget build(BuildContext context) {
    if (widget.title != null) {
      title = widget.title!;
    } else if (widget.userPlaylistsOnly) {
      title = 'Your Playlists';
    }
    return CustomBottomSheet(
      title: Text(title),
      subtitle: widget.subtitle != null
          ? Text(
              widget.subtitle!,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
              ),
            )
          : null,
      content: [
        if (!widget.userPlaylistsOnly)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _searchResults.isEmpty
                ? Center(
                    child: Text(widget.userPlaylistsOnly
                        ? 'No playlists found'
                        : 'No results found'))
                : Column(
                    children: _searchResults
                        .map((item) => _buildListItem(item))
                        .toList(),
                  ),
      ],
    );
  }
}
