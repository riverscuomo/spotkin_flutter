import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class SettingsButton extends StatelessWidget {
  final List<Job> jobs;
  final Function(int, Job) updateJob;
  final Function() onJobsImported;

  const SettingsButton({
    Key? key,
    required this.jobs,
    required this.updateJob,
    required this.onJobsImported,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingsScreen(
              jobs: jobs,
              updateJob: updateJob,
              onJobsImported: onJobsImported,
            ),
          ),
        );
      },
    );
  }
}
