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

  void _addNewRow(PlaylistSimple playlist, Job job) {
    // Check if the playlist already exists in the recipe
    if (job.recipe.any((ingredient) => ingredient.playlist.id == playlist.id)) {
      // Show a snackbar or alert to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This playlist is already in the recipe')),
      );
      return;
    }

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

  Future<bool> _handleDismiss(DismissDirection direction, int index) async {
    if (direction == DismissDirection.endToStart) {
      // Right swipe: confirm and remove the ingredient
      bool confirmDelete = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Confirm Delete"),
                content: const Text(
                    "Are you sure you want to remove this playlist?"),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Delete"),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (confirmDelete) {
        _removeIngredient(index);
        return true;
      }
    } else if (direction == DismissDirection.startToEnd) {
      // Left swipe: set quantity to zero (archive)
      _updateJobInStorage(index, 0);
      setState(() {
        _ingredientRows[index].quantityController.text = '0';
      });
      // Show a snackbar to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playlist archived (quantity set to 0)')),
      );
    }
    return false; // Don't dismiss the item
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientRows.removeAt(index);
      final job = storageService.getJobs().first;
      final updatedRecipe = List<Ingredient>.from(job.recipe)..removeAt(index);
      final updatedJob = job.copyWith(recipe: updatedRecipe);
      storageService.updateJob(updatedJob);
    });
  }

  Widget buildQuantityDropdown(IngredientRow row, int index) {
    return SizedBox(
      width: 80,
      child: DropdownButtonFormField<int>(
        value: int.tryParse(row.quantityController.text) ?? 5,
        items: List.generate(21, (index) {
          return DropdownMenuItem<int>(
            value: index,
            child: Text(index.toString()),
          );
        }),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              row.quantityController.text = value.toString();
              _updateJobInStorage(index, value);
            });
          }
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

  void _updateJobInStorage(int index, int newQuantity) {
    final job = storageService.getJobs().first;
    final updatedRecipe = List<Ingredient>.from(job.recipe);
    updatedRecipe[index] = updatedRecipe[index].copyWith(quantity: newQuantity);

    final updatedJob = job.copyWith(recipe: updatedRecipe);
    storageService.updateJob(updatedJob);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(
                Icons.add,
              ),
              onPressed: () async {
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
                        title: 'Add a playlist',
                      );
                    });
              },
            ),
          ],
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
            int index = entry.key;
            IngredientRow row = entry.value;
            final playlist = row.playlist;
            if (playlist == null) {
              return const SizedBox.shrink();
            }
            return Dismissible(
              key: ValueKey('${playlist.id}_$index'),
              background: Container(
                color: Colors.orange,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20.0),
                child: Row(
                  children: const [
                    Icon(Icons.archive, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Archive', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              secondaryBackground: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text('Delete', style: TextStyle(color: Colors.white)),
                    SizedBox(width: 8),
                    Icon(Icons.delete, color: Colors.white),
                  ],
                ),
              ),
              confirmDismiss: (direction) => _handleDismiss(direction, index),
              child: SpotifyStylePlaylistTile(
                playlist: playlist,
                trailingButton: buildQuantityDropdown(row, index),
              ),
            );
          }),
      ],
    );
  }
}
