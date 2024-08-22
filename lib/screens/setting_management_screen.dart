import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart' hide Image;
import 'package:spotkin_flutter/app_core.dart';

import '../widgets/bottom_sheets/banned_genres_bottom_sheet.dart';

class SettingManagementScreen extends StatefulWidget {
  final String title;
  final int jobIndex;
  final String fieldName;
  final String tooltip;
  final List<SearchType> searchTypes;

  const SettingManagementScreen({
    Key? key,
    required this.title,
    required this.jobIndex,
    required this.fieldName,
    required this.tooltip,
    required this.searchTypes,
  }) : super(key: key);

  @override
  _SettingManagementScreenState createState() =>
      _SettingManagementScreenState();
}

class _SettingManagementScreenState extends State<SettingManagementScreen> {
  late List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _initItems();
  }

  void _initItems() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    _items = _getItems(job);
  }

  List<dynamic> _getItems(Job job) {
    switch (widget.fieldName) {
      case 'bannedArtists':
        return List<Artist>.from(job.bannedArtists);
      case 'bannedTracks':
        return List<Track>.from(job.bannedTracks);
      case 'bannedGenres':
        return List<String>.from(job.bannedGenres);
      case 'exceptionsToBannedGenres':
        return List<Artist>.from(job.exceptionsToBannedGenres);
      case 'lastTracks':
        return List<Track>.from(job.lastTracks);
      default:
        return [];
    }
  }

  void _updateJobAndState() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    final updatedJob = _createUpdatedJob(job);
    jobProvider.updateJob(widget.jobIndex, updatedJob);
    setState(() {
      _items = _getItems(updatedJob);
    });
    print(
        'Job updated in SettingManagementScreen. ${widget.fieldName} count: ${_items.length}');
  }

  void showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return widget.fieldName == 'bannedGenres'
            ? BannedGenresBottomSheet(
                jobIndex: widget.jobIndex,
              )
            : SearchBottomSheet(
                onItemSelected: _addItem,
                searchTypes: widget.searchTypes,
              );
      },
    ).then((_) {
      _initItems();
    });
  }

  void _addItem(dynamic item) {
    if (!_items.any((existingItem) => existingItem.id == item.id)) {
      setState(() {
        _items.add(item);
        _updateJobAndState();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _updateJobAndState();
    });
  }

  Job _createUpdatedJob(Job job) {
    switch (widget.fieldName) {
      case 'bannedArtists':
        return job.copyWith(bannedArtists: _items as List<Artist>);
      case 'bannedTracks':
        return job.copyWith(bannedTracks: _items as List<Track>);
      case 'bannedGenres':
        return job.copyWith(bannedGenres: _items as List<String>);
      case 'exceptionsToBannedGenres':
        return job.copyWith(exceptionsToBannedGenres: _items as List<Artist>);
      case 'lastTracks':
        return job.copyWith(lastTracks: _items as List<Track>);
      default:
        return job;
    }
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
      subtitle = '';
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
              const Icon(Icons.music_note, size: 50),
        ),
      );
    } else {
      leadingWidget = const Icon(Icons.music_note, size: 50);
    }

    return ListTile(
      leading: leadingWidget,
      title: Text(name),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.labelSmall,
            )
          : null,
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
          _items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    getEmptySettingString(widget.fieldName),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
              : const SizedBox.shrink(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: showSearchBottomSheet,
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

String getEmptySettingString(String fieldName) {
  switch (fieldName) {
    case 'bannedArtists':
      return 'No artists banned yet';
    case 'bannedTracks':
      return 'No tracks banned yet';
    case 'bannedGenres':
      return 'No genres banned yet';
    case 'exceptionsToBannedGenres':
      return 'No exceptions to banned genres yet';
    case 'lastTracks':
      return 'No last tracks added yet';
    default:
      return '';
  }
}
