import 'package:flutter/material.dart';

class SpotifyButton extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onPressed;
  final bool isProcessing;
  final void Function() processJobs;

  const SpotifyButton({
    Key? key,
    this.imageUrl,
    required this.onPressed,
    required this.isProcessing,
    required this.processJobs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 55, minHeight: 60),
      child: ElevatedButton(
        onPressed: isProcessing ? null : processJobs,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: isProcessing
                    ? const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : CircleAvatar(
                        radius: 25,
                        backgroundImage:
                            imageUrl != null ? NetworkImage(imageUrl!) : null,
                        backgroundColor: Colors.green[400],
                        child: imageUrl == null
                            ? Image.asset(
                                'assets/images/transparent_spotkin.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultIcon(),
                              )
                            : null,
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isProcessing ? '...' : 'Update',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return const Icon(
      Icons.music_note,
      color: Colors.white,
      size: 30,
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
