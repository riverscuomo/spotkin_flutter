import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class SettingsScreen extends StatelessWidget {
  final List<Job> jobs;
  final Function(int, Job) updateJob;
  final StorageService storageService = StorageService();
  late final BackupService backupService;

  SettingsScreen({
    Key? key,
    required this.jobs,
    required this.updateJob,
  }) : super(key: key) {
    backupService = BackupService(storageService);
  }

  void _createBackup(BuildContext context) {
    backupService.createBackup();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup file created. Check your downloads.')),
    );
  }

  Future<void> _importBackup(BuildContext context) async {
    await backupService.importBackup();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backup imported and jobs updated.')),
    );
    // You might want to refresh the jobs list here or in the parent widget
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [InfoButton()],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                return SettingsCard(
                  index: index,
                  job: jobs[index],
                  updateJob: updateJob,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _createBackup(context),
                child: const Text('Create Backup'),
              ),
              ElevatedButton(
                onPressed: () => _importBackup(context),
                child: const Text('Import Backup'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
