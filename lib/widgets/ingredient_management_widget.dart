import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';
import 'package:flutter/material.dart';

class IngredientForm extends StatefulWidget {
  final List<Ingredient> initialIngredients;
  final Function(List<Ingredient>) onIngredientsChanged;

  const IngredientForm({
    Key? key,
    required this.initialIngredients,
    required this.onIngredientsChanged,
  }) : super(key: key);

  @override
  _IngredientFormState createState() => _IngredientFormState();
}

class _IngredientFormState extends State<IngredientForm> {
  final _formKey = GlobalKey<FormState>();
  late List<IngredientFormRow> _ingredientRows;

  @override
  void initState() {
    super.initState();
    _initIngredientRows();
  }

  void _initIngredientRows() {
    _ingredientRows = widget.initialIngredients.map((ingredient) => 
      IngredientFormRow(
        playlistController: TextEditingController(text: ingredient.sourcePlaylistId),
        quantityController: TextEditingController(text: ingredient.quantity.toString()),
      )
    ).toList();
    if (_ingredientRows.isEmpty) {
      _addNewRow();
    }
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
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientRows.removeAt(index);
    });
  }

  void _submitAndAddIngredient() {
    if (_formKey.currentState!.validate()) {
      List<Ingredient> updatedIngredients = _ingredientRows.map((row) => 
        Ingredient(
          sourcePlaylistName: '', // You might want to update this if needed
          sourcePlaylistId: row.playlistController.text,
          quantity: int.tryParse(row.quantityController.text) ?? 0,
        )
      ).toList();

      widget.onIngredientsChanged(updatedIngredients);
      _addNewRow();
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
                  child: TextFormField(
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
          ElevatedButton(
            onPressed: _submitAndAddIngredient,
            child: const Text('Add Ingredient'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var row in _ingredientRows) {
      row.playlistController.dispose();
      row.quantityController.dispose();
    }
    super.dispose();
  }
}

class IngredientFormRow {
  final TextEditingController playlistController;
  final TextEditingController quantityController;

  IngredientFormRow({
    required this.playlistController,
    required this.quantityController,
  });
}