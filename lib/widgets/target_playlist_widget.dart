import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/widgets/update_button.dart';

class TargetPlaylistWidget extends StatelessWidget {
  final int index;
  final bool isProcessing;
  final void Function(Job, int) processJob;
  final Widget Function(int) buildTargetPlaylistSelectionOptions;
  final bool isExpanded;
  final Function(bool) onExpandChanged;

  const TargetPlaylistWidget({
    Key? key,
    required this.index,
    required this.isProcessing,
    required this.processJob,
    required this.buildTargetPlaylistSelectionOptions,
    required this.isExpanded,
    required this.onExpandChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        if (jobProvider.jobs.isEmpty) {
          return _buildEmptyState(context);
        }

        final job = jobProvider.jobs[index];
        final targetPlaylist = job.targetPlaylist;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).expansionTileTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                Column(
                  children: [
                    PlaylistImageIcon(
                      playlist: targetPlaylist,
                      size: 160,
                    ),
                    const SizedBox(height: 16),
                    if (job.isNull)
                      Column(
                        children: [
                          Text(
                            'Select a playlist',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          buildTargetPlaylistSelectionOptions(index),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                playlistTitle(
                                  context,
                                  targetPlaylist,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 5),
                                Text(targetPlaylist.description ?? '',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              job.recipe.isEmpty
                                  ? const SizedBox()
                                  : UpdateButton(
                                      isProcessing: isProcessing,
                                      onPressed: () => processJob(job, index),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    if (isExpanded && !job.isNull) ...[
                      const SizedBox(height: 16),
                      buildTargetPlaylistSelectionOptions(index),
                    ],
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      onExpandChanged(!isExpanded);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).expansionTileTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.playlist_add,
              size: 160,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No playlists yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => buildTargetPlaylistSelectionOptions(0),
              child: const Text('Add a playlist'),
            ),
          ],
        ),
      ),
    );
  }
}
