import 'package:flutter/material.dart';
import '../../../models/interactive_block.dart';
import 'dart:convert'; // Necesario para imágenes base64

class AgamottoWidget extends StatefulWidget {
  final InteractiveBlock block;
  const AgamottoWidget({super.key, required this.block});
  @override
  State<AgamottoWidget> createState() => _AgamottoWidgetState();
}
class _AgamottoWidgetState extends State<AgamottoWidget> {
  double _val = 0;
  @override
  Widget build(BuildContext context) {
    final List items = widget.block.content['items'] ?? [];
    if(items.isEmpty) return const Text("Agamotto sin imágenes");
    
    final currentItem = items[_val.toInt().clamp(0, items.length-1)];
    final url = currentItem['front'] ?? '';

    return Column(
      children: [
        SizedBox(
          height: 250,
          width: double.infinity,
          child: url.startsWith('data:') 
             ? Image.memory(base64Decode(url.split(',').last), fit: BoxFit.cover)
             : Image.network(url, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.broken_image)),
        ),
        Slider(value: _val, min: 0, max: (items.length - 1).toDouble(), divisions: items.length > 1 ? items.length - 1 : 1, onChanged: (v)=>setState(()=>_val=v))
      ],
    );
  }
}