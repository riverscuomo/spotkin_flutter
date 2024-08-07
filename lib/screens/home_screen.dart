import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';
import 'package:spotkin_flutter/widgets/home_job_widget.dart';

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

  void _refreshJobs() {
    _loadJobs();
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: widgetPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  DefaultTabController(
                    length: jobsIterable.length + 1,
                    child: Column(children: [
                      Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelStyle: Theme.of(context).textTheme.labelMedium,
                          tabs: [
                            ...jobsIterable.map((entry) {
                              return Tab(
                                child: Text(
                                  entry.value.targetPlaylist.name ?? 'New job',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                              );
                            }),
                            Tab(
                              child: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {},
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.9,
                        child: TabBarView(
                          children: [
                            ...jobsIterable.map((jobEntry) {
                              return HomeJobWidget(
                                  job: jobEntry.value,
                                  index: jobEntry.key,
                                  jobs: jobs,
                                  processJobs: _processJobs,
                                  onJobUpdate: (j) {
                                    updateJob(jobEntry.key, j);
                                  });
                            }),
                            Container(),
                          ],
                        ),
                      ),
                    ]),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
