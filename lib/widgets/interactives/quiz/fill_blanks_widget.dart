import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class FillBlanksWidget extends StatelessWidget {
  final InteractiveBlock block;
  const FillBlanksWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.text_fields, size: 40),
            const Text("Rellenar Huecos"),
            const Text(
              "Instrucción: Escribe la frase y pon entre *asteriscos* las palabras ocultas.\nEj: La capital de Francia es *París*.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Texto del ejercicio...'),
              controller: TextEditingController(text: block.content['text']),
              onChanged: (v) => block.content['text'] = v,
            ),
          ],
        ),
      ),
    );
  }
}