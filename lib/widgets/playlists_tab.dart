import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';
import 'ingredient_row.dart';

const int defaultQuantity = 2;

class PlaylistsTab extends StatefulWidget {
  final Job job;
  final int jobIndex;

  const PlaylistsTab({
    Key? key,
    required this.jobIndex,
    required this.job,
  }) : super(key: key);

  @override
  _PlaylistsTabState createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  late List<IngredientRow> _ingredientRows;
  final SpotifyService spotifyService = getIt<SpotifyService>();

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
    _ingredientRows = widget.job.recipe
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
  void didUpdateWidget(PlaylistsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.job.recipe != oldWidget.job.recipe) {
      _initIngredientRows();
    }
  }

  void _addNewRow(PlaylistSimple playlist) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    if (widget.job.recipe
        .any((ingredient) => ingredient.playlist.id == playlist.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This playlist is already in the recipe')),
      );
      return;
    }

    Ingredient newIngredient = Ingredient(
      playlist: playlist,
      quantity: defaultQuantity,
    );

    setState(() {
      _ingredientRows.add(IngredientRow(
        playlist: playlist,
        quantityController: TextEditingController(text: defaultQuantity.toString()),
      ));
      _sortIngredientRows();
    });

    final updatedJob =
        widget.job.copyWith(recipe: [...widget.job.recipe, newIngredient]);
    jobProvider.updateJob(widget.jobIndex, updatedJob);
  }

  void _updateJobInStorage(String playlistId, int newQuantity) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final updatedRecipe = widget.job.recipe.map((ingredient) {
      if (ingredient.playlist.id == playlistId) {
        return ingredient.copyWith(quantity: newQuantity);
      }
      return ingredient;
    }).toList();

    final updatedJob = widget.job.copyWith(recipe: updatedRecipe);
    jobProvider.updateJob(widget.jobIndex, updatedJob);

    setState(() {
      for (var row in _ingredientRows) {
        if (row.playlist?.id == playlistId) {
          row.quantityController.text = newQuantity.toString();
          break;
        }
      }
      _sortIngredientRows();
    });
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
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final updatedRecipe = widget.job.recipe
        .where((ingredient) => ingredient.playlist.id != playlistId)
        .toList();

    setState(() {
      _ingredientRows.removeWhere((row) => row.playlist?.id == playlistId);
      _sortIngredientRows();
    });

    final updatedJob = widget.job.copyWith(recipe: updatedRecipe);
    jobProvider.updateJob(widget.jobIndex, updatedJob);
  }

  Widget buildQuantityDropdown(IngredientRow row) {
    return SizedBox(
      width: 65,
      child: DropdownButtonFormField<int>(
        style: Theme.of(context).textTheme.labelLarge,
        value: int.tryParse(row.quantityController.text) ?? defaultQuantity,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              iconSize: 45.0,
              icon: const Icon(Icons.add),
              onPressed: () async {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (BuildContext context) {
                    return SearchBottomSheet(
                      onItemSelected: (dynamic item) {
                        if (item is PlaylistSimple) {
                          _addNewRow(item);
                        }
                      },
                      searchTypes: const [SearchType.playlist],
                      title: 'Add a playlist',
                    );
                  },
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recipe',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Source playlists and quantities',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_ingredientRows.isEmpty) ...[
          const Center(
            child: Text(
              'Add a source playlist to start building your recipe',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ] else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _ingredientRows.length,
            itemBuilder: (context, index) {
              final row = _ingredientRows[index];
              final playlistId = row.playlist?.id;

              if (playlistId == null) {
                return const SizedBox.shrink();
              }

              return Dismissible(
                key: Key(playlistId),
                background: Container(
                  color: Colors.yellow,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 16),
                  child: const Icon(Icons.archive, color: Colors.black),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) =>
                    _handleDismiss(direction, playlistId),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        if (row.playlist?.images?.isNotEmpty ?? false)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              image: DecorationImage(
                                image: NetworkImage(
                                    row.playlist!.images!.first.url!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.music_note,
                                color: Colors.white),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.playlist?.name ?? 'Unknown Playlist',
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Spotify',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        buildQuantityDropdown(row),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
