import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class SpotifyButton extends StatefulWidget {
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
  _SpotifyButtonState createState() => _SpotifyButtonState();
}

class _SpotifyButtonState extends State<SpotifyButton> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _audioPlayer.setSource(AssetSource('sounds/update_button_sound.mp3'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handlePress() async {
    if (!widget.isProcessing) {
      await _audioPlayer.play(AssetSource('sounds/update_button_sound.mp3'));
      widget.processJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150, minHeight: 48),
      child: ElevatedButton.icon(
        onPressed: widget.isProcessing ? null : _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        icon: SizedBox(
          width: 30,
          height: 30,
          child: Center(
            child: widget.isProcessing
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
                    backgroundImage: widget.imageUrl != null
                        ? NetworkImage(widget.imageUrl!)
                        : null,
                    backgroundColor: Colors.green[400],
                    child: widget.imageUrl == null
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
              widget.isProcessing ? 'Processing...' : 'Update',
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
