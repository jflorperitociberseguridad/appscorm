import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/interactive_block.dart';

class CarouselWidget extends StatelessWidget {
  final InteractiveBlock block;
  const CarouselWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final List items = block.content['items'] ?? [];
    if (items.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(20), child: Text("Carrusel vacío")));

    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final url = item['front'] ?? '';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              children: [
                Expanded(child: url.startsWith('data:') 
                  ? Image.memory(base64Decode(url.split(',').last), fit: BoxFit.cover)
                  : Image.network(url, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.image))),
                if (item['back'] != null) Padding(padding: const EdgeInsets.all(8.0), child: Text(item['back']))
              ],
            ),
          );
        },
      ),
    );
  }
  // Helper para base64 si no tienes el import de dart:convert arriba, añádelo: import 'dart:convert';
}
