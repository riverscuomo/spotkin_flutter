import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class EditDescriptionScreen extends StatefulWidget {
  final Job job;
  final int jobIndex;
  final Function(int, Job) updateJob;

  const EditDescriptionScreen({
    Key? key,
    required this.job,
    required this.jobIndex,
    required this.updateJob,
  }) : super(key: key);

  @override
  State<EditDescriptionScreen> createState() => _EditDescriptionScreenState();
}

class _EditDescriptionScreenState extends State<EditDescriptionScreen> {
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.job.description);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveDescription() {
    final updatedJob =
        widget.job.copyWith(description: _descriptionController.text);
    widget.updateJob(widget.jobIndex, updatedJob);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Description'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveDescription,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
      ),
    );
  }
}
