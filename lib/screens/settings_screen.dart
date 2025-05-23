import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotkin_flutter/app_core.dart';
import '../widgets/debug_label_wrapper.dart';

class SettingsScreen extends StatelessWidget {
  final int index;

  SettingsScreen({
    super.key,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Algorithm'),
        actions: const [SettingsInfoButton()],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 16),
                SettingsCard(
                  index: index,
                ).withDebugLabel('SettingsCard'),
              ],
            ).withDebugLabel('SettingsListView'),
          ),
          const SizedBox(height: 16),
        ],
      ).withDebugLabel('SettingsColumn'),
    ).withDebugLabel('SettingsScaffold');
  }
}
