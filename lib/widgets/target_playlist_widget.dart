import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' hide Image;
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/widgets/spotify_button.dart';

class TargetPlaylistWidget extends StatelessWidget {
  final PlaylistSimple targetPlaylist;
  final List<Job> jobs;
  final bool isProcessing;
  final void Function() processJobs;
  final Widget Function() buildTargetPlaylistSelectionOptions;
  final bool isExpanded;
  final Function(bool) onExpandChanged;

  const TargetPlaylistWidget({
    Key? key,
    required this.targetPlaylist,
    required this.jobs,
    required this.isProcessing,
    required this.processJobs,
    required this.buildTargetPlaylistSelectionOptions,
    required this.isExpanded,
    required this.onExpandChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expansionTileTheme = Theme.of(context).expansionTileTheme;

    return Container(
      decoration: BoxDecoration(
        color: expansionTileTheme.backgroundColor,
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
                if (jobs.isEmpty)
                  Column(
                    children: [
                      Text(
                        'Select a playlist',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      buildTargetPlaylistSelectionOptions(),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlaylistTitle(
                              context,
                              targetPlaylist,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 5),
                            playlistSubtitle(targetPlaylist, context),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // const SizedBox(width: 8),
                          SpotifyButton(
                            isProcessing: isProcessing,
                            processJobs: processJobs,
                            onPressed: processJobs,
                          ),
                        ],
                      ),
                    ],
                  ),
                if (isExpanded && jobs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  buildTargetPlaylistSelectionOptions(),
                ],
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Icon(isExpanded ? Icons.edit_off : Icons.edit),
                onPressed: () {
                  onExpandChanged(!isExpanded);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
