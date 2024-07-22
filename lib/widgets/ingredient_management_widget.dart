import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart';
import 'package:spotkin_flutter/app_core.dart';



class IngredientForm extends StatefulWidget {
  final List<Ingredient> initialIngredients;
  final Function(List<Ingredient>) onIngredientsChanged;
  final Future<String> Function(String playlistId) fetchPlaylistName;

  const IngredientForm({
    Key? key,
    required this.initialIngredients,
    required this.onIngredientsChanged,
    required this.fetchPlaylistName,
  }) : super(key: key);

  @override
  _IngredientFormState createState() => _IngredientFormState();
}

class _IngredientFormState extends State<IngredientForm> {
  final _formKey = GlobalKey<FormState>();
  late List<IngredientFormRow> _ingredientRows;
  bool _hasChanges = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initIngredientRows();
  }
 bool get _hasEmptyRow => _ingredientRows.any((row) => 
    row.playlistController.text.isEmpty && row.quantityController.text.isEmpty);

  void _initIngredientRows() {
    _ingredientRows = widget.initialIngredients.map((ingredient) => 
      IngredientFormRow(
        playlistController: TextEditingController(text: ingredient.sourcePlaylistId),
        quantityController: TextEditingController(text: ingredient.quantity.toString()),
        playlistName: ingredient.sourcePlaylistName,
      )
    ).toList();
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
        
        if (lastRow.playlistController.text.isNotEmpty && lastRow.quantityController.text.isNotEmpty) {
          String playlistId = Utils.extractPlaylistId(lastRow.playlistController.text);
          String playlistName = await widget.fetchPlaylistName(playlistId);
          
          Ingredient newIngredient = Ingredient(
            sourcePlaylistName: playlistName,
            sourcePlaylistId: playlistId,
            quantity: int.tryParse(lastRow.quantityController.text) ?? 0,
          );

          // Update the row with the fetched playlist name
          setState(() {
            lastRow.playlistName = playlistName;
            // Add the new ingredient to the list
            widget.onIngredientsChanged([...widget.initialIngredients, newIngredient]);
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

  @override
  Widget build(BuildContext context) {
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
          ..._ingredientRows.asMap().entries.map((entry) {
            int idx = entry.key;
            IngredientFormRow row = entry.value;
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: row.playlistName != null
                    ? Text(row.playlistName!, style: TextStyle(fontWeight: FontWeight.bold))
                    : TextFormField(
                        controller: row.playlistController,
                        decoration: const InputDecoration(
                          labelText: 'Source playlist link',
                          hintText: 'Enter Spotify playlist link or ID',
                        ),
                        validator: Utils.validateSpotifyPlaylistInput,
                      ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: row.quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty || int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeIngredient(idx),
                ),
              ],
            );
          }),
          const SizedBox(height: 10),
          // In the build method
if (_hasChanges && _ingredientRows.last.playlistController.text.isNotEmpty && _ingredientRows.last.quantityController.text.isNotEmpty)
  ElevatedButton(
    onPressed: _isSubmitting ? null : _submitForm,
    child: _isSubmitting ? CircularProgressIndicator() : Text('Submit'),
  )
else if (!_hasEmptyRow)
  IconButton(
    icon: const Icon(Icons.add),
    onPressed: _addNewRow,
  ),
        ],
      ),
    );
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
}

class IngredientFormRow {
  final TextEditingController playlistController;
  final TextEditingController quantityController;
  String? playlistName;

  IngredientFormRow({
    required this.playlistController,
    required this.quantityController,
    this.playlistName,
  });
}