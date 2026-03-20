import 'package:flutter/material.dart';
import '../../../models/interactive_block.dart';

class MultipleChoiceWidget extends StatelessWidget {
  final InteractiveBlock block;
  const MultipleChoiceWidget({super.key, required this.block});
  @override
  Widget build(BuildContext context) {
    final List options = block.content['options'] ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(block.content['question'] ?? 'Pregunta...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            ...options.map((opt) {
              final text = opt is Map ? opt['text'] : opt.toString();
              final isCorrect = opt is Map ? (opt['correct'] ?? false) : false;
              return Row(children: [
                Icon(isCorrect ? Icons.check_circle : Icons.circle_outlined, color: isCorrect ? Colors.green : Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(text))
              ]);
            })
          ],
        ),
      ),
    );
  }
}