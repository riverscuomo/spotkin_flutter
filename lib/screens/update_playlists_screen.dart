import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';


class UpdatePlaylistsScreen extends StatefulWidget {
  final String accessToken;
  final String backendUrl;

  UpdatePlaylistsScreen({
    required this.accessToken,
    required this.backendUrl,
  });

  @override
  _UpdatePlaylistsScreenState createState() => _UpdatePlaylistsScreenState();
}

class _UpdatePlaylistsScreenState extends State<UpdatePlaylistsScreen> {
  List<Job> jobs = [];
  List<Map<String, dynamic>> jobResults = [];
  bool isProcessing = false;
  late ApiService _apiService;
  late StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      accessToken: widget.accessToken,
      backendUrl: widget.backendUrl,
    );
    _storageService = StorageService();
    _loadJobs();
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

    setState(() {
      jobResults = results;
      isProcessing = false;
    });
  }

  void updateJob(int index, Job updatedJob) {
  print("Updating job at index $index: ${updatedJob.name}");
  print("Recipe count: ${updatedJob.recipe.length}");
  for (var ingredient in updatedJob.recipe) {
    print("Ingredient: ${ingredient.sourcePlaylistId}, Quantity: ${ingredient.quantity}");
  }
  setState(() {
    jobs[index] = updatedJob;
    _storageService.saveJobs(jobs);
  });
  print("Jobs saved after update");
}

  void _addNewJob(Job newJob) {
    setState(() {
      jobs.add(newJob);
      _storageService.saveJobs(jobs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: jobs.isEmpty ? const Text('Create Your Spotkin') : const Text('Update Your Spotkin')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (jobs.isEmpty) _buildJobForm(),
              // else
              //   ElevatedButton(
              //     onPressed: () => _showAddJobDialog(context),
              //     child: const Text('Add New Job'),
              //   ),
              const SizedBox(height: 20),
              // Text('Existing Jobs', style: Theme.of(context).textTheme.headline6),
              jobs.isEmpty
                  ? 
                  
                  SizedBox()
                  // const Center(child: Text('No jobs yet. Create one above!'))
                  : Column(
                      children: [
                        ...jobs.asMap().entries.map((entry) {
                          return _buildRecipeCard(entry.value, entry.key);
                        }).toList(),
                        const SizedBox(height: 20),
                        ExpansionTile(
                          title: const Text('Settings'),
                          initiallyExpanded: false,
                          children: [
                            ...jobs.asMap().entries.map((entry) {
                              return SettingsCard(
                                index: entry.key,
                                job: entry.value,
                                updateJob: updateJob,
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
             jobs.isNotEmpty ? ElevatedButton(
                onPressed:  isProcessing ? null : _processJobs,
                child:
                    Text(isProcessing ? 'Processing...' : 'Update Spotkin On Spotify'),
              ) : SizedBox(),
              const SizedBox(height: 20),
              
              jobResults.isEmpty
                  ? 
                  SizedBox()
                  // const Center(child: Text('No jobs processed yet.'))
                  : Column(
                      children: [Text('Job Results', style: Theme.of(context).textTheme.headline6),
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
                      }).toList(),
                      ]
                    ),
            ],
          ),
        ),
      ),
    );
  }

 

  void _showAddJobDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Job'),
          content: SingleChildScrollView(
            child: JobForm(
              onSubmit: (Job newJob) {
                _addNewJob(newJob);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      },
    );
  }

   Widget _buildJobForm() {
    return JobForm(
      onSubmit: (Job newJob) {
        _addNewJob(newJob);
      },
    );
  }

  Widget _buildRecipeCard(Job job, int index) {
    if (job.recipe.isEmpty) {
      print('Job ${job.name}  recipe is empty');
    } else{
    print('Job ${job.name} recipe first ingredient before passing to widget: ${job.recipe[0].sourcePlaylistId} ${job.recipe[0].quantity}');}
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: job.name,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (value) =>
                  updateJob(index, job.copyWith(name: value)),
            ),
            TextFormField(
              initialValue: job.playlistId,
              decoration: const InputDecoration(labelText: 'Playlist link'),
              onChanged: (value) =>
                  updateJob(index, job.copyWith(playlistId: value)),
            ),
            IngredientManagementWidget(
              initialIngredients: job.recipe,
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

}
