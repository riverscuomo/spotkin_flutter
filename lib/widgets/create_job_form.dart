import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class CreateJobForm extends StatefulWidget {
  final Function(Job) onSubmit;

  CreateJobForm({
    required this.onSubmit,
  });

  @override
  _CreateJobFormState createState() => _CreateJobFormState();
}

class _CreateJobFormState extends State<CreateJobForm> {
  final _formKey = GlobalKey<FormState>();
  // final _nameController = TextEditingController();
  final _playlistIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // TextFormField(
          //   controller: _nameController,
          //   decoration: const InputDecoration(labelText: 'Job Name'),
          //   validator: (value) =>
          //       value?.isEmpty ?? true ? 'Please enter a job name' : null,
          // ),
          TextFormField(
            controller: _playlistIdController,
            decoration: const InputDecoration(labelText: 'Target playlist'),
            validator: (value) => value?.isEmpty ?? true
                ? 'Please enter a Spotify playlist link'
                : null,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final spotifyService = getIt<SpotifyService>();
      final playlistId = Utils.extractPlaylistId(_playlistIdController.text);
      final targetPlaylist = await spotifyService.fetchPlaylist(playlistId);
      final newJob = Job(
        targetPlaylist: targetPlaylist,
      );

      widget.onSubmit(newJob);
    }
  }
}
