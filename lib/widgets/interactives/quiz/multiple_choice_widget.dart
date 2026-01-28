import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class MultipleChoiceWidget extends StatefulWidget {
  final InteractiveBlock block;
  const MultipleChoiceWidget({super.key, required this.block});
  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  late List<dynamic> options;
  late List<dynamic> correctIndices;

  @override
  void initState() {
    super.initState();
    options = widget.block.content['options'] ?? [];
    correctIndices = widget.block.content['correctIndices'] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Selección Múltiple", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              decoration: const InputDecoration(labelText: 'Pregunta'),
              controller: TextEditingController(text: widget.block.content['question']),
              onChanged: (v) => widget.block.content['question'] = v,
            ),
            const Divider(),
            ...options.asMap().entries.map((e) {
              final isCorrect = correctIndices.contains(e.key);
              return ListTile(
                leading: Checkbox(
                  value: isCorrect,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        correctIndices.add(e.key);
                      } else {
                        correctIndices.remove(e.key);
                      }
                      widget.block.content['correctIndices'] = correctIndices;
                    });
                  },
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
