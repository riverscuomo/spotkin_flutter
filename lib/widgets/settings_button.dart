import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class SettingsButton extends StatelessWidget {
  final Job job;
  final int index;
  final Function(int, Job) updateJob;
  final Function(Job) addJob;

  const SettingsButton({
    Key? key,
    required this.job,
    required this.index,
    required this.updateJob,
    required this.addJob,
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
              index: index,
            ),
          ),
        );
      },
    );
  }
}
