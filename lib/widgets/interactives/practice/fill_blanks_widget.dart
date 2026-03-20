import 'package:flutter/material.dart';
import '../../../models/interactive_block.dart';

class FillBlanksWidget extends StatelessWidget {
  final InteractiveBlock block;
  const FillBlanksWidget({super.key, required this.block});
  @override
  Widget build(BuildContext context) {
    String text = block.content['text'] ?? "Texto de *ejemplo*.";
    text = text.replaceAll(RegExp(r'<[^>]*>'), ''); // Remove HTML tags for simple rendering
    final parts = text.split('*');
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: List.generate(parts.length, (i) {
        if (i % 2 == 0) return Text(parts[i], style: const TextStyle(fontSize: 16));
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 80,
          height: 30,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.indigo.shade200))),
        );
      }),
    );
  }
}