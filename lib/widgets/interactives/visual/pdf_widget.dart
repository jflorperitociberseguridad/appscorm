import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class PdfWidget extends StatefulWidget {
  final InteractiveBlock block;
  const PdfWidget({super.key, required this.block});
  @override
  State<PdfWidget> createState() => _PdfWidgetState();
}

class _PdfWidgetState extends State<PdfWidget> {
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.block.content['url'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
            const SizedBox(height: 10),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL del documento PDF',
                hintText: 'https://...',
                border: OutlineInputBorder()
              ),
              onChanged: (val) => setState(() => widget.block.content['url'] = val),
            ),
          ],
        ),
      ),
    );
  }
}