import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' hide Image;
import 'package:spotkin_flutter/app_core.dart';

class ListManagementScreen extends StatefulWidget {
  final String title;
  final Job job;
  final int jobIndex;
  final String fieldName;
  final String tooltip;
  final Function(int, Job) updateJob;
  final List<SearchType> searchTypes;

  const ListManagementScreen({
    Key? key,
    required this.title,
    required this.job,
    required this.jobIndex,
    required this.fieldName,
    required this.tooltip,
    required this.updateJob,
    required this.searchTypes,
  }) : super(key: key);

  @override
  _ListManagementScreenState createState() => _ListManagementScreenState();
}

class _ListManagementScreenState extends State<ListManagementScreen> {
  late List<dynamic> _items;

  @override
  void initState() {
    super.initState();
    _items = _getItems();
  }

  List<dynamic> _getItems() {
    switch (widget.fieldName) {
      case 'bannedArtists':
        return widget.job.bannedArtists;
      case 'bannedTracks':
        return widget.job.bannedTracks;
      case 'bannedGenres':
        return widget.job.bannedGenres;
      case 'exceptionsToBannedGenres':
        return widget.job.exceptionsToBannedGenres;
      case 'lastTracks':
        return widget.job.lastTracks;
      default:
        return [];
    }
  }

  void _addItem(dynamic item) {
    setState(() {
      if (!_items.any((existingItem) => existingItem.id == item.id)) {
        _items.add(item);
        _updateJob();
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _updateJob();
    });
  }

  void _updateJob() {
    Job updatedJob;
    switch (widget.fieldName) {
      case 'bannedArtists':
        updatedJob = widget.job.copyWith(bannedArtists: _items as List<Artist>);
        break;
      case 'bannedTracks':
        updatedJob = widget.job.copyWith(bannedTracks: _items as List<Track>);
        break;
      case 'bannedGenres':
        updatedJob = widget.job.copyWith(bannedGenres: _items as List<String>);
        break;
      case 'exceptionsToBannedGenres':
        updatedJob = widget.job
            .copyWith(exceptionsToBannedGenres: _items as List<Artist>);
        break;
      case 'lastTracks':
        updatedJob = widget.job.copyWith(lastTracks: _items as List<Track>);
        break;
      default:
        return;
    }
    widget.updateJob(widget.jobIndex, updatedJob);
  }

  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SearchBottomSheet(
          onItemSelected: _addItem,
          searchTypes: widget.searchTypes,
        );
      },
    );
  }

  Widget _buildListItem(dynamic item) {
    String name = '';
    String? subtitle;
    String? imageUrl;

    if (item is Artist) {
      name = item.name ?? 'Unknown Artist';
      subtitle = 'Artist • Popularity: ${item.popularity ?? 'N/A'}';
      imageUrl =
          item.images?.isNotEmpty == true ? item.images!.first.url : null;
    } else if (item is Track) {
      name = item.name ?? 'Unknown Track';
      subtitle =
          '${item.artists?.isNotEmpty == true ? item.artists!.first.name : 'Unknown Artist'} • ${item.album?.name ?? 'Unknown Album'}';
      imageUrl = item.album?.images?.isNotEmpty == true
          ? item.album!.images!.first.url
          : null;
    } else if (item is Album) {
      name = item.name ?? 'Unknown Album';
      subtitle =
          '${item.artists?.isNotEmpty == true ? item.artists!.first.name : 'Unknown Artist'} • ${item.releaseDate ?? 'Unknown Release Date'}';
      imageUrl =
          item.images?.isNotEmpty == true ? item.images!.first.url : null;
    } else if (item is PlaylistSimple) {
      name = item.name ?? 'Unknown Playlist';
      subtitle = 'Playlist • ${item.tracksLink?.total ?? 0} tracks';
      imageUrl =
          item.images?.isNotEmpty == true ? item.images!.first.url : null;
    } else if (item is String) {
      name = item;
      subtitle = 'Genre';
    }

    Widget leadingWidget;
    if (imageUrl != null) {
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.music_note, size: 50),
        ),
      );
    } else {
      leadingWidget = Icon(Icons.music_note, size: 50);
    }

    return ListTile(
      leading: leadingWidget,
      title: Text(name),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => _removeItem(_items.indexOf(item)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(widget.tooltip),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _showSearchBottomSheet,
              child: const Text('Add New Item'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) => _buildListItem(_items[index]),
            ),
          ),
        ],
      ),
    );
  }
}
