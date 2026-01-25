import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class TrueFalseWidget extends StatefulWidget {
  final InteractiveBlock block;
  const TrueFalseWidget({super.key, required this.block});
  @override
  State<TrueFalseWidget> createState() => _TrueFalseWidgetState();
}

class _TrueFalseWidgetState extends State<TrueFalseWidget> {
  @override
  Widget build(BuildContext context) {
    bool isTrue = widget.block.content['isTrue'] ?? true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Verdadero o Falso", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              decoration: const InputDecoration(labelText: 'Afirmación / Pregunta'),
              controller: TextEditingController(text: widget.block.content['question']),
              onChanged: (v) => widget.block.content['question'] = v,
            ),
            SwitchListTile(
              title: Text("La respuesta correcta es: ${isTrue ? 'VERDADERO' : 'FALSO'}"),
              value: isTrue,
              onChanged: (val) => setState(() => widget.block.content['isTrue'] = val),
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
