import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class SettingsScreen extends StatelessWidget {
  final List<Job> jobs;
  final Function(int, Job) updateJob;
  final StorageService storageService = StorageService();
  late final BackupService backupService;
  final VoidCallback onJobsImported;

  SettingsScreen({
    Key? key,
    required this.jobs,
    required this.updateJob,
    required this.onJobsImported,
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
    onJobsImported();
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
              ElevatedButton.icon(
                icon: const Icon(Icons.backup),
                label: const Text('Create Backup'),
                onPressed: () => _createBackup(context),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text('Import Backup'),
                onPressed: () => _importBackup(context),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
