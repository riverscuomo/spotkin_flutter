import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class JobForm extends StatefulWidget {
  final Function(Job) onSubmit;

  JobForm({required this.onSubmit});

  @override
  _JobFormState createState() => _JobFormState();
}

class _JobFormState extends State<JobForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _playlistIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lastTrackIdsController = TextEditingController();
  final _bannedArtistNamesController = TextEditingController();
  final _bannedSongTitlesController = TextEditingController();
  final _bannedTrackIdsController = TextEditingController();
  final _bannedGenresController = TextEditingController();
  final _exceptionsToBannedGenresController = TextEditingController();
  bool _removeLowEnergy = false;
  List<Ingredient> _ingredients = [];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Job Name'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a job name' : null,
          ),
          TextFormField(
            controller: _playlistIdController,
            decoration: const InputDecoration(labelText: 'Playlist ID'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a playlist ID' : null,
          ),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          SwitchListTile(
            title: const Text('Remove Low Energy'),
            value: _removeLowEnergy,
            onChanged: (bool value) {
              setState(() {
                _removeLowEnergy = value;
              });
            },
          ),
          TextFormField(
            controller: _lastTrackIdsController,
            decoration: const InputDecoration(
                labelText: 'Last Track IDs (comma-separated)'),
          ),
          TextFormField(
            controller: _bannedArtistNamesController,
            decoration: const InputDecoration(
                labelText: 'Banned Artist Names (comma-separated)'),
          ),
          TextFormField(
            controller: _bannedSongTitlesController,
            decoration: const InputDecoration(
                labelText: 'Banned Song Titles (comma-separated)'),
          ),
          TextFormField(
            controller: _bannedTrackIdsController,
            decoration: const InputDecoration(
                labelText: 'Banned Track IDs (comma-separated)'),
          ),
          TextFormField(
            controller: _bannedGenresController,
            decoration: const InputDecoration(
                labelText: 'Banned Genres (comma-separated)'),
          ),
          TextFormField(
            controller: _exceptionsToBannedGenresController,
            decoration: const InputDecoration(
                labelText: 'Exceptions to Banned Genres (comma-separated)'),
          ),
          const SizedBox(height: 10),
          Text('Ingredients', style: Theme.of(context).textTheme.subtitle1),
          ..._ingredients.asMap().entries.map((entry) {
            int idx = entry.key;
            Ingredient ingredient = entry.value;
            return Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: ingredient.sourcePlaylistId,
                    decoration:
                        const InputDecoration(labelText: 'Source Playlist ID'),
                    onChanged: (value) {
                      setState(() {
                        _ingredients[idx] =
                            ingredient.copyWith(sourcePlaylistId: value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: ingredient.quantity.toString(),
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _ingredients[idx] = ingredient.copyWith(
                            quantity: int.tryParse(value) ?? 0);
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _ingredients.removeAt(idx);
                    });
                  },
                ),
              ],
            );
          }).toList(),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _ingredients.add(Ingredient(
                    sourcePlaylistId: '',
                    sourcePlaylistName: 'test2',
                    quantity: 0));
              });
            },
            child: const Text('Add Playlist'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Add Job'),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newJob = Job(
        name: _nameController.text,
        playlistId: _playlistIdController.text,
        description: _descriptionController.text,
        removeLowEnergy: _removeLowEnergy,
        lastTrackIds: _lastTrackIdsController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        bannedArtistNames: _bannedArtistNamesController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        bannedSongTitles: _bannedSongTitlesController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        bannedTrackIds: _bannedTrackIdsController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        bannedGenres: _bannedGenresController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        exceptionsToBannedGenres: _exceptionsToBannedGenresController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        recipe: _ingredients,
      );

      widget.onSubmit(newJob);
    }
  }
}
