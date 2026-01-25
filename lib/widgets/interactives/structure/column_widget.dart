import 'package:flutter/material.dart';
import '../../../models/interactive_block.dart';

class ColumnWidget extends StatelessWidget {
  final InteractiveBlock block;
  const ColumnWidget({super.key, required this.block});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("COLUMNA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Divider(),
          Text(block.content['text'] ?? 'Contenido de la columna...')
        ],
      ),
    );
  }
}