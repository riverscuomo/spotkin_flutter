import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotkin_flutter/app_core.dart';

class SettingsScreen extends StatelessWidget {
  final int index;
  final StorageService storageService = StorageService();
  late final BackupService backupService;

  SettingsScreen({
    super.key,
    required this.index,
  });

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
    Provider.of<JobProvider>(context, listen: false).loadJobs();
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);

    // Initialize backupService here to have access to the context
    backupService = BackupService(
      storageService,
      jobProvider.addJob,
      jobProvider.updateJob,
    );

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
