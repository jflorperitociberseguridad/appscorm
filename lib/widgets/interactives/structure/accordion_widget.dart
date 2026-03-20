import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class AccordionWidget extends StatelessWidget {
  final InteractiveBlock block;
  const AccordionWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final title = block.content['title'] ?? block.content['question'] ?? 'Título del panel'; // Fallback a question por si se usa genericamente
    final text = block.content['text'] ?? 'Contenido desplegable...';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.expand_circle_down, color: Colors.indigo),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[50],
            child: Text(text, style: const TextStyle(height: 1.5)),
          )
        ],
      ),
    );
  }
}