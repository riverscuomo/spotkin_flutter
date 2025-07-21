import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart' hide Offset;
import 'package:spotkin_flutter/app_core.dart';
import '../widgets/playlist/target_playlist_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:spotkin_flutter/data/models/job.dart' show FreezeStatus;

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
  late TabController _tabController;

  bool isProcessing = false;
  bool _isExpanded = false;
  // bool _showAddJobButton = false;

  final widgetPadding = 3.0;

  @override
  void initState() {
    super.initState();
    _verifyToken(); // You can keep the token verification in initState
    _tabController = TabController(
        length: 3,
        vsync: this,
        initialIndex: 2); // Start with Tracks tab (index 2)
    _tabController.addListener(() {
      // This will trigger a rebuild when the tab changes
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    try {
      await spotifyService.checkAuthentication();
      debugPrint('Home screen: Token is valid');
    } catch (e) {
      debugPrint('Token verification failed: $e');
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
    debugPrint('Processing job: ${job.targetPlaylist.name}, id: ${job.id}');

    setState(() {
      isProcessing = true;
    });

    try {
      final allJobs = Provider.of<JobProvider>(context, listen: false).jobs;
      debugPrint('Total jobs: ${allJobs.length}');

      final results = await _backendService.processJob(job.id);

      debugPrint('Received results: $results');

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
      debugPrint('Error in _processJob: $e');
      debugPrint('Stack trace: $stackTrace');

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
  }

  Widget buildTargetPlaylistSelectionOptions(int index) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    return TargetPlaylistSelectionOptions(
      job: jobProvider.jobs[index],
      deleteJob: () => _deleteJob(context, index),
      onPlaylistSelected: (PlaylistSimple selectedPlaylist) {
        if (jobProvider.jobs.isEmpty) {
          final newJob = Job(
            freezeStatus: const FreezeStatus(
              daysSinceUpdate: 0,
              daysUntilFreeze: 21,
              freezeThresholdDays: 21,
              isFrozen: false,
            ),
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
          return Center(
            child:
                const CircularProgressIndicator().withDebugLabel('HomeLoader'),
          ).withDebugLabel('LoadingCenter');
        }

        final jobs = jobProvider.jobs;
        final jobsIterable =
            jobs.isNotEmpty ? jobs.asMap().entries : [MapEntry(0, Job.empty())];

        final jobEntry = jobsIterable.first;
        final job = jobEntry.value;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            // title: const Text('Spotkin'),
            automaticallyImplyLeading: false,
            actions: const [
              InfoButton(),
            ],
          ),
          body: Column(
            children: [
              // Target Playlist Widget stays at the top for all tabs
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
              ).withDebugLabel('TargetPlaylistWidget'),
              SizedBox(height: widgetPadding),

              // Tab selector
              if (!job.isNull)
                Container(
                  decoration: BoxDecoration(
                    color: Colors
                        .black, // Darker background for more contrast with pills
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.3), width: 1),
                  ),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Determine if we should use fixed tabs or scrollable tabs
                      // based on the available width
                      final screenWidth = constraints.maxWidth;
                      final bool useFixedTabs =
                          screenWidth > 500; // Threshold for switching modes

                      return TabBar(
                        controller: _tabController,
                        isScrollable:
                            !useFixedTabs, // Scrollable on narrow screens, fixed on wide screens
                        tabs: [
                          Material(
                            elevation: _tabController.index == 0 ? 12 : 0,
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 20),
                              constraints: const BoxConstraints(minHeight: 38),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: _tabController.index == 0
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey.withOpacity(0.15),
                                border: Border.all(
                                  color: _tabController.index == 0
                                      ? const Color(0xFF4CAF50)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: const Text('Filters'),
                            ),
                          ),
                          Material(
                            elevation: _tabController.index == 1 ? 12 : 0,
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 20),
                              constraints: const BoxConstraints(
                                  minHeight: 38), // Fixed height constraint
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: _tabController.index == 1
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey.withOpacity(0.15),
                                border: Border.all(
                                  color: _tabController.index == 1
                                      ? const Color(0xFF4CAF50)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: const Text('Sources'),
                            ),
                          ),
                          Material(
                            elevation: _tabController.index == 2 ? 12 : 0,
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 20),
                              constraints: const BoxConstraints(
                                  minHeight: 38), // Fixed height constraint
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: _tabController.index == 2
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey.withOpacity(0.15),
                                border: Border.all(
                                  color: _tabController.index == 2
                                      ? const Color(0xFF4CAF50)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Text(job.targetPlaylist.name ?? 'Tracks'),
                            ),
                          ),
                        ],
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.7),
                        // Remove default indicator
                        indicator: const BoxDecoration(),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 4.0),
                        // Responsive spacing between tabs based on screen width
                        labelPadding: EdgeInsets.symmetric(
                          horizontal: useFixedTabs
                              ? (constraints.maxWidth / 50).clamp(4.0, 12.0)
                              : 2.0,
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: widgetPadding),

              // Main content with tabs
              if (!job.isNull)
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Filters Tab
                      SingleChildScrollView(
                        child: FiltersTab(
                          index: jobEntry.key,
                        ),
                      ),

                      // Playlists Tab
                      SingleChildScrollView(
                        child: SourcesTab(
                          job: job,
                          jobIndex: jobEntry.key,
                        ),
                      ),

                      // Tracks Tab
                      TracksTab(
                        job: job,
                        jobIndex: jobEntry.key,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ).withDebugLabel('HomeScaffold');
      },
    );
  }
}
