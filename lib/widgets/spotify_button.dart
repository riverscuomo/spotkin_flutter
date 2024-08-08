import 'package:flutter/material.dart';

class SpotifyButton extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final VoidCallback onPressed;
  final bool isProcessing;
  final void Function() processJobs;

  const SpotifyButton({
    Key? key,
    this.imageUrl,
    this.size = 48,
    required this.onPressed,
    required this.isProcessing,
    required this.processJobs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : processJobs,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green[400],
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              // offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: isProcessing
              ? const Text('...')
              : Image.asset(
                  'assets/images/updatespotkinbutton.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultIcon(),
                ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      color: Colors.green[400],
      child: Icon(
        Icons.music_note,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}

// class SpotifyButton extends StatelessWidget {
//   const SpotifyButton({
//     super.key,
//     required this.isProcessing,
//     required this.processJobs,
//   });

//   final bool isProcessing;
//   final void Function() processJobs;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 100, // Fixed width
//       height: 40, // Fixed height
//       child: ElevatedButton(
//         onPressed: isProcessing ? null : processJobs,
//         style: ElevatedButton.styleFrom(
//           padding: EdgeInsets.zero,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//         ),
//         child: Text(
//           isProcessing ? 'Processing...' : 'Update',
//           textAlign: TextAlign.center,
//         ),
//       ),
//     );
//   }
// }
