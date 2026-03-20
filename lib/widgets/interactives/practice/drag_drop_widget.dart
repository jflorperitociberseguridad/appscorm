import 'package:flutter/material.dart';
import '../../../models/interactive_block.dart';
import 'dart:convert';

class DragDropWidget extends StatelessWidget {
  final InteractiveBlock block;
  const DragDropWidget({super.key, required this.block});
  @override
  Widget build(BuildContext context) {
    final url = block.content['url'];
    return AspectRatio(
      aspectRatio: 16/9,
      child: Container(
        color: Colors.grey[200],
        child: Stack(
          children: [
            if (url != null && url.isNotEmpty)
               Positioned.fill(
                 child: url.startsWith('data:') 
                   ? Image.memory(base64Decode(url.split(',').last), fit: BoxFit.cover)
                   : Image.network(url, fit: BoxFit.cover),
               ),
            const Center(child: Text("Zona Interactiva (Preview)", style: TextStyle(backgroundColor: Colors.white54))),
          ],
        ),
      ),
    );
  }
}