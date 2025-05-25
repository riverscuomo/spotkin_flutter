import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  static String formatTime(int hour) {
    final time = DateTime(2023, 1, 1, hour, 0);
    final format = DateFormat.jm(); // This will use the local time format
    return format.format(time);
  }

  static int localToUtc(int localHour) {
    final now = DateTime.now();
    final localTime = DateTime(now.year, now.month, now.day, localHour);
    final utcTime = localTime.toUtc();
    return utcTime.hour;
  }

  static int utcToLocal(int utcHour) {
    final now = DateTime.now();
    final utcTime = DateTime.utc(now.year, now.month, now.day, utcHour);
    final localTime = utcTime.toLocal();
    return localTime.hour;
  }

  // static Widget getPlaylistImageOrIcon(
  //     PlaylistSimple playlist, int? imageIndex) {
  //   if (playlist.images?.isNotEmpty == true) {
  //     if (imageIndex != null && playlist.images!.length > imageIndex) {
  //       return Image.network(playlist.images![imageIndex].url ?? '');
  //     } else {
  //       return Image.network(playlist.images!.first.url ?? '');
  //     }
  //   } else {
  //     return const Icon(Icons.music_note);
  //   }
  // }

  static Future<void> myLaunch(String url) async {
    debugPrint('Launching URL: $url');
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
