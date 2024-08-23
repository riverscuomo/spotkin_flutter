import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:spotkin_flutter/helpers/utils.dart';

const gap = SizedBox(
  height: 2,
);

Future<void> _onOpen(String url) async {
  Utils.myLaunch(url);
}

List<Widget> buildInfoSheetContent(BuildContext context) {
  final theme = Theme.of(context);

  return [
    Text(
      '👋 Hi there! I\'m Spotkin, your personal music discovery assistant! 🎵',
      style: theme.textTheme.bodyLarge,
    ),
    gap,
    Text(
      'My mission is to help you discover lots of great music without the hassle of constant searching or relying solely on generic algorithms. 🎶',
      style: theme.textTheme.bodyMedium,
    ),
    gap,
    Text(
      'I combine the best of Spotify\'s algorithms and curated playlists, but YOU get the final say and fine-tuned control. No more overly obvious recommendations, too-popular songs, or tracks you know you don\'t like!',
      style: theme.textTheme.bodyMedium,
    ),
    gap,
    Text(
      'Every day, I update one of your Spotify playlists with carefully selected tracks from your other playlists and sources.🎧',
      style: theme.textTheme.bodyMedium,
    ),
    gap,
    Text(
      'I can run automatically... or you can activate me by clicking the "Update" button. ✨',
      style: theme.textTheme.bodyMedium,
    ),
    gap,
    Text(
      'I work best when drawing from a variety of sources, such as:',
      style: theme.textTheme.bodyMedium,
    ),
    Text(
      '• Dynamic playlists like "New Music Friday" or "Today\'s Top Hits"',
      style: theme.textTheme.bodyMedium,
    ),
    Text(
      '• Curated playlists like Rolling Stone\'s "fivehundredalbums"',
      style: theme.textTheme.bodyMedium,
    ),
    RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '• New releases from genres you love via the ',
            style: theme.textTheme.bodyMedium,
          ),
          TextSpan(
            text: 'new_albums script',
            style: TextStyle(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _onOpen('https://github.com/riverscuomo/new-albums');
              },
          ),
        ],
      ),
    ),
    Text(
      '• Your personal "Daily Mix" playlists and "Discover Weekly"',
      style: theme.textTheme.bodyMedium,
    ),
    gap,
    Text(
      'You can create a custom recipe for each playlist, choosing which sources to pull music from.',
      style: theme.textTheme.bodyMedium,
    ),
    gap,
    Text(
      'You have precise control over your music experience: you can include or exclude specific artists, tracks, genres, and even set energy levels. This increases the odds you only get music you\'ll love!',
      style: theme.textTheme.bodyMedium,
    ),
    gap,
    Text(
      'When you hit the "Update" button, I use your personalized recipe to refresh your playlists with fresh, tailored tunes!',
      style: theme.textTheme.bodyMedium,
    ),
    gap,
    Text(
      'Experience a constantly evolving, personalized music journey without the limitations of standard algorithms. Ready to discover your new favorite songs? Let\'s go! 🚀🎵',
      style: theme.textTheme.bodyMedium,
    ),
  ];
}

List<Widget> buildSettingsInfoSheetContent(BuildContext context) {
  final theme = Theme.of(context);

  return [
    Text(
      'You have precise control over your music experience: you can include or exclude specific artists, tracks, genres, and even set energy levels. This increases the odds you only get music you\'ll love!',
      style: theme.textTheme.bodyMedium,
    ),
  ];
}
