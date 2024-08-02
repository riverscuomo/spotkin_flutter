import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';
import '../widgets/info_button.dart';
import '../widgets/playlist_image_icon.dart';
import '../widgets/spotify_button.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> config;
  final String accessToken;
  final String backendUrl;

  HomeScreen({
    required this.config,
    required this.accessToken,
    required this.backendUrl,
  });

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
  bool _isExpanded = false;
  Key _expansionTileKey = UniqueKey();
  final widgetPadding = 3.0;

  // bool _isResettingTargetPlaylist = false;

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
    _isExpanded = jobs.isEmpty;
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

  void _replaceJob(Job newJob) {
    setState(() {
      jobs.clear();
      jobs.add(newJob);
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

        // Collapse the ExpansionTile
        setState(() {
          _isExpanded = false;
          _expansionTileKey = UniqueKey(); // This forces a rebuild
        });
      },
    );
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
              updateJob: updateJob,
              onIngredientsChanged: (updatedIngredients) {
                setState(() {
                  job = job.copyWith(recipe: updatedIngredients);
                  updateJob(index, job);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = jobs.isEmpty ? Job.empty() : jobs[0];
    final targetPlaylist = job.targetPlaylist;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotkin'),
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
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widgetPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Material(
                    // color: Theme.of(context).cardColor,
                    elevation: 1,
                    borderRadius: BorderRadius.circular(12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: ExpansionTile(
                        key: _expansionTileKey,
                        title: Column(children: [
                          PlaylistImageIcon(
                            playlist: targetPlaylist,
                            size: 120,
                          ),
                          const SizedBox(height: 10),
                          PlaylistTitle(context, targetPlaylist),
                          const SizedBox(height: 5),
                          playlistSubtitle(targetPlaylist, context)
                        ]),
                        // leading: ,
                        // subtitle: ,
                        initiallyExpanded: _isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            _isExpanded = expanded;
                          });
                        },
                        children: [
                          buildTargetPlaylistSelectionOptions(),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: widgetPadding),
                  ...jobs.asMap().entries.map((entry) {
                    return _buildRecipeCard(entry.value, entry.key);
                  }),
                ],
              ),
              const SizedBox(height: 20),
              jobResults.isEmpty
                  ? const SizedBox()
                  : Column(children: [
                      ...jobResults.map((result) {
                        return ListTile(
                          title: Text(result['name']),
                          subtitle: Text(result['result'],
                              style: Theme.of(context).textTheme.labelSmall),
                          leading: Icon(
                            result['status'] == 'Success'
                                ? Icons.check_circle
                                : Icons.error,
                            color: result['status'] == 'Success'
                                ? Colors.green
                                : Colors.red,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow),
                            style: greenButtonStyle,
                            onPressed: () {
                              Utils.myLaunch(
                                  targetPlaylist.externalUrls?.spotify ?? '');
                            },
                          ),
                        );
                      }),
                    ]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: jobs.isNotEmpty && jobs[0].recipe.isNotEmpty
          ? SpotifyButton(isProcessing: isProcessing, processJobs: _processJobs)
          : null,
      backgroundColor: Colors.black,
    );
  }
}
