// import 'dart:convert';
// import 'dart:html' as html;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:spotify/spotify.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Spotify Auth Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//       ),
//       home: SpotifyAuthPage(),
//     );
//   }
// }

// class SpotifyAuthPage extends StatefulWidget {
//   @override
//   _SpotifyAuthPageState createState() => _SpotifyAuthPageState();
// }

// class _SpotifyAuthPageState extends State<SpotifyAuthPage> {
//   SpotifyApiCredentials? credentials;
//   String? spotifyRedirectUri;
//   SpotifyApi? spotify;
//   String? userInfo;
//   bool isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     loadConfig().then((_) {
//       final currentUri = Uri.parse(html.window.location.href);
//       if (currentUri.hasQuery && currentUri.queryParameters.containsKey('code')) {
//         handleAuthResponse(currentUri);
//       }
//     });
//   }

//   Future<void> loadConfig() async {
//     final configString = await rootBundle.loadString('assets/config.json');
//     final config = json.decode(configString);
//     credentials = SpotifyApiCredentials(
//       config['SPOTIFY_CLIENT_ID'],
//       config['SPOTIFY_CLIENT_SECRET'],
//     );
//     spotifyRedirectUri = config['SPOTIFY_REDIRECT_URI'];
//   }

//   Future<void> authenticateWithSpotify() async {
//     setState(() {
//       isLoading = true;
//     });

//     final grant = SpotifyApi.authorizationCodeGrant(credentials!);

//     final authUri = grant.getAuthorizationUrl(
//       Uri.parse(spotifyRedirectUri!),
//       scopes: ['user-read-email', 'user-read-private'],
//     );

//     html.window.location.href = authUri.toString();
//   }

//   Future<void> handleAuthResponse(Uri responseUri) async {
//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final grant = SpotifyApi.authorizationCodeGrant(credentials!);
//       spotify = SpotifyApi.fromAuthCodeGrant(grant, responseUri.toString());
//       print(spotify.)

//       // // Fetch user info
//       // final user = await spotify!.me.get();
//       // setState(() {
//       //   userInfo = 'Logged in as: ${user.email} (${user.displayName})';
//       //   isLoading = false;
//       // });

//       // Clear the URL parameters
//       html.window.history.pushState(null, '', '/');
//     } catch (e) {
//       setState(() {
//         userInfo = 'Error during authentication: $e';
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Spotify Auth Demo'),
//       ),
//       body: Center(
//         child: isLoading
//             ? CircularProgressIndicator()
//             : userInfo != null
//                 ? Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(userInfo!),
//                       ElevatedButton(
//                         onPressed: () {
//                           setState(() {
//                             spotify = null;
//                             userInfo = null;
//                           });
//                         },
//                         child: Text('Logout'),
//                       ),
//                     ],
//                   )
//                 : ElevatedButton(
//                     onPressed: authenticateWithSpotify,
//                     child: Text('Login with Spotify'),
//                   ),
//       ),
//     );
//   }
// }
