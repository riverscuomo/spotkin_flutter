import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class UpdateButton extends StatefulWidget {
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
  _UpdateButtonState createState() => _UpdateButtonState();
}

class _UpdateButtonState extends State<UpdateButton> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // _audioPlayer.setSource(AssetSource('sounds/baby_giggle.mp3'));
    // Set initial volume (0.0 to 1.0)
    _audioPlayer.setVolume(0.2);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _handlePress() async {
    if (!widget.isProcessing) {
      await _audioPlayer.play(AssetSource('sounds/baby_giggle.mp3'));
      widget.onPressed();
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
          width: 85, // Fixed width for the label
          child: Center(
            child: Text(
              widget.isProcessing ? 'Processing...' : 'Go!',
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
