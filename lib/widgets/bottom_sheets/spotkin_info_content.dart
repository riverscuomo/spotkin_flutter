import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const gap = SizedBox(
  height: 5,
);

Future <void>
_onOpen(String url) async{
  Utils.myLaunch(url);
}

final infoSheetContent = [
  Text(
      '👋 Hi there! I\'m Spotkin, your personal music discovery assistant! 🎵'),
  gap,
  Text(
      'My mission is to help you discover lots of great music without the hassle of constant searching or relying solely on generic algorithms. 🎶'),
  gap,
  Text(
      'I combine the best of Spotify\'s algorithms and curated playlists, but YOU get the final say and fine-tuned control. No more overly obvious recommendations, too-popular songs, or tracks you know you don\'t like!'),
  gap,
  Text(
      'Every day, I update one of your Spotify playlists with carefully selected tracks from your other playlists and sources.🎧'),
  gap,
  Text(
      'I can run automatically... or you can activate me by clicking the "Update Spotkin On Spotify" button. ✨'),
  gap,
  Text('I work best when drawing from a variety of sources, such as:'),
  Text('• Dynamic playlists like "New Music Friday" or "Today\'s Top Hits"'),
  Text('• Curated playlists like Rolling Stone\'s "fivehundredalbums"'),
  RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: '• New releases from genres you love via the ',
          ),
          TextSpan(
            text: 'new_albums script',
            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
          ..onTap = () {
           _onOpen('https://github.com/riverscuomo/new-albums'); 
          }, 
        ),
      ],
    ),
  ),
  Text('• Your personal "Daily Mix" playlists and "Discover Weekly"'),
  gap,
  Text(
      'You can create a custom recipe for each playlist, choosing which sources to pull music from.'),
  gap,
  Text(
      'You have precise control over your music experience: you can include or exclude specific artists, tracks, genres, and even set energy levels. This increases the odds you only get music you\'ll love!'),
  gap,
  Text(
      'When you hit the "Update" button, I use your personalized recipe to refresh your playlists with fresh, tailored tunes!'),
  gap,
  Text(
      'Experience a constantly evolving, personalized music journey without the limitations of standard algorithms. Ready to discover your new favorite songs? Let\'s go! 🚀🎵'),
];
