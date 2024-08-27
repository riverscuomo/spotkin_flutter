import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';
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
        final job = jobProvider.getJob(index);
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
                    if (job.isNull || targetPlaylist.id == null)
                      _buildPlaylistSelectionContent(context, job)
                    else
                      _buildPlaylistContent(context, job, targetPlaylist),
                    if (isExpanded && !job.isNull && targetPlaylist.id != null)
                      _buildExpandedContent(context),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => onExpandChanged(!isExpanded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistSelectionContent(BuildContext context, Job job) {
    return Column(
      children: [
        Text(
          'Select a playlist',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        buildTargetPlaylistSelectionOptions(index),
      ],
    );
  }

  Widget _buildPlaylistContent(
      BuildContext context, Job job, PlaylistSimple targetPlaylist) {
    return Row(
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
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(targetPlaylist.description ?? '',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (job.recipe.isNotEmpty)
          UpdateButton(
            isProcessing: isProcessing,
            onPressed: () => processJob(job, index),
          ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Edit Spotkin Settings',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        buildTargetPlaylistSelectionOptions(index),
      ],
    );
  }
}
