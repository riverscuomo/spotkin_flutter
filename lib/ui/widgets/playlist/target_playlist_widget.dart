import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/ui/widgets/buttons/update_button.dart';

class TargetPlaylistWidget extends StatelessWidget {
  final int index;
  final bool isProcessing;
  final void Function(Job) processJob;
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
        // Check if jobs list is empty or index is out of bounds
        if (jobProvider.jobs.isEmpty || index >= jobProvider.jobs.length) {
          return Column(
            children: [
              Text(
                'No jobs available. Please add a job.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          );
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
                    // Freeze status banners
                    if (job.freezeStatus.isFrozen)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Job frozen – update needed!',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (job.freezeStatus.daysUntilFreeze < 7)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.black),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Job will freeze in ${job.freezeStatus.daysUntilFreeze.toStringAsFixed(0)} days',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    PlaylistImageIcon(
                      playlist: targetPlaylist,
                      size: 160,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Last updated ${job.freezeStatus.daysSinceUpdate.toStringAsFixed(0)} days ago',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
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
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // SizedBox(),
                          job.recipe.isEmpty
                              ? const SizedBox()
                              : UpdateButton(
                                  isProcessing: isProcessing,
                                  onPressed: () => processJob(job),
                                ),
                        ],
                      ),
                    if (isExpanded) ...[
                      const SizedBox(height: 16),
                      buildTargetPlaylistSelectionOptions(index),
                    ],
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      icon: const Icon(Icons.expand_more),
                      onPressed: () {
                        onExpandChanged(!isExpanded);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
