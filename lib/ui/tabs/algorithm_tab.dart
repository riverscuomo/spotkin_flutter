import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class AlgorithmTab extends StatelessWidget {
  final int index;

  const AlgorithmTab({
    Key? key,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Algorithm Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          // Use the existing SettingsCard that already works
          SettingsCard(index: index),
        ],
      ),
    );
  }
}
