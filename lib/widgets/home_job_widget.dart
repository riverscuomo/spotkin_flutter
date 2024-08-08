import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/models/job.dart';
import 'package:spotkin_flutter/widgets/spotify_button.dart';

class HomeJobWidget extends StatefulWidget {
  final Job job;
  final int index;
  final List<Job> jobs;
  final Function(Job) onJobUpdate;
  final void Function() processJobs;

  const HomeJobWidget(
      {super.key,
      required this.job,
      required this.index,
      required this.jobs,
      required this.onJobUpdate,
      required this.processJobs});

  @override
  _HomeJobWidgetState createState() => _HomeJobWidgetState();
}

class _HomeJobWidgetState extends State<HomeJobWidget> {
  List<Map<String, dynamic>> jobResults = [];
  bool isProcessing = false;
  Key _expansionTileKey = UniqueKey();
  final widgetPadding = 3.0;
  bool _isExpanded = false;

  final SpotifyService spotifyService = getIt<SpotifyService>();
  final StorageService storageService = getIt<StorageService>();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.job.targetPlaylist.id == null;
  }

  @override
  Widget build(BuildContext context) {
    final targetPlaylist = widget.job.targetPlaylist;
    final index = widget.index;

    return SingleChildScrollView(
        child: Column(children: [
      ExpansionTile(
        key: _expansionTileKey,
        title: Column(children: [
          PlaylistImageIcon(
            playlist: targetPlaylist,
            size: 160,
          ),
          const SizedBox(height: 16),
          _isExpanded
              ? const SizedBox()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlaylistTitle(context, targetPlaylist,
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                playlistSubtitle(targetPlaylist, context),
                                const SizedBox(width: 10),
                                if (jobResults.isNotEmpty)
                                  Text(
                                    jobResults[0]['result'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium!
                                        .copyWith(fontStyle: FontStyle.italic),
                                  ),
                                const SizedBox(width: 10),
                                if (jobResults.isNotEmpty)
                                  Icon(
                                    size: 14,
                                    jobResults[0]['status'] == 'Success'
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: jobResults[0]['status'] == 'Success'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                              ],
                            ),
                          ],
                        ),
                        SpotifyButton(
                            isProcessing: isProcessing,
                            processJobs: widget.processJobs),
                      ],
                    )
                  ],
                )
        ]),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          TargetPlaylistSelectionOptions(
            onPlaylistSelected: (PlaylistSimple selectedPlaylist) {
              if (widget.jobs.isEmpty) {
                final newJob = Job(
                  targetPlaylist: selectedPlaylist,
                );
                _addNewJob(newJob);
              } else {
                final updateJob = widget.jobs[widget.index]
                    .copyWith(targetPlaylist: selectedPlaylist);
                _replaceJob(updateJob);
              }

              // Collapse the ExpansionTile
              setState(() {
                _isExpanded = false;
                _expansionTileKey = UniqueKey(); // This forces a rebuild
              });
            },
          ),
        ],
      ),
      SizedBox(height: widgetPadding),
      _buildRecipeCard(widget.job, index),
    ]));
  }

  Widget _buildRecipeCard(Job job, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecipeWidget(
              initialIngredients: job.recipe,
              jobIndex: index,
              jobs: widget.jobs,
              updateJob: updateJob,
              jobResults: jobResults,
              /* onIngredientsChanged: (updatedIngredients) {
                setState(() {
                  job = job.copyWith(recipe: updatedIngredients);
                  widget.jobs[index] = job;
                });
              }, */
              /* onRecipeDeleted: () {
                setState(() {
                  widget.jobs.removeAt(index);
                });
              },
              onRecipeAdded: (newRecipe) {
                setState(() {
                  job.recipe.add(newRecipe);
                  widget.jobs[index] = job;
                });
              }, */
            ),
          ],
        ),
      ),
    );
  }

  void _replaceJob(Job newJob) {
    setState(() {
      widget.jobs.clear();
      widget.jobs.add(newJob);
    });
    storageService.saveJobs(widget.jobs);
  }

  void _addNewJob(Job newJob) {
    setState(() {
      widget.jobs.add(newJob);
    });
    storageService.saveJobs(widget.jobs);
  }

  void updateJob(int index, Job updatedJob) {
    print("Updating job at index $index: ${updatedJob.targetPlaylist.name}");
    setState(() {
      widget.jobs[index] = updatedJob;
    });
    storageService.saveJobs(widget.jobs);
  }
}
