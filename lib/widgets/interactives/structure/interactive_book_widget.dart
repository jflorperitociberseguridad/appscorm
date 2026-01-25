import 'package:flutter/material.dart';
import '../../../models/interactive_block.dart';

class InteractiveBookWidget extends StatelessWidget {
  final InteractiveBlock block;
  const InteractiveBookWidget({super.key, required this.block});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(border: Border.all(color: Colors.indigo), borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text("📖 Libro: ${block.content['title'] ?? 'Sin título'}")),
    );
  }
}