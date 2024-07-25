import 'package:flutter/material.dart';
import 'package:spotkin_flutter/app_core.dart';

class ListManagementScreen extends StatefulWidget {
  final String title;
  final List<String> items;
  final String tooltip;
  final Function(List<String>) onListUpdated;

  const ListManagementScreen({
    Key? key,
    required this.title,
    required this.items,
    required this.tooltip,
    required this.onListUpdated,
  }) : super(key: key);

  @override
  _ListManagementScreenState createState() => _ListManagementScreenState();
}

class _ListManagementScreenState extends State<ListManagementScreen> {
  late List<String> _items;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  void _addItem(String item) {
    setState(() {
      _items.add(item);
    });
    widget.onListUpdated(_items);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    widget.onListUpdated(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(widget.tooltip),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Add new item',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _addItem(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_items[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeItem(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
