import 'package:flutter/material.dart';

class SpotifyButton extends StatelessWidget {
  const SpotifyButton({
    super.key,
    required this.isProcessing,
    required this.processJobs,
  });

  final bool isProcessing;
  final void Function() processJobs;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 200,
        minHeight: 38,
      ),
      child: ElevatedButton(
        onPressed: isProcessing ? null : processJobs,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(90, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Text(
          isProcessing ? 'Processing...' : 'Update',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
