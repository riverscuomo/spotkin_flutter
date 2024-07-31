import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' hide Image;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class Utils {
  static String extractPlaylistId(String playlistUrl) {
    Uri uri = Uri.parse(playlistUrl);

    if (uri.host != 'open.spotify.com' ||
        !uri.pathSegments.contains('playlist')) {
      throw FormatException('Invalid Spotify playlist URL');
    }

    String playlistId = uri.pathSegments.last;
    return playlistId;
  }

  static Widget getPlaylistImageOrIcon(PlaylistSimple playlist) {
    return playlist.images?.isNotEmpty ??
            playlist.images?.last.url?.isNotEmpty == true
        ? Image.network(playlist.images?.last.url ?? '')
        : const Icon(Icons.music_note);
  }

  static Future<void> myLaunch(String url) async {
    print('Launching URL: $url');
    final uri = Uri.parse(url);
    if (await url_launcher.canLaunchUrl(uri)) {
      await url_launcher.launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  static void showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  static String? validateSpotifyPlaylistInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a Spotify playlist link or ID';
    }

    // Regex for Spotify playlist link
    final linkRegex =
        RegExp(r'^https:\/\/open\.spotify\.com\/playlist\/[a-zA-Z0-9]{22}');
    // Regex for Spotify playlist ID
    final idRegex = RegExp(r'^[a-zA-Z0-9]{22}$');

    if (linkRegex.hasMatch(value) || idRegex.hasMatch(value)) {
      return null; // Valid input
    } else {
      return 'Invalid Spotify playlist link or ID';
    }
  }
}
