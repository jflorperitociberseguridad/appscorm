import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class ImageWidget extends StatefulWidget {
  final InteractiveBlock block;
  const ImageWidget({super.key, required this.block});

  @override
  State<ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  late TextEditingController _urlCtrl;
  late TextEditingController _captionCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.block.content['url'] ?? '');
    _captionCtrl = TextEditingController(text: widget.block.content['caption'] ?? '');
  }

  void _save() {
    setState(() {
      widget.block.content['url'] = _urlCtrl.text;
      widget.block.content['caption'] = _captionCtrl.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.block.content['prompt'] ?? widget.block.content['style'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.image, size: 40, color: Colors.indigo),
            if (prompt != null && prompt.toString().trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Prompt sugerido: ${prompt.toString()}',
                style: const TextStyle(fontSize: 12, color: Colors.indigo),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL de la Imagen',
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _captionCtrl,
              decoration: const InputDecoration(
                labelText: 'Pie de foto (Opcional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _save(),
            ),
          ],
        ),
      ),
    );
  }
}
