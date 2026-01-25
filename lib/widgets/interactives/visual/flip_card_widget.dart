import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class FlipCardWidget extends StatefulWidget {
  final InteractiveBlock block;
  const FlipCardWidget({super.key, required this.block});

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget> {
  // Controladores para editar el texto sin perder el foco
  late TextEditingController _frontCtrl;
  late TextEditingController _backCtrl;

  @override
  void initState() {
    super.initState();
    _frontCtrl = TextEditingController(text: widget.block.content['front'] ?? '');
    _backCtrl = TextEditingController(text: widget.block.content['back'] ?? '');
  }

  void _save() {
    setState(() {
      widget.block.content['front'] = _frontCtrl.text;
      widget.block.content['back'] = _backCtrl.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.flip, color: Colors.blue), 
                SizedBox(width: 8), 
                Text("Tarjeta Giratoria", style: TextStyle(fontWeight: FontWeight.bold))
              ]
            ),
            const SizedBox(height: 15),
            
            // CARA FRONTAL
            TextField(
              controller: _frontCtrl,
              decoration: const InputDecoration(
                labelText: 'Cara Frontal (Pregunta / Concepto)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.help_outline),
                filled: true,
                fillColor: Colors.white
              ),
              onChanged: (_) => _save(),
            ),
            
            const SizedBox(height: 15),
            
            // CARA TRASERA
            TextField(
              controller: _backCtrl,
              decoration: const InputDecoration(
                labelText: 'Cara Trasera (Respuesta / Definición)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info_outline),
                filled: true,
                fillColor: Colors.white
              ),
              maxLines: 2,
              onChanged: (_) => _save(),
            ),
          ],
        ),
      ),
    );
  }
}