import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';
import '../widgets/target_playlist_widget.dart';

const maxJobs = 2;

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> config;
  final String accessToken;
  final String backendUrl;

  const HomeScreen({
    Key? key,
    required this.config,
    required this.accessToken,
    required this.backendUrl,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late BackendService _backendService;

  final SpotifyService spotifyService = getIt<SpotifyService>();
  late TabController? _tabController;

  List<Map<String, dynamic>?> jobResults = [];
  bool isProcessing = false;
  bool _isExpanded = false;
  bool _showAddJobButton = false;

  final widgetPadding = 3.0;

  @override
  void initState() {
    super.initState();
    _verifyToken();
    _backendService = BackendService(
      accessToken: widget.accessToken,
      backendUrl: widget.backendUrl,
    );

    _initTabController();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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

  void _initTabController() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final jobs = jobProvider.jobs;
    _showAddJobButton = jobs.isNotEmpty &&
        !jobs.any((job) => job.isNull) &&
        jobs.length < maxJobs;
    _tabController = TabController(
      length: (jobs.isEmpty ? 1 : jobs.length) + (_showAddJobButton ? 1 : 0),
      vsync: this,
    );
  }

  void _addNewJob(Job newJob) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.addJob(newJob);
    _initTabController();
  }

  void _deleteJob(BuildContext context, int index) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final playlist = jobProvider.jobs[index].targetPlaylist;
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
                _initTabController();
                _tabController?.animateTo(0);
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
  }

  Future<void> _processJob(Job job, int index) async {
    setState(() {
      isProcessing = true;
      jobResults = List.filled(
          Provider.of<JobProvider>(context, listen: false).jobs.length, null);
    });

    final results = await _backendService.processJobs([job], [index]);

    if (results.isNotEmpty) {
      if (results[0].containsKey('status') && results[0]['status'] == 'Error') {
        print(results[0]['result'].runtimeType);
        final result = results[0]['result'] as String;
        print('Error processing jobs: $result');
        if (result.startsWith("Status widgetPadding01")) {
          print('Token expired, authenticate again...');
          spotifyService.initiateSpotifyLogin();
          return;
        }
      }
      setState(() {
        jobResults[index] = results[0];
        isProcessing = false;
      });
    }
  }

  void _replaceJob(Job newJob, int index) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.updateJob(index, newJob);
    setState(() {
      _isExpanded = false; // Collapse after changing the target playlist
    });
    _initTabController();
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
              jobResults: jobResults,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTargetPlaylistSelectionOptions(int index) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    return TargetPlaylistSelectionOptions(
      playlist: jobProvider.jobs[index].targetPlaylist,
      deleteJob: () => _deleteJob(context, index),
      onPlaylistSelected: (PlaylistSimple selectedPlaylist) {
        if (jobProvider.jobs.isEmpty) {
          final newJob = Job(
            targetPlaylist: selectedPlaylist,
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
          _replaceJob(updateJob, index);
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
        final jobs = jobProvider.jobs;
        final jobsIterable =
            jobs.isNotEmpty ? jobs.asMap().entries : [MapEntry(0, Job.empty())];
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: const Text('Spotkin'),
            titleTextStyle: Theme.of(context).textTheme.titleLarge,
            automaticallyImplyLeading: false,
            actions: const [
              InfoButton(),
            ],
          ),
          body: DefaultTabController(
            length: jobsIterable.length + (_showAddJobButton ? 1 : 0),
            child: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    expandedHeight: 0,
                    bottom: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelStyle: Theme.of(context).textTheme.labelMedium,
                      controller: _tabController,
                      onTap: (index) {
                        if (index == jobsIterable.length && _showAddJobButton) {
                          _tabController?.animateTo(jobsIterable.length);
                          _addNewJob(Job.empty());
                        }
                      },
                      tabs: [
                        ...jobsIterable.map((entry) {
                          return Tab(
                            child: Text(
                              entry.value.targetPlaylist.name ?? 'New job',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          );
                        }),
                        if (_showAddJobButton) const Tab(icon: Icon(Icons.add))
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  ...jobsIterable.map((jobEntry) {
                    final job = jobEntry.value;

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          TargetPlaylistWidget(
                            targetPlaylist: job.targetPlaylist,
                            job: job,
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
                    );
                  }),
                  if (_showAddJobButton)
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () {
                              _tabController?.animateTo(jobsIterable.length);
                              _addNewJob(Job.empty());
                            },
                            child: const Text('Add new job'),
                          ),
                        ],
                      ),
                    )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
