import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';
import '../widgets/spotify_button.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  List<Job> jobs = [];
  List<Map<String, dynamic>> jobResults = [];
  bool isProcessing = false;
  late ApiService _apiService;
  late StorageService _storageService;
  final SpotifyService spotifyService = getIt<SpotifyService>();
  final widgetPadding = 3.0;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _verifyToken();
    _apiService = ApiService(
      accessToken: widget.accessToken,
      backendUrl: widget.backendUrl,
    );
    _storageService = StorageService();
    _loadJobs();
  }

  void _addNewJob(Job newJob) {
    setState(
      () {
        jobs.add(newJob);
      },
    );
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

  Future<void> _processJobs() async {
    setState(() {
      isProcessing = true;
      jobResults.clear();
    });

    final results = await _apiService.processJobs(jobs);

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
        jobResults = results;
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
              initialIngredients: job.recipe,
              jobs: jobs,
              jobIndex: index,
              updateJob: updateJob,
              jobResults: jobResults,
            ),
          ],
        ),
      ),
    );
  }

  void _refreshJobs() {
    _loadJobs();
    // setState(() {
    //   _isExpanded = jobs.isEmpty;
    //   _expansionTileKey = UniqueKey();
    // });
  }

  void _replaceJob(Job newJob) {
    setState(() {
      jobs.clear();
      jobs.add(newJob);
      _isExpanded = false; // Collapse after changing the target playlist
    });
    _storageService.saveJobs(jobs);
  }

  Widget buildTargetPlaylistSelectionOptions() {
    return TargetPlaylistSelectionOptions(
      onPlaylistSelected: (PlaylistSimple selectedPlaylist) {
        if (jobs.isEmpty) {
          final newJob = Job(
            targetPlaylist: selectedPlaylist,
          );
          _addNewJob(newJob);
        } else {
          final updateJob = jobs[0].copyWith(targetPlaylist: selectedPlaylist);
          _replaceJob(updateJob);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    jobs: jobs,
                    updateJob: updateJob,
                    onJobsImported: _refreshJobs,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: jobsIterable.length + 1,
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
                  tabs: [
                    ...jobsIterable.map((entry) {
                      return Tab(
                        child: Text(
                          entry.value.targetPlaylist.name ?? 'New job',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      );
                    }),
                    const Tab(
                      icon: Icon(Icons.add),
                    )
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              ...jobsIterable.map((jobEntry) {
                final job = jobEntry.value;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      TargetPlaylistWidget(
                        targetPlaylist: job.targetPlaylist,
                        jobs: jobs,
                        isProcessing: isProcessing,
                        processJobs: _processJobs,
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
                      _buildRecipeCard(job, jobEntry.key),
                    ],
                  ),
                );
              }),
              Container(),
            ],
          ),
        ),
      ),
    );
  }
}
