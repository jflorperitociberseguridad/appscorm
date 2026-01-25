import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class QuoteWidget extends StatelessWidget {
  final InteractiveBlock block;
  const QuoteWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.format_quote, size: 40, color: Colors.amber),
            TextField(
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Cita / Frase célebre'),
              controller: TextEditingController(text: block.content['text']),
              onChanged: (v) => block.content['text'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Autor'),
              controller: TextEditingController(text: block.content['author']),
              onChanged: (v) => block.content['author'] = v,
            ),
          ],
        ),
      ),
    );
  }
}