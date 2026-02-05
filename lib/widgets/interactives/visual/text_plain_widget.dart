import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';
import '../../../../services/ai_service.dart';
import '../../wysiwyg_editor.dart';

class TextPlainWidget extends StatefulWidget {
  final InteractiveBlock block;

  const TextPlainWidget({super.key, required this.block});

  @override
  State<TextPlainWidget> createState() => _TextPlainWidgetState();
}

class _TextPlainWidgetState extends State<TextPlainWidget> {
  late final Future<AiService> _aiServiceFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _aiServiceFuture = AiService.create();
  }

  // ESTA ES LA FUNCIÓN QUE HACE FUNCIONAR EL BOTÓN DE LA IA (PUNTO 2)
  Future<void> _ejecutarIA(String accion) async {
    setState(() => _isLoading = true);

    try {
      String modo = 'fix';
      if (accion.contains('Resumir')) modo = 'summarize';
      if (accion.contains('Expandir')) modo = 'expand';
      if (accion.contains('profesional')) modo = 'professional';

      // Tomamos el texto que haya escrito el usuario
      String textoActual = widget.block.content['text'] ?? '';

      // Llamamos a Gemini
      final aiService = await _aiServiceFuture;
      final nuevoTexto = await aiService.improveText(textoActual, mode: modo);

      // Actualizamos el bloque con el nuevo texto
      setState(() {
        widget.block.content['text'] = nuevoTexto;
      });
    } catch (e) {
      debugPrint("Error con la IA: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABECERA DEL BLOQUE CON EL MENÚ DE IA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.short_text, size: 16, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text("TEXTPLAIN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: _ejecutarIA, // Aquí conectamos el botón con la IA
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Resumir contenido', child: Text('Resumir contenido')),
                  const PopupMenuItem(value: 'Expandir explicación', child: Text('Expandir explicación')),
                  const PopupMenuItem(value: 'Cambiar a tono profesional', child: Text('Cambiar a tono profesional')),
                ],
              ),
            ],
          ),
          
          if (_isLoading) const LinearProgressIndicator(),
          const SizedBox(height: 12),

          // EL EDITOR WYSIWYG (PUNTO 1)
          // Usamos el widget que ya tienes creado en lib/widgets/wysiwyg_editor.dart
          WysiwygEditor(
            label: "EDITOR DE TEXTO", // ✅ CORRECCIÓN: Se añade el parámetro requerido
            initialValue: widget.block.content['text'] ?? '',
            onChanged: (val) {
              widget.block.content['text'] = val;
            },
          ),
        ],
      ),
    );
  }
}
