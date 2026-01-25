import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class ProcessWidget extends StatefulWidget {
  final InteractiveBlock block;
  const ProcessWidget({super.key, required this.block});
  @override
  State<ProcessWidget> createState() => _ProcessWidgetState();
}

class _ProcessWidgetState extends State<ProcessWidget> {
  late List<dynamic> steps;
  
  IconData _iconForStep(Map<String, dynamic> step) {
    final raw = step['icon'];
    if (raw is int) {
      return IconData(raw, fontFamily: 'MaterialIcons');
    }
    return Icons.check_circle_outline;
  }

  @override
  void initState() {
    super.initState();
    steps = widget.block.content['steps'] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.format_list_numbered),
            title: const Text("Proceso paso a paso"),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() {
                steps.add({
                  'title': 'Paso ${steps.length + 1}',
                  'desc': '',
                  'icon': Icons.check_circle_outline.codePoint,
                });
                widget.block.content['steps'] = steps;
              }),
            ),
          ),
          ...steps.asMap().entries.map((e) {
            final step = (e.value as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
            return ListTile(
              leading: Icon(_iconForStep(step)),
              title: TextField(
                controller: TextEditingController(text: step['title']),
                decoration: InputDecoration(labelText: 'Paso ${e.key + 1}'),
                onChanged: (val) {
                  step['title'] = val;
                  steps[e.key] = step;
                  widget.block.content['steps'] = steps;
                },
              ),
              subtitle: TextField(
                controller: TextEditingController(text: step['desc']),
                decoration: const InputDecoration(labelText: 'Descripción'),
                onChanged: (val) {
                  step['desc'] = val;
                  steps[e.key] = step;
                  widget.block.content['steps'] = steps;
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => steps.removeAt(e.key)),
              ),
            );
          }).toList()
        ],
      ),
    );
  }
}
