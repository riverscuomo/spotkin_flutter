
class Utils {
  static String? validateSpotifyPlaylistInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a Spotify playlist link or ID';
    }
    
    // Regex for Spotify playlist link
    final linkRegex = RegExp(r'^https:\/\/open\.spotify\.com\/playlist\/[a-zA-Z0-9]{22}');
    // Regex for Spotify playlist ID
    final idRegex = RegExp(r'^[a-zA-Z0-9]{22}$');
    
    if (linkRegex.hasMatch(value) || idRegex.hasMatch(value)) {
      return null; // Valid input
    } else {
      return 'Invalid Spotify playlist link or ID';
    }
  }
}
