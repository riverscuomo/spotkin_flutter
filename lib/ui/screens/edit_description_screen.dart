import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spotkin_flutter/app_core.dart';

class EditDescriptionScreen extends StatefulWidget {
  final int jobIndex;

  const EditDescriptionScreen({
    Key? key,
    required this.jobIndex,
  }) : super(key: key);

  @override
  State<EditDescriptionScreen> createState() => _EditDescriptionScreenState();
}

class _EditDescriptionScreenState extends State<EditDescriptionScreen> {
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    _descriptionController = TextEditingController(text: job.description);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveDescription() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final job = jobProvider.jobs[widget.jobIndex];
    final updatedJob = job.copyWith(description: _descriptionController.text);
    jobProvider.updateJob(widget.jobIndex, updatedJob);
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
