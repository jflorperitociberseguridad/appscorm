import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class SingleChoiceWidget extends StatefulWidget {
  final InteractiveBlock block;
  const SingleChoiceWidget({super.key, required this.block});
  @override
  State<SingleChoiceWidget> createState() => _SingleChoiceWidgetState();
}

class _SingleChoiceWidgetState extends State<SingleChoiceWidget> {
  late List<dynamic> options;
  
  @override
  void initState() {
    super.initState();
    options = widget.block.content['options'] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Selección Única", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              decoration: const InputDecoration(labelText: 'Pregunta'),
              controller: TextEditingController(text: widget.block.content['question']),
              onChanged: (v) => widget.block.content['question'] = v,
            ),
            const Divider(),
            ...options.asMap().entries.map((e) {
              final isSelected = widget.block.content['correctIndex'] == e.key;
              return ListTile(
              onTap: () => setState(() => widget.block.content['correctIndex'] = e.key),
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
              title: TextField(
                controller: TextEditingController(text: e.value.toString()),
                decoration: InputDecoration(labelText: 'Opción ${e.key + 1}'),
                onChanged: (v) => options[e.key] = v,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => options.removeAt(e.key)),
              ),
            );
            }),
            ElevatedButton(
              onPressed: () => setState(() => options.add("Nueva Opción")),
              child: const Text("Añadir Opción"),
            ),
            const Divider(),
            TextField(
              decoration: const InputDecoration(labelText: 'Feedback positivo'),
              controller: TextEditingController(text: widget.block.content['feedbackPositive']),
              onChanged: (v) => widget.block.content['feedbackPositive'] = v,
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Feedback negativo'),
              controller: TextEditingController(text: widget.block.content['feedbackNegative']),
              onChanged: (v) => widget.block.content['feedbackNegative'] = v,
            ),
          ],
        ),
      ),
    );
  }
}
