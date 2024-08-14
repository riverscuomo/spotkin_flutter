import 'package:flutter/material.dart';

class UpdateButton extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onPressed;
  final bool isProcessing;

  const UpdateButton({
    super.key,
    this.imageUrl,
    required this.onPressed,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, minHeight: 48),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        icon: SizedBox(
          width: 30,
          height: 30,
          child: Center(
            child: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : CircleAvatar(
                    radius: 15,
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
        label: SizedBox(
          width: 82, // Fixed width for the label
          child: Center(
            child: Text(
              isProcessing ? 'Processing...' : 'Update',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return const Icon(
      Icons.music_note,
      color: Colors.white,
    );
  }
}

// class UpdateButton extends StatelessWidget {
//   const UpdateButton({
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
