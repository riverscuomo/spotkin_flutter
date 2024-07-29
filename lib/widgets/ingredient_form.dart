import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

import 'ingredient_form_row.dart';

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
  final _formKey = GlobalKey<FormState>();
  late List<IngredientFormRow> _ingredientRows;
  bool _hasChanges = false;
  bool _isSubmitting = false;
  final SpotifyService spotifyService = getIt<SpotifyService>();

  @override
  void initState() {
    super.initState();
    _initIngredientRows();
  }

  @override
  void dispose() {
    for (var row in _ingredientRows) {
      row.playlistController.removeListener(_onFormChanged);
      row.quantityController.removeListener(_onFormChanged);
      row.playlistController.dispose();
      row.quantityController.dispose();
    }
    super.dispose();
  }

  bool get _hasEmptyRow => _ingredientRows.any((row) =>
      row.playlistController.text.isEmpty &&
      row.quantityController.text.isEmpty);

  void _initIngredientRows() {
    _ingredientRows = widget.initialIngredients
        .map((ingredient) => IngredientFormRow(
              playlistController:
                  TextEditingController(text: ingredient.playlist.name),
              quantityController:
                  TextEditingController(text: ingredient.quantity.toString()),
              playlist: ingredient.playlist,
            ))
        .toList();
    if (_ingredientRows.isEmpty) {
      _addNewRow();
    }
    _setupControllerListeners();
  }

  void _setupControllerListeners() {
    for (var row in _ingredientRows) {
      row.playlistController.addListener(_onFormChanged);
      row.quantityController.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  void didUpdateWidget(IngredientForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIngredients != oldWidget.initialIngredients) {
      _initIngredientRows();
    }
  }

  void _addNewRow() {
    setState(() {
      _ingredientRows.add(IngredientFormRow(
        playlistController: TextEditingController(),
        quantityController: TextEditingController(),
      ));
      _setupControllerListeners();
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientRows.removeAt(index);
      _onFormChanged();
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Process only the last (newest) ingredient row
        IngredientFormRow lastRow = _ingredientRows.last;

        if (lastRow.playlistController.text.isNotEmpty &&
            lastRow.quantityController.text.isNotEmpty) {
          String playlistId =
              Utils.extractPlaylistId(lastRow.playlistController.text);

          final playlist = await spotifyService.getPlaylist(playlistId);
          // String playlistName = playlist.name ?? 'Unknown Playlist';

          Ingredient newIngredient = Ingredient(
            // playlistName: playlistName,
            // playlistId: playlistId,
            playlist: playlist,
            quantity: int.tryParse(lastRow.quantityController.text) ?? 0,
          );

          // Update the row with the fetched playlist name
          setState(() {
            // lastRow.playlistName = playlistName;
            lastRow.playlist = playlist;
            // Add the new ingredient to the list
            widget.onIngredientsChanged(
                [...widget.initialIngredients, newIngredient]);
          });
        }

        setState(() {
          _hasChanges = false;
          _isSubmitting = false;
          // Add a new empty row for the next ingredient
          _addNewRow();
        });
      } catch (e) {
        // Handle any errors that occurred during playlist fetching
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching playlist details: $e')),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Source Playlists',
              style: Theme.of(context).textTheme.titleMedium),
          ..._ingredientRows.asMap().entries.map((entry) {
            int idx = entry.key;
            IngredientFormRow row = entry.value;
            return ListTile(
              title: Text(row.playlist?.name ?? 'Unknown Playlist'),
              leading: Image.network(row.playlist?.images?.first.url ?? ''),
              trailing: buildQuantityDropdown(row),
            );
          }),
          const SizedBox(height: 10),
          // In the build method
          if (_hasChanges &&
              _ingredientRows.last.playlistController.text.isNotEmpty &&
              _ingredientRows.last.quantityController.text.isNotEmpty)
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit'),
            )
          // else if (!_hasEmptyRow)
          //   IconButton(
          //     icon: const Icon(Icons.search),
          //     onPressed: () {
          //       showModalBottomSheet(
          //         context: context,
          //         builder: (BuildContext context) {
          //           return Container(
          //             padding: const EdgeInsets.all(16),
          //             child: Column(
          //               mainAxisSize: MainAxisSize.min,
          //               children: <Widget>[
          //                 TextField(
          //                   decoration: const InputDecoration(
          //                     hintText: 'Search...',
          //                     prefixIcon: Icon(Icons.search),
          //                     border: OutlineInputBorder(),
          //                   ),
          //                   onChanged: (value) {
          //                     // Implement your search logic here
          //                   },
          //                 ),
          //                 const SizedBox(height: 16),
          //                 ElevatedButton(
          //                   child: const Text('Close'),
          //                   onPressed: () => Navigator.pop(context),
          //                 ),
          //               ],
          //             ),
          //           );
          //         },
          //       );
          //     },
          //   ),
        ],
      ),
    );
  }
}
