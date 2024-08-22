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
        ],
      ),
    );
  }
}
