// import 'package:flutter/material.dart';
// import 'package:spotify/spotify.dart' hide Image;
// import 'package:spotkin_flutter/app_core.dart';

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({
//     Key? key,
//   }) : super(key: key);

//   @override
//   _SearchScreenState createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   final SpotifyService spotifyService = getIt<SpotifyService>();
//   List<dynamic> allSearchResults = [];
//   List<dynamic> filteredResults = [];
//   bool isLoading = false;
//   String selectedFilter = 'All';

//   final List<String> filters = ['All', 'Tracks', 'Artists', 'Playlists'];

//   void _performSearch() async {
//     final query = _searchController.text;
//     if (query.isEmpty) return;

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       print('Initiating search for query: $query');
//       final results = await spotifyService.search(query, types: [
//         SearchType.track,
//         SearchType.artist,
//         SearchType.playlist,
//       ]);
//       print('Search completed. Processing results...');

//       setState(() {
//         allSearchResults = results;
//         _filterResults();
//         isLoading = false;
//       });

//       print('Number of results: ${allSearchResults.length}');
//     } catch (e) {
//       print('Error performing search: $e');
//       setState(() {
//         isLoading = false;
//       });
//       // You might want to show an error message to the user here
//     }
//   }

//   void _filterResults() {
//     switch (selectedFilter) {
//       case 'Tracks':
//         filteredResults = allSearchResults.whereType<Track>().toList();
//         break;
//       case 'Artists':
//         filteredResults = allSearchResults.whereType<Artist>().toList();
//         break;
//       case 'Playlists':
//         filteredResults = allSearchResults.whereType<PlaylistSimple>().toList();
//         break;
//       default:
//         filteredResults = allSearchResults;
//     }
//   }

//   Widget _buildFilterPill(String filter) {
//     bool isSelected = filter == selectedFilter;

//     Map<String, Color> colors = {
//       'All': Colors.orange,
//       'Tracks': Colors.red,
//       'Artists': Colors.orange,
//       'Playlists': Colors.green
//     };

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 4),
//       child: FilterChip(
//         label: Text(filter),
//         selected: isSelected,
//         onSelected: (bool selected) {
//           setState(() {
//             selectedFilter = filter;
//             _filterResults();
//           });
//         },
//         backgroundColor: Colors.grey[300],
//         selectedColor: colors[filter],
//         labelStyle: TextStyle(
//           color: isSelected ? Colors.white : Colors.black,
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }

//   Widget _buildListItem(dynamic item) {
//     String title = 'Unknown';
//     String subtitle = 'Unknown Type';
//     String? imageUrl = '';
//     bool isArtist = false;

//     if (item is Track) {
//       title = item.name ?? 'Unknown Track';
//       subtitle =
//           '${item.artists?.isNotEmpty == true ? item.artists!.first.name : 'Unknown Artist'} • Track';
//       imageUrl = item.album?.images?.isNotEmpty == true
//           ? item.album!.images!.first.url
//           : '';
//     } else if (item is Artist) {
//       title = item.name ?? 'Unknown Artist';
//       subtitle = 'Artist';
//       imageUrl = item.images?.isNotEmpty == true ? item.images!.first.url : '';
//       isArtist = true;
//     } else if (item is PlaylistSimple) {
//       title = item.name ?? 'Unknown PlaylistSimple';
//       subtitle = 'PlaylistSimple • ${item.tracksLink?.total ?? 0} tracks';
//       imageUrl = item.images?.isNotEmpty == true ? item.images!.first.url : '';
//     }

//     Widget leadingWidget;
//     if (imageUrl!.isNotEmpty) {
//       if (isArtist) {
//         leadingWidget = CircleAvatar(
//           radius: 25,
//           backgroundImage: NetworkImage(imageUrl),
//           onBackgroundImageError: (exception, stackTrace) {
//             print('Error loading image: $exception');
//           },
//           child: Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.white, width: 2),
//             ),
//           ),
//         );
//       } else {
//         leadingWidget = ClipRRect(
//           borderRadius: BorderRadius.circular(4),
//           child: Image.network(
//             imageUrl,
//             width: 50,
//             height: 50,
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) =>
//                 Icon(Icons.music_note, size: 50),
//           ),
//         );
//       }
//     } else {
//       leadingWidget = Icon(Icons.music_note, size: 50);
//     }

//     return ListTile(
//       leading: leadingWidget,
//       title: Text(title),
//       subtitle: Text(subtitle),
//       trailing: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           item is PlaylistSimple || item is Artist
//               ? IconButton(
//                   icon: Icon(Icons.add, color: Colors.green),
//                   onPressed: () {
//                     // TODO: Implement add functionality
//                     print('Add pressed for: $title');
//                   },
//                 )
//               : SizedBox(),
//           item is Track || item is Artist
//               ? IconButton(
//                   icon: Icon(Icons.remove, color: Colors.red),
//                   onPressed: () {
//                     // TODO: Implement remove functionality
//                     print('Remove pressed for: $title');
//                   },
//                 )
//               : SizedBox(),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Spotify Search'),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search Spotify',
//                 suffixIcon: IconButton(
//                   icon: Icon(Icons.search),
//                   onPressed: _performSearch,
//                 ),
//               ),
//               onSubmitted: (_) => _performSearch(),
//             ),
//           ),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: filters.map(_buildFilterPill).toList(),
//             ),
//           ),
//           Expanded(
//             child: isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : ListView.builder(
//                     itemCount: filteredResults.length,
//                     itemBuilder: (context, index) =>
//                         _buildListItem(filteredResults[index]),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
