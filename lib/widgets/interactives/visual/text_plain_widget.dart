import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';
import '../../quill_html_viewer.dart';

class TextPlainWidget extends StatelessWidget {
  final InteractiveBlock block;

  const TextPlainWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final text = block.content['text'] ?? 'Sin texto...';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: QuillHtmlViewer(htmlContent: text),
    );
  }
}