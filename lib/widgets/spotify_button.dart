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
    return Container(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 300,
                minHeight: 40,
              ),
              child: ElevatedButton(
                onPressed: isProcessing ? null : processJobs,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(
                  isProcessing ? 'Processing...' : 'Update',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
