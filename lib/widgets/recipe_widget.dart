import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

import 'ingredient_row.dart';

class RecipeWidget extends StatefulWidget {
  final List<Ingredient> initialIngredients;
  final Function(List<Ingredient>) onIngredientsChanged;
  final List<Job> jobs;
  final Function(int, Job) updateJob;

  const RecipeWidget({
    Key? key,
    required this.initialIngredients,
    required this.onIngredientsChanged,
    required this.jobs,
    required this.updateJob,
  }) : super(key: key);

  @override
  _RecipeWidgetState createState() => _RecipeWidgetState();
}

class _RecipeWidgetState extends State<RecipeWidget> {
  late List<IngredientRow> _ingredientRows;
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
      row.quantityController.dispose();
    }
    super.dispose();
  }

  void _initIngredientRows() {
    _ingredientRows = widget.initialIngredients
        .map((ingredient) => IngredientRow(
              quantityController:
                  TextEditingController(text: ingredient.quantity.toString()),
              playlist: ingredient.playlist,
            ))
        .toList();
  }

  @override
  void didUpdateWidget(RecipeWidget oldWidget) {
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

    storageService.updateJob(job.copyWith(
      recipe: [...job.recipe, newIngredient],
    ));
    setState(() {
      _ingredientRows.add(IngredientRow(
        playlist: playlist,
        quantityController: TextEditingController(),
      ));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientRows.removeAt(index);
      // _onFormChanged();
    });
  }

  Widget buildQuantityDropdown(IngredientRow row) {
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
          trailing: IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    jobs: widget.jobs,
                    updateJob: widget.updateJob,
                  ),
                ),
              );
            },
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
            IngredientRow row = entry.value;
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
