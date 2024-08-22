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
  // late StorageService _storageService;
  final SpotifyService spotifyService = getIt<SpotifyService>();
  TabController? _tabController;
  bool _isExpanded = false;
  bool _showAddJobButton = false;
  List<Map<String, dynamic>?> jobResults = [];
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _verifyToken();
    _backendService = BackendService(
      accessToken: widget.accessToken,
      backendUrl: widget.backendUrl,
    );
    // _storageService = StorageService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobs();
    });
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

  Future<void> _loadJobs() async {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    await jobProvider.loadJobs();
    _updateTabController();
  }

  void _updateTabController() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final jobs = jobProvider.jobs;
    setState(() {
      _showAddJobButton = jobs.length < maxJobs;
      // _tabController?.dispose(); // Dispose the old controller
      // _tabController = TabController(
      //   length: jobs.length + (_showAddJobButton ? 1 : 0),
      //   vsync: this,
      // );
    });
  }

  void _addNewJob(Job newJob) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.addJob(newJob);
    _updateTabController();
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
                _updateTabController();
                Navigator.of(context).pop();
                _tabController?.animateTo(0);
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
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    setState(() {
      isProcessing = true;
      jobResults = List.filled(jobProvider.jobs.length, null);
    });

    final results =
        await _backendService.processJobs(jobProvider.jobs, [index]);

    if (results.isNotEmpty) {
      if (results[0].containsKey('status') && results[0]['status'] == 'Error') {
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

  void _updateJob(int index, Job updatedJob) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.updateJob(index, updatedJob);
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
              onJobsReloaded: _loadJobs,
              updateJob: _updateJob,
              addJob: _addNewJob,
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
          final newJob = Job(targetPlaylist: selectedPlaylist);
          _addNewJob(newJob);
        } else {
          if (jobProvider.jobs
              .any((job) => job.targetPlaylist.id == selectedPlaylist.id)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Playlist already selected for another job.')),
            );
            return;
          }
          final updatedJob = jobProvider.jobs[index]
              .copyWith(targetPlaylist: selectedPlaylist);
          _updateJob(index, updatedJob);
        }
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

        if (jobProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
            length: jobs.length + (_showAddJobButton ? 1 : 0),
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
                        if (index == jobs.length && _showAddJobButton) {
                          _tabController?.animateTo(jobs.length);
                          jobProvider.addJob(Job.empty());
                          _updateTabController(); // Update the controller after adding a job
                        }
                      },
                      tabs: [
                        ...jobs.map((job) {
                          return Tab(
                            child: Text(
                              job.targetPlaylist.name ?? 'New job',
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
                  ...jobs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final job = entry.value;
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          TargetPlaylistWidget(
                            targetPlaylist: job.targetPlaylist,
                            job: job,
                            index: index,
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
                          const SizedBox(height: 3.0),
                          if (!job.isNull) _buildRecipeCard(job, index),
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
                              _tabController?.animateTo(jobs.length);
                              jobProvider.addJob(Job.empty());
                              _updateTabController(); // Update the controller after adding a job
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

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
