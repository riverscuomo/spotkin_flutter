import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class IngredientManagementWidget extends StatefulWidget {
  final List<Ingredient> initialIngredients;
  final Function(List<Ingredient>) onIngredientsChanged;

  const IngredientManagementWidget({
    Key? key,
    required this.initialIngredients,
    required this.onIngredientsChanged,
  }) : super(key: key);

  @override
  _IngredientManagementWidgetState createState() => _IngredientManagementWidgetState();
}

class _IngredientManagementWidgetState extends State<IngredientManagementWidget> {
  late List<Ingredient> _ingredients;

  @override
  void initState() {
    super.initState();
    _ingredients = List.from(widget.initialIngredients);
  }

  @override
  void didUpdateWidget(IngredientManagementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIngredients != oldWidget.initialIngredients) {
      setState(() {
        _ingredients = List.from(widget.initialIngredients);
      });
    }
  }

  void _updateIngredient(int index, Ingredient updatedIngredient) {
    setState(() {
      _ingredients[index] = updatedIngredient;
      widget.onIngredientsChanged(_ingredients);
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      widget.onIngredientsChanged(_ingredients);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ingredients', style: Theme.of(context).textTheme.subtitle1),
        ..._ingredients.asMap().entries.map((entry) {
          int idx = entry.key;
          Ingredient ingredient = entry.value;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('sourcePlaylistId_$idx'),
                  initialValue: ingredient.sourcePlaylistId,
                  decoration: const InputDecoration(
                    labelText: 'Source playlist link',
                    hintText: 'Enter Spotify playlist link or ID',
                  ),
                  validator: Utils.validateSpotifyPlaylistInput,
                  onChanged: (value) {
                    _updateIngredient(idx, ingredient.copyWith(sourcePlaylistId: value));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: ValueKey('quantity_$idx'),
                  initialValue: ingredient.quantity.toString(),
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateIngredient(idx, ingredient.copyWith(quantity: int.tryParse(value) ?? 0));
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
          onPressed: () {
            setState(() {
              _ingredients.add(Ingredient(sourcePlaylistName: '', sourcePlaylistId: '', quantity: 0));
              widget.onIngredientsChanged(_ingredients);
            });
          },
          child: const Text('Add Ingredient'),
        ),
      ],
    );
  }
}