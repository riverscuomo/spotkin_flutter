import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

import 'ingredient_form_row.dart';
import 'spotify_style_playlist_tile.dart';

class IngredientForm extends StatefulWidget {
  final List<Ingredient> initialIngredients;
  final Function(List<Ingredient>) onIngredientsChanged;
  // final Future<String> Function(String playlistId) getPlaylistName;

  const IngredientForm({
    Key? key,
    required this.initialIngredients,
    required this.onIngredientsChanged,
    // required this.getPlaylistName,
  }) : super(key: key);

  @override
  _IngredientFormState createState() => _IngredientFormState();
}

class _IngredientFormState extends State<IngredientForm> {
  // final _formKey = GlobalKey<FormState>();
  late List<IngredientFormRow> _ingredientRows;
  // bool _hasChanges = false;
  // bool _isSubmitting = false;
  final SpotifyService spotifyService = getIt<SpotifyService>();
  final StorageService storageService = getIt<StorageService>();

  @override
  void initState() {
    super.initState();
    _initIngredientRows();
  }

  @override
  void dispose() {
    for (var row in _ingredientRows) {
      // row.playlistController.removeListener(_onFormChanged);
      // row.quantityController.removeListener(_onFormChanged);
      // row.playlistController.dispose();
      row.quantityController.dispose();
    }
    super.dispose();
  }

  // bool get _hasEmptyRow => _ingredientRows.any((row) =>
  //     // row.playlistController.text.isEmpty &&
  //     row.quantityController.text.isEmpty);

  void _initIngredientRows() {
    _ingredientRows = widget.initialIngredients
        .map((ingredient) => IngredientFormRow(
              // playlistController:
              //     TextEditingController(text: ingredient.playlist.name),
              quantityController:
                  TextEditingController(text: ingredient.quantity.toString()),
              playlist: ingredient.playlist,
            ))
        .toList();
    // if (_ingredientRows.isEmpty) {
    //   _addNewRow();
    // }
    // _setupControllerListeners();
  }

  // void _setupControllerListeners() {
  //   for (var row in _ingredientRows) {
  //     row.playlistController.addListener(_onFormChanged);
  //     row.quantityController.addListener(_onFormChanged);
  //   }
  // }

  // void _onFormChanged() {
  //   setState(() {
  //     _hasChanges = true;
  //   });
  // }

  @override
  void didUpdateWidget(IngredientForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIngredients != oldWidget.initialIngredients) {
      _initIngredientRows();
    }
  }

  void _addNewRow(PlaylistSimple playlist, Job job) {
    Ingredient newIngredient = Ingredient(
      playlist: playlist,
      quantity: 5,
    );

    // final job = storageService.getJobByPlaylistId(playlist.id!);

    // if (job == null) {
    //   print(
    //       'No Job found with playlist name: ${playlist.id} #${playlist.name}');
    //   // show a snackbar

    //   Utils.showSnackbar(context, 'Job not found for playlist: ${playlist.id}');
    //   return;
    // }
    storageService.updateJob(job.copyWith(
      recipe: [...job.recipe, newIngredient],
    ));
    setState(() {
      _ingredientRows.add(IngredientFormRow(
        playlist: playlist,
        // playlistController: TextEditingController(),
        quantityController: TextEditingController(),
      ));
      // _setupControllerListeners();
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientRows.removeAt(index);
      // _onFormChanged();
    });
  }

  // Future<void> _submitForm() async {
  //   if (_formKey.currentState!.validate()) {
  //     setState(() {
  //       _isSubmitting = true;
  //     });

  //     try {
  //       // Process only the last (newest) ingredient row
  //       IngredientFormRow lastRow = _ingredientRows.last;

  //       if (lastRow.playlistController.text.isNotEmpty &&
  //           lastRow.quantityController.text.isNotEmpty) {
  //         String playlistId =
  //             Utils.extractPlaylistId(lastRow.playlistController.text);

  //         final playlist = await spotifyService.getPlaylist(playlistId);
  //         // String playlistName = playlist.name ?? 'Unknown Playlist';

  //         Ingredient newIngredient = Ingredient(
  //           // playlistName: playlistName,
  //           // playlistId: playlistId,
  //           playlist: playlist,
  //           quantity: int.tryParse(lastRow.quantityController.text) ?? 0,
  //         );

  //         // Update the row with the fetched playlist name
  //         setState(() {
  //           // lastRow.playlistName = playlistName;
  //           lastRow.playlist = playlist;
  //           // Add the new ingredient to the list
  //           widget.onIngredientsChanged(
  //               [...widget.initialIngredients, newIngredient]);
  //         });
  //       }

  //       setState(() {
  //         _hasChanges = false;
  //         _isSubmitting = false;
  //         // Add a new empty row for the next ingredient
  //         _addNewRow();
  //       });
  //     } catch (e) {
  //       // Handle any errors that occurred during playlist fetching
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error fetching playlist details: $e')),
  //       );
  //       setState(() {
  //         _isSubmitting = false;
  //       });
  //     }
  //   }
  // }

  Widget buildQuantityDropdown(IngredientFormRow row) {
    return SizedBox(
      width: 80, // Adjust the width as needed
      child: DropdownButtonFormField<int>(
        value: int.tryParse(row.quantityController.text) ?? 5,
        items: List.generate(21, (index) {
          return DropdownMenuItem<int>(
            value: index,
            child: Text(index.toString()),
          );
        }),
        onChanged: (value) {
          row.quantityController.text = value.toString();
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a quantity';
          }
          return null;
        },
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(
            Icons.add,
          ),
          title: const Text(
            'Add',
          ),
          onTap: () async {
            showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return SearchBottomSheet(
                    onItemSelected: (dynamic item) {
                      if (item is PlaylistSimple) {
                        _addNewRow(item, storageService.getJobs().first);
                      }
                    },
                    searchTypes: const [SearchType.playlist],
                  );
                });
          },
        ),
        if (_ingredientRows.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Let's start building your Spotkin",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._ingredientRows.asMap().entries.map((entry) {
            IngredientFormRow row = entry.value;
            final playlist = row.playlist;
            if (playlist == null) {
              return const SizedBox.shrink();
            }
            return SpotifyStylePlaylistTile(
                playlist: row.playlist!,
                trailingButton: buildQuantityDropdown(row),
                onTileTapped: () async {
                  // update the job.recipe
                  //  String playlistName = playlist.name ?? 'Unknown Playlist';

                  // // Update the row with the fetched playlist name
                  // setState(() {
                  //   // lastRow.playlistName = playlistName;
                  //   // lastRow.playlist = playlist;
                  //   // Add the new ingredient to the list
                  //   widget.onIngredientsChanged(
                  //       [...widget.initialIngredients, newIngredient]);
                  // });
                }

                // setState(() {
                //   _hasChanges = false;
                //   _isSubmitting = false;
                //   // Add a new empty row for the next ingredient
                //   _addNewRow();
                // });

                // },
                );
          }),
        // const SizedBox(height: 10),
        // if (_hasChanges &&
        //     _ingredientRows.isNotEmpty &&
        //     // _ingredientRows.last.playlistController.text.isNotEmpty &&
        //     _ingredientRows.last.quantityController.text.isNotEmpty)
        //   // ElevatedButton(
        //   //   onPressed: _isSubmitting ? null : _submitForm,
        //   //   child: _isSubmitting
        //   //       ? const CircularProgressIndicator()
        //   //       : const Text('Submit'),
        //   // ),
      ],
    );
  }
}
