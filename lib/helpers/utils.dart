import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' hide Image;
import 'package:url_launcher/url_launcher.dart';

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

  static void launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
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
