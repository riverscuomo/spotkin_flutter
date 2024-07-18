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
            decoration: const InputDecoration(labelText: 'Target playlist link'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter a playlist ID' : null,
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newJob = Job(
        name: _nameController.text,
        playlistId: _playlistIdController.text,
      
      );

      widget.onSubmit(newJob);
    }
  }
}
