import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart' hide Image;
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/widgets/bottom_sheets/banned_items_bottom_sheet.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      final job = jobProvider.jobs[widget.jobIndex];
      final items = _getItems(job);
      if (items.isEmpty) {
        showSearchBottomSheet();
      }
    });
  }

  List<dynamic> _getItems(Job job) {
    switch (widget.fieldName) {
      case 'bannedArtists':
        return List<Artist>.from(job.bannedArtists);
      case 'bannedAlbums':
        return List<AlbumSimple>.from(job.bannedAlbums);
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

  void showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        switch (widget.fieldName) {
          case 'bannedGenres':
            return BannedGenresBottomSheet(jobIndex: widget.jobIndex);
          case 'bannedAlbums':
            return BannedAlbumsBottomSheet(jobIndex: widget.jobIndex);
          case 'bannedTracks':
            return BannedTracksBottomSheet(jobIndex: widget.jobIndex);
          case 'bannedArtists':
            return BannedArtistsBottomSheet(jobIndex: widget.jobIndex);
          default:
            return SearchBottomSheet(
              onItemSelected: _addItem,
              searchTypes: widget.searchTypes,
            );
        }
      },
    );
  }

  void _addItem(dynamic item) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    final items = _getItems(job);

    if (!items.any((existingItem) => existingItem.id == item.id)) {
      items.add(item);
      final updatedJob = _createUpdatedJob(job, items);
      jobProvider.updateJob(widget.jobIndex, updatedJob);
    }
  }

  Job _createUpdatedJob(Job job, List<dynamic> items) {
    switch (widget.fieldName) {
      case 'bannedArtists':
        return job.copyWith(bannedArtists: items as List<Artist>);
      case 'bannedAlbums':
        return job.copyWith(bannedAlbums: items as List<AlbumSimple>);
      case 'bannedTracks':
        return job.copyWith(bannedTracks: items as List<Track>);
      case 'bannedGenres':
        return job.copyWith(bannedGenres: items as List<String>);
      case 'exceptionsToBannedGenres':
        return job.copyWith(exceptionsToBannedGenres: items as List<Artist>);
      case 'lastTracks':
        return job.copyWith(lastTracks: items as List<Track>);
      default:
        return job;
    }
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
      body: Consumer<JobProvider>(
        builder: (context, jobProvider, child) {
          final job = jobProvider.jobs[widget.jobIndex];
          final bannedItems =
              _getItems(job); // These are the banned items from the job

          return Column(
            children: [
              if (bannedItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    getEmptySettingString(widget.fieldName),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: showSearchBottomSheet,
                  child: const Text('Add New Item'),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: bannedItems.length,
                  itemBuilder: (context, index) {
                    final item = bannedItems[index];
                    return ListTile(
                      leading: _buildLeadingImage(item),
                      title: Text(_getItemTitle(item)),
                      subtitle: _buildSubtitle(context, item),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          final updatedItems = List<dynamic>.from(bannedItems)
                            ..removeAt(index);
                          final updatedJob =
                              _createUpdatedJob(job, updatedItems);
                          jobProvider.updateJob(widget.jobIndex, updatedJob);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeadingImage(dynamic item) {
    String? imageUrl;
    if (item is Artist) {
      imageUrl =
          item.images?.isNotEmpty == true ? item.images!.first.url : null;
    } else if (item is AlbumSimple) {
      imageUrl =
          item.images?.isNotEmpty == true ? item.images!.first.url : null;
    } else if (item is Track) {
      imageUrl = item.album?.images?.isNotEmpty == true
          ? item.album!.images!.first.url
          : null;
    }

    if (imageUrl != null) {
      return ClipRRect(
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
    return const Icon(Icons.music_note, size: 50);
  }

  String _getItemTitle(dynamic item) {
    if (item is Artist) return item.name ?? 'Unknown Artist';
    if (item is AlbumSimple) return item.name ?? 'Unknown Album';
    if (item is Track) return item.name ?? 'Unknown Track';
    if (item is String) return item;
    return 'Unknown Item';
  }

  Widget? _buildSubtitle(BuildContext context, dynamic item) {
    String? subtitle;
    if (item is Artist) {
      subtitle = 'Artist • Popularity: ${item.popularity ?? 'N/A'}';
    } else if (item is AlbumSimple) {
      subtitle =
          '${item.artists?.isNotEmpty == true ? item.artists!.first.name : 'Unknown Artist'} • ${item.releaseDate ?? 'Unknown Release Date'}';
    } else if (item is Track) {
      subtitle =
          '${item.artists?.isNotEmpty == true ? item.artists!.first.name : 'Unknown Artist'} • ${item.album?.name ?? 'Unknown Album'}';
    }

    return subtitle != null
        ? Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall,
          )
        : null;
  }
}

class _ItemsList extends StatelessWidget {
  final int jobIndex;
  final String fieldName;
  final List<dynamic> Function(Job) getItems;
  final Job Function(Job, List<dynamic>) createUpdatedJob;

  const _ItemsList({
    required this.jobIndex,
    required this.fieldName,
    required this.getItems,
    required this.createUpdatedJob,
  });

  void _removeItem(BuildContext context, int index, List<dynamic> items) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[jobIndex];
    items.removeAt(index);
    final updatedJob = createUpdatedJob(job, items);
    jobProvider.updateJob(jobIndex, updatedJob);
  }

  Widget _buildListItem(
      BuildContext context, dynamic item, List<dynamic> items) {
    String name = '';
    String? subtitle;
    String? imageUrl;

    if (item is Artist) {
      name = item.name ?? 'Unknown Artist';
      subtitle = 'Artist • Popularity: ${item.popularity ?? 'N/A'}';
      imageUrl =
          item.images?.isNotEmpty == true ? item.images!.first.url : null;
    } else if (item is AlbumSimple) {
      name = item.name ?? 'Unknown Album';
      subtitle =
          '${item.artists?.isNotEmpty == true ? item.artists!.first.name : 'Unknown Artist'} • ${item.releaseDate ?? 'Unknown Release Date'}';
      imageUrl =
          item.images?.isNotEmpty == true ? item.images!.first.url : null;
    } else if (item is Track) {
      name = item.name ?? 'Unknown Track';
      subtitle =
          '${item.artists?.isNotEmpty == true ? item.artists!.first.name : 'Unknown Artist'} • ${item.album?.name ?? 'Unknown Album'}';
      imageUrl = item.album?.images?.isNotEmpty == true
          ? item.album!.images!.first.url
          : null;
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
        onPressed: () => _removeItem(context, items.indexOf(item), items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        final job = jobProvider.jobs[jobIndex];
        final items = getItems(job);

        if (items.isEmpty) {
          return Center(
            child: Text(
              getEmptySettingString(fieldName),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          );
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _buildListItem(context, items[index], items),
        );
      },
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
