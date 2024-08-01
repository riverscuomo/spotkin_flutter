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
                maxWidth: 300, // Adjust this value as needed
                minHeight: 50,
              ),
              child: ElevatedButton(
                onPressed: isProcessing ? null : processJobs,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50), // Minimum size
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(
                  isProcessing ? 'Processing...' : 'Update Spotkin On Spotify',
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
