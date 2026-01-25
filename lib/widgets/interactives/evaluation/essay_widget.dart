import 'package:flutter/material.dart';
import '../../../models/interactive_block.dart';
import '../../quill_html_viewer.dart';

class EssayWidget extends StatelessWidget {
  final InteractiveBlock block;
  const EssayWidget({super.key, required this.block});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      QuillHtmlViewer(htmlContent: block.content['question'] ?? block.content['text'] ?? "Ensayo"),
      const SizedBox(height: 10),
      const TextField(maxLines: 4, decoration: InputDecoration(border: OutlineInputBorder(), hintText: "Respuesta del alumno..."), readOnly: true)
    ]);
  }
}