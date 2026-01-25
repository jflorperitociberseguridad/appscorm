import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class EmbedWidget extends StatelessWidget {
  final InteractiveBlock block;
  const EmbedWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.code, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            const Text("Incrustar Web / Iframe"),
            const SizedBox(height: 10),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Código Iframe o URL',
                hintText: '<iframe src="..."></iframe>',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: block.content['code']),
              onChanged: (v) => block.content['code'] = v,
            ),
          ],
        ),
      ),
    );
  }
}