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
    return SizedBox(
      width: 100, // Fixed width
      height: 40, // Fixed height
      child: ElevatedButton(
        onPressed: isProcessing ? null : processJobs,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          isProcessing ? 'Processing...' : 'Update',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
