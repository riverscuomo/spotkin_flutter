import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> config;
  // final String accessToken;

  HomeScreen({
    required this.config,
    // required this.accessToken,
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

  @override
  void initState() {
    print('Home Screen: initState...');
    super.initState();
    // _verifyToken();
    // final accessToken = spotifyService.getAccessToken();

    _storageService = StorageService();
    _initializeSpotify();
    _initialApiService();
    _loadJobs();
  }
  //  _apiService = ApiService(
  //     accessToken: accessToken ?? '',
  //     backendUrl: widget.config['backendUrl'],
  //   );

  void _initialApiService() async {
    final accessToken = await spotifyService.getAccessToken();
    _apiService = ApiService(
      accessToken: accessToken ?? '',
      backendUrl: widget.config['backendUrl'],
    );
  }

  Future<void> _initializeSpotify() async {
    await spotifyService.initializeSpotify();
    // Now you can use _spotifyService.spotify
  }

  Future<void> _verifyToken() async {
    try {
      final user = await spotifyService.checkAuthentication();
      print('Home Screen: Home screen: Token is valid');
    } catch (e) {
      print('Home Screen: Token verification failed: $e');
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
        print('Home Screen: Error processing jobs: $result');
        if (result.startsWith("Status 401")) {
          print('Home Screen: Token expired, authenticate again...');
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
      _storageService.saveJobs(jobs);
    });
  }

  void _addNewJob(Job newJob) {
    setState(() {
      jobs.add(newJob);
      _storageService.saveJobs(jobs);
    });
  }

  Widget _buildPlaylistSelectionOptions() {
    return PlaylistSelectionOptions(
      onPlaylistSelected: (PlaylistSimple selectedPlaylist) {
        final newJob = Job(
          targetPlaylist: selectedPlaylist,
        );
        _addNewJob(newJob);
      },
    );
  }

  Widget _buildCreateJobForm() {
    return CreateJobForm(
      onSubmit: (Job newJob) {
        _addNewJob(newJob);
      },
    );
  }

  Widget _buildRecipeCard(Job job, int index) {
    if (job.recipe.isEmpty) {
      print('Home Screen: Job ${job.targetPlaylist.name}  recipe is empty');
      // return const SizedBox();
    } else {
      print(
          'Job ${job.targetPlaylist.name} recipe first ingredient before passing to widget: ${job.recipe[0].playlist.id} ${job.recipe[0].quantity}');
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IngredientForm(
              initialIngredients: job.recipe,
              // fetchPlaylistName: _fetchPlaylistName,
              onIngredientsChanged: (updatedIngredients) {
                setState(() {
                  job = job.copyWith(recipe: updatedIngredients);
                  updateJob(index, job);
                });
              },
            )
          ],
        ),
      ),
    );
  }

  // Future<String> _fetchPlaylistName(String playlistId) async {
  //   try {
  //     final playlist = await spotifyService.getPlaylistDetails(playlistId);
  //     return playlist.name ?? 'Unknown Playlist';
  //   } catch (e) {
  //     print('Home Screen: Error fetching playlist name: $e');
  //     return 'Unknown Playlist';
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final job = jobs.isEmpty ? Job.empty() : jobs[0];
    final spotifyService = getIt<SpotifyService>();
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
                  builder: (context) =>
                      SettingsScreen(jobs: jobs, updateJob: updateJob),
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  jobs.isEmpty
                      // ? _buildCreateJobForm()
                      ? _buildPlaylistSelectionOptions()
                      : TextFormField(
                          initialValue: job.targetPlaylist.name,
                          // decoration: const InputDecoration(
                          //     labelText: 'Target playlist link'),
                          onChanged: (value) async {
                            final targetPlaylist =
                                await spotifyService.fetchPlaylist(value);
                            updateJob(
                              0,
                              job.copyWith(targetPlaylist: targetPlaylist),
                            );
                          },
                        ),
                  const SizedBox(height: 20),
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
                          subtitle: Text(result['result']),
                          leading: Icon(
                            result['status'] == 'Success'
                                ? Icons.check_circle
                                : Icons.error,
                            color: result['status'] == 'Success'
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                      }),
                    ]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: jobs.isNotEmpty && jobs[0].recipe.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: isProcessing ? null : _processJobs,
                child: Text(isProcessing
                    ? 'Processing...'
                    : 'Update Spotkin On Spotify'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            )
          : null,
      backgroundColor: Colors.black,
    );
  }
}
