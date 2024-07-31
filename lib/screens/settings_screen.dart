import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class SettingsScreen extends StatelessWidget {
  final List<Job> jobs;
  final Function(int, Job) updateJob;

  const SettingsScreen({Key? key, required this.jobs, required this.updateJob})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        // actions: [],
      ),
      body: ListView.builder(
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          return SettingsCard(
            index: index,
            job: jobs[index],
            updateJob: updateJob,
          );
        },
      ),
    );
  }
}
