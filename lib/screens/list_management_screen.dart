import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' hide Image;
import 'package:spotkin_flutter/app_core.dart';

import '../models/spotify_item.dart';

class DisplayItem {
  final String id;
  final String name;
  final String type;
  final String? imageUrl;
  final String? subtitle;

  DisplayItem({
    required this.id,
    required this.name,
    required this.type,
    this.imageUrl,
    this.subtitle,
  });
}

class ListManagementScreen extends StatefulWidget {
  final String title;
  final Job job;
  final int jobIndex;
  final String fieldName;
  final String tooltip;
  final Function(int, Job) updateJob; // Update the type here
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
  late List<DisplayItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _getItems();
  }

  List<DisplayItem> _getItems() {
    List<String> rawItems;
    switch (widget.fieldName) {
      case 'bannedArtistNames':
        rawItems = widget.job.bannedArtistNames;
        break;
      case 'bannedSongTitles':
        rawItems = widget.job.bannedSongTitles;
        break;
      case 'bannedTrackIds':
        rawItems = widget.job.bannedTrackIds;
        break;
      case 'bannedGenres':
        rawItems = widget.job.bannedGenres;
        break;
      case 'exceptionsToBannedGenres':
        rawItems = widget.job.exceptionsToBannedGenres;
        break;
      case 'lastTrackIds':
        rawItems = widget.job.lastTrackIds;
        break;
      default:
        rawItems = [];
    }

    return rawItems
        .map((item) => DisplayItem(
              id: item,
              name: item,
              type: widget.fieldName,
              imageUrl:
                  null, // We don't have image URLs for existing items, so we'll leave this null for now
            ))
        .toList();
  }

  void _addItem(dynamic item) {
    DisplayItem newItem;
    if (item is Artist) {
      newItem = DisplayItem(
        id: item.id ?? '',
        name: item.name ?? 'Unknown Artist',
        type: 'Artist',
        imageUrl:
            item.images?.isNotEmpty == true ? item.images!.first.url : null,
        subtitle: 'Artist',
      );
    } else if (item is Track) {
      newItem = DisplayItem(
        id: item.id ?? '',
        name: item.name ?? 'Unknown Track',
        type: 'Track',
        imageUrl: item.album?.images?.isNotEmpty == true
            ? item.album!.images!.first.url
            : null,
        subtitle:
            '${item.artists?.isNotEmpty == true ? item.artists!.first.name : 'Unknown Artist'} • Track',
      );
    } else if (item is PlaylistSimple) {
      newItem = DisplayItem(
        id: item.id ?? '',
        name: item.name ?? 'Unknown Playlist',
        type: 'Playlist',
        imageUrl:
            item.images?.isNotEmpty == true ? item.images!.first.url : null,
        subtitle: 'Playlist • ${item.tracksLink?.total ?? 0} tracks',
      );
    } else {
      print('Unsupported item type: ${item.runtimeType}');
      return;
    }

    setState(() {
      if (!_items.any((existingItem) => existingItem.id == newItem.id)) {
        _items.add(newItem);
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
    List<String> updatedList = _items.map((item) => item.name).toList();
    switch (widget.fieldName) {
      case 'bannedArtistNames':
        updatedJob = widget.job.copyWith(bannedArtistNames: updatedList);
        break;
      case 'bannedSongTitles':
        updatedJob = widget.job.copyWith(bannedSongTitles: updatedList);
        break;
      case 'bannedTrackIds':
        updatedJob = widget.job.copyWith(bannedTrackIds: updatedList);
        break;
      case 'bannedGenres':
        updatedJob = widget.job.copyWith(bannedGenres: updatedList);
        break;
      case 'exceptionsToBannedGenres':
        updatedJob = widget.job.copyWith(exceptionsToBannedGenres: updatedList);
        break;
      case 'lastTrackIds':
        updatedJob = widget.job.copyWith(lastTrackIds: updatedList);
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

  Widget _buildListItem(DisplayItem item) {
    Widget leadingWidget;
    if (item.imageUrl != null) {
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          item.imageUrl!,
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
      title: Text(item.name),
      subtitle: Text(item.subtitle ?? ''),
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
