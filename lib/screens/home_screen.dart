import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';
import '../widgets/target_playlist_widget.dart';

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
  late BackendService _BackendService;
  late StorageService _storageService;
  final SpotifyService spotifyService = getIt<SpotifyService>();
  late TabController? _tabController;

  List<Job> jobs = [];
  List<Map<String, dynamic>?> jobResults = [];
  bool isProcessing = false;
  bool _isExpanded = false;
  bool _showAddJobButton = false;

  final widgetPadding = 3.0;
  final maxJobs = 2;

  @override
  void initState() {
    super.initState();
    _verifyToken();
    _BackendService = BackendService(
      accessToken: widget.accessToken,
      backendUrl: widget.backendUrl,
    );
    _storageService = StorageService();
    _loadJobs();
    _showAddJobButton = jobs.isNotEmpty &&
        !jobs.any((job) => job.isNull) &&
        jobs.length < maxJobs;
    _tabController = TabController(
        length: (jobs.isEmpty ? 1 : jobs.length) + (_showAddJobButton ? 1 : 0),
        vsync: this);
  }

  void _addNewJob(Job newJob) {
    setState(() {
      jobs.add(newJob);
      _updateTabController();
    });
    _storageService.saveJobs(jobs);
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

  void _loadJobs() {
    setState(() {
      jobs = _storageService.getJobs();
    });
  }

  Future<void> _processJob(Job job, int index) async {
    setState(() {
      isProcessing = true;
      jobResults = List.filled(jobs.length, null);
    });

    final results = await _BackendService.processJobs(
        jobs, [index]); // only process the job at the given index

    if (results.isNotEmpty) {
      // If the token has expired, re-authenticate
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

  void updateJob(int index, Job updatedJob) {
    print("Updating job at index $index: ${updatedJob.targetPlaylist.name}");
    setState(() {
      jobs[index] = updatedJob;
    });
    _storageService.saveJobs(jobs);
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
              updateJob: updateJob,
              addJob: _addNewJob,
              jobResults: jobResults,
            ),
          ],
        ),
      ),
    );
  }

  void _replaceJob(Job newJob, int index) {
    setState(() {
      jobs[index] = newJob;
      _isExpanded = false; // Collapse after changing the target playlist
      _updateTabController();
    });
    _storageService.saveJobs(jobs);
  }

  void _updateTabController() {
    final index = _tabController?.index ?? 0;
    _showAddJobButton = jobs.length < maxJobs && !jobs.any((job) => job.isNull);
    _tabController = TabController(
        length: jobs.length + (_showAddJobButton ? 1 : 0), vsync: this);
    _tabController?.index = index;
  }

  Widget buildTargetPlaylistSelectionOptions(int index) {
    return TargetPlaylistSelectionOptions(
      onPlaylistSelected: (PlaylistSimple selectedPlaylist) {
        if (jobs.isEmpty) {
          final newJob = Job(
            targetPlaylist: selectedPlaylist,
          );
          _addNewJob(newJob);
        } else {
          if (jobs.any((job) => job.targetPlaylist.id == selectedPlaylist.id)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Playlist already selected for another job.'),
              ),
            );
            return;
          }
          final updateJob =
              jobs[index].copyWith(targetPlaylist: selectedPlaylist);
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
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
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
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
