import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';

import 'ingredient_row.dart';

class RecipeWidget extends StatefulWidget {
  final List<Ingredient> initialIngredients;
  final Function(List<Ingredient>) onIngredientsChanged;
  final List<Job> jobs;
  final Function(int, Job) updateJob;
  final List<Map<String, dynamic>> jobResults;
  final Function() onJobsReloaded; // Add this new callback

  const RecipeWidget({
    Key? key,
    required this.initialIngredients,
    required this.onIngredientsChanged,
    required this.jobs,
    required this.updateJob,
    required this.jobResults,
    required this.onJobsReloaded, // Add this to the constructor
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

  void loadJobs() async {
    // Reload jobs from storage
    List<Job> updatedJobs = await storageService.getJobs();

    // Call the callback to update jobs in the parent widget
    widget.onJobsReloaded();

    // Optionally, you can update the local state if needed
    setState(() {
      // If you need to use the updated jobs locally
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
    _sortIngredientRows();
  }

  void _sortIngredientRows() {
    setState(() {
      _ingredientRows.sort((a, b) {
        int quantityA = int.tryParse(a.quantityController.text) ?? 0;
        int quantityB = int.tryParse(b.quantityController.text) ?? 0;
        return quantityB.compareTo(quantityA);
      });
    });
  }

  @override
  void didUpdateWidget(RecipeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIngredients != oldWidget.initialIngredients) {
      _initIngredientRows();
    }
  }

  void _addNewRow(PlaylistSimple playlist, Job job) {
    if (job.recipe.any((ingredient) => ingredient.playlist.id == playlist.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This playlist is already in the recipe')),
      );
      return;
    }

    Ingredient newIngredient = Ingredient(
      playlist: playlist,
      quantity: 5,
    );

    setState(() {
      _ingredientRows.add(IngredientRow(
        playlist: playlist,
        quantityController: TextEditingController(text: '5'),
      ));
      _sortIngredientRows();
    });

    final updatedJob = job.copyWith(recipe: [...job.recipe, newIngredient]);
    storageService.updateJob(updatedJob);
    widget.onIngredientsChanged(updatedJob.recipe);
  }

  void _updateJobInStorage(String playlistId, int newQuantity) {
    final job = storageService.getJobs().first;
    final updatedRecipe = job.recipe.map((ingredient) {
      if (ingredient.playlist.id == playlistId) {
        return ingredient.copyWith(quantity: newQuantity);
      }
      return ingredient;
    }).toList();

    final updatedJob = job.copyWith(recipe: updatedRecipe);
    storageService.updateJob(updatedJob);

    setState(() {
      for (var row in _ingredientRows) {
        if (row.playlist?.id == playlistId) {
          row.quantityController.text = newQuantity.toString();
          break;
        }
      }
      _sortIngredientRows();
    });

    widget.onIngredientsChanged(updatedJob.recipe);
  }

  Widget buildQuantityDropdown(IngredientRow row) {
    return SizedBox(
      width: 70,
      child: DropdownButtonFormField<int>(
        value: int.tryParse(row.quantityController.text) ?? 5,
        items: List.generate(21, (index) {
          return DropdownMenuItem<int>(
            value: index,
            child: Text(index.toString()),
          );
        }),
        onChanged: (value) {
          if (value != null && row.playlist != null) {
            _updateJobInStorage(row.playlist!.id!, value);
          }
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a quantity';
          }
          return null;
        },
      ),
    );
  }

  Future<bool> _handleDismiss(
      DismissDirection direction, String playlistId) async {
    if (direction == DismissDirection.endToStart) {
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
        _removeIngredient(playlistId);
        return true;
      }
    } else if (direction == DismissDirection.startToEnd) {
      _updateJobInStorage(playlistId, 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist archived (quantity set to 0)')),
      );
    }
    return false;
  }

  void _removeIngredient(String playlistId) {
    final job = storageService.getJobs().first;
    final updatedRecipe = job.recipe
        .where((ingredient) => ingredient.playlist.id != playlistId)
        .toList();
    final updatedJob = job.copyWith(recipe: updatedRecipe);
    storageService.updateJob(updatedJob);

    setState(() {
      _ingredientRows.removeWhere((row) => row.playlist?.id == playlistId);
      _sortIngredientRows();
    });

    widget.onIngredientsChanged(updatedJob.recipe);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> jobResults = widget.jobResults;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
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
                  },
                );
              },
            ),
            const SizedBox(width: 10),
            if (jobResults.isNotEmpty)
              Text(
                jobResults[0]['result'],
                style: Theme.of(context)
                    .textTheme
                    .labelMedium!
                    .copyWith(fontStyle: FontStyle.italic),
              ),
            const SizedBox(width: 10),
            if (jobResults.isNotEmpty)
              Icon(
                size: 14,
                jobResults[0]['status'] == 'Success'
                    ? Icons.check_circle
                    : Icons.error,
                color: jobResults[0]['status'] == 'Success'
                    ? Colors.green
                    : Colors.red,
              ),
            if (_ingredientRows.isNotEmpty)
              SettingsButton(
                jobs: widget.jobs,
                updateJob: widget.updateJob,
                onJobsImported: loadJobs,
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
          ..._ingredientRows.map((row) {
            final playlist = row.playlist;
            if (playlist == null) {
              return const SizedBox.shrink();
            }
            return Dismissible(
              key: ValueKey(playlist.id),
              background: Container(
                color: Colors.orange,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20.0),
                child: const Row(
                  children: [
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Delete', style: TextStyle(color: Colors.white)),
                    SizedBox(width: 8),
                    Icon(Icons.delete, color: Colors.white),
                  ],
                ),
              ),
              confirmDismiss: (direction) =>
                  _handleDismiss(direction, playlist.id!),
              child: SpotifyStylePlaylistTile(
                playlist: playlist,
                trailingButton: buildQuantityDropdown(row),
                active: row.quantityController.text != '0',
              ),
            );
          }),
      ],
    );
  }
}
