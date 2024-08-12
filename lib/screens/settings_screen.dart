import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class SettingsScreen extends StatelessWidget {
  final Job job;
  final int index;
  final Function(int, Job) updateJob;
  final Function(Job) addJob;
  final StorageService storageService = StorageService();
  late final BackupService backupService;
  final VoidCallback onJobsImported;

  SettingsScreen({
    super.key,
    required this.job,
    required this.index,
    required this.updateJob,
    required this.addJob,
    required this.onJobsImported,
  }) {
    backupService = BackupService(storageService, addJob, updateJob);
  }

  void _createBackup(BuildContext context) {
    backupService.createBackup();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Backup file created. Check your downloads.')),
    );
  }

  Future<void> _importBackup(BuildContext context) async {
    await backupService.importBackup();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup imported and jobs updated.')),
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
            child: ListView(
              children: [
                const SizedBox(height: 16),
                SettingsCard(
                  index: index,
                  job: job,
                  updateJob: updateJob,
                ),
              ],
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
