import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';
import '../widgets/target_playlist_widget.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> config;

  const HomeScreen({
    Key? key,
    required this.config,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final BackendService _backendService = getIt<BackendService>();
  final SpotifyService spotifyService = getIt<SpotifyService>();
  // late TabController _tabController;

  bool isProcessing = false;
  bool _isExpanded = false;
  // bool _showAddJobButton = false;

  final widgetPadding = 3.0;

  @override
  void initState() {
    super.initState();
    _verifyToken(); // You can keep the token verification in initState
  }

  Future<void> _verifyToken() async {
    try {
      await spotifyService.checkAuthentication();
      print('Home screen: Token is valid');
    } catch (e) {
      print('Token verification failed: $e');
      // Handle re-authentication here
    }
  }

  void _addNewJob(Job newJob) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.addJob(newJob);
    // _updateTabController();
  }

  void _deleteJob(BuildContext context, int index) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final playlist = jobProvider.jobs[index].targetPlaylist!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete ${playlist.name}'),
          content: const Text(
              'Are you sure you want to delete this Spotkin? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                jobProvider.deleteJob(index);
                // _initTabController();
                // _tabController.animateTo(0);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    // _updateTabController();
  }

  Future<void> _processJob(Job job) async {
    print('Processing job: ${job.targetPlaylist.name}, id: ${job.id}');

    setState(() {
      isProcessing = true;
    });

    try {
      final allJobs = Provider.of<JobProvider>(context, listen: false).jobs;
      print('Total jobs: ${allJobs.length}');

      final results = await _backendService.processJob(job.id);

      print('Received results: $results');

      setState(() {
        isProcessing = false;
      });

      if (results.isNotEmpty) {
        _showResultSnackBar({
          'name': job.targetPlaylist.name,
          'status': 'success',
          'message': results['message'],
        });
      } else {
        _showResultSnackBar({
          'name': job.targetPlaylist.name,
          'status': 'Error',
          'message': 'No results returned from backend service',
        });
      }
    } catch (e, stackTrace) {
      print('Error in _processJob: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        isProcessing = false;
      });

      _showResultSnackBar({
        'name': job.targetPlaylist.name,
        'status': 'Error',
        'message': 'Error: ${e.toString()}',
      });
    }
  }

  void _showResultSnackBar(Map<String, dynamic> result) {
    if (result['status'] == 'success') {
      // do nothing
    } else {
      // play unhappy sound
    }
    final snackBar = SnackBar(
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: result['status'] == 'success' ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['name'],
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result['message'],
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              result['status'] == 'success' ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _updateJob(Job newJob, int index) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.updateJob(index, newJob);
    setState(() {
      _isExpanded = false; // Collapse after changing the target playlist
    });
    // _updateTabController();
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
              job: job,
              jobIndex: index,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTargetPlaylistSelectionOptions(int index) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    return TargetPlaylistSelectionOptions(
      job: jobProvider.jobs[index],
      deleteJob: () => _deleteJob(context, index),
      onPlaylistSelected: (PlaylistSimple selectedPlaylist) {
        if (jobProvider.jobs.isEmpty) {
          final newJob = Job(
            targetPlaylist: selectedPlaylist,
            id: const Uuid().v4(),
          );
          _addNewJob(newJob);
        } else {
          if (jobProvider.jobs
              .any((job) => job.targetPlaylist.id == selectedPlaylist.id)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Playlist already selected for another job.'),
              ),
            );
            return;
          }
          final updateJob = jobProvider.jobs[index]
              .copyWith(targetPlaylist: selectedPlaylist);
          _updateJob(updateJob, index);
        }
        // Auto-collapse after selection
        setState(() {
          _isExpanded = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<JobProvider>(
      builder: (context, jobProvider, child) {
        if (jobProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final jobs = jobProvider.jobs;
        final jobsIterable =
            jobs.isNotEmpty ? jobs.asMap().entries : [MapEntry(0, Job.empty())];

        final jobEntry = jobsIterable.first;
        final job = jobEntry.value;

        // // Ensure tab controller is up to date
        // _updateTabController();

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            // title: const Text('Spotkin'),
            automaticallyImplyLeading: false,
            actions: const [
              InfoButton(),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                TargetPlaylistWidget(
                  index: jobEntry.key,
                  isProcessing: isProcessing,
                  processJob: _processJob,
                  buildTargetPlaylistSelectionOptions:
                      buildTargetPlaylistSelectionOptions,
                  isExpanded: _isExpanded,
                  onExpandChanged: (expanded) {
                    setState(() {
                      _isExpanded = expanded;
                    });
                  },
                ),
                SizedBox(height: widgetPadding),
                if (!job.isNull) _buildRecipeCard(job, jobEntry.key),
              ],
            ),

            // if (_showAddJobButton)
            //   SingleChildScrollView(
            //     child: Column(
            //       children: [
            //         const SizedBox(height: 15),
            //         ElevatedButton(
            //           onPressed: () {
            //             _addNewJob(Job.empty());
            //           },
            //           child: const Text('Add new job'),
            //         ),
            //       ],
            //     ),
            //   ),
            // ],
          ),
          // ),
        );
      },
    );
  }
}
