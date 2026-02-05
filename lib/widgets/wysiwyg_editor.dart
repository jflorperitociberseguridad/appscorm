import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_service.dart';

class WysiwygEditor extends StatefulWidget {
  final String initialValue;
  final String label;
  final Function(String) onChanged;

  const WysiwygEditor({
    super.key,
    this.initialValue = '',
    required this.label,
    required this.onChanged,
  });

  @override
  State<WysiwygEditor> createState() => _WysiwygEditorState();
}

class _WysiwygEditorState extends State<WysiwygEditor> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  
  // ✅ AÑADIDO: Controlador para el nombre del archivo (Petición anterior)
  final TextEditingController _nameController = TextEditingController(); 
  
  bool _isLoading = true;
  late final Future<AiService> _aiServiceFuture;

  @override
  void initState() {
    super.initState();
    // Iniciamos el nombre con la etiqueta por defecto
    _nameController.text = widget.label.isNotEmpty ? widget.label : "Nuevo Contenido";
    _aiServiceFuture = AiService.create();
    _initializeEditor();
    _isLoading = false;
  }

  @override
  void didUpdateWidget(WysiwygEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      try {
        if (widget.initialValue.trim().isEmpty) return; // Evita delta vacío

        final delta = HtmlToDelta().convert(widget.initialValue);
        
        // Verificamos si el controlador está inicializado antes de usarlo
        if (_isLoading) return; 

        final currentHtml = _getHtmlFromDelta(_controller.document.toDelta());
        
        if (currentHtml != widget.initialValue) {
           if (delta.isEmpty) return; // Protección extra
           
           setState(() {
            _controller = QuillController(
              document: Document.fromDelta(delta),
              selection: const TextSelection.collapsed(offset: 0),
            );
            _controller.addListener(_onEditorChanged);
          });
        }
      } catch (e) {
        debugPrint("Error actualizando editor: $e");
      }
    }
  }

  String _getHtmlFromDelta(var delta) {
    final converter = QuillDeltaToHtmlConverter(
      delta.toJson(),
      ConverterOptions(converterOptions: OpConverterOptions(inlineStylesFlag: true)),
    );
    return converter.convert();
  }

  // ✅ MODIFICADO: Guardar usando el nombre del campo de texto
  Future<void> _generarCurso() async {
    try {
      final html = _getHtmlFromDelta(_controller.document.toDelta());
      widget.onChanged(html);
      
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      
      // Usamos el nombre escrito por el usuario o un default
      String saveKey = _nameController.text.trim().isEmpty 
          ? 'borrador_curso_juritecnia' 
          : 'curso_${_nameController.text.trim().replaceAll(' ', '_').toLowerCase()}';

      await prefs.setString(saveKey, html);
      if (!mounted) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Guardado como: ${_nameController.text}"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      debugPrint("Error guardando: $e");
    }
  }

  Future<void> _applyAiChange(String mode) async {
    Navigator.pop(context);
    setState(() => _isLoading = true);
    try {
      final currentText = _controller.document.toPlainText();
      // Usamos 'fix' si es professional, o el modo directo
      String aiMode = mode == 'professional' ? 'fix' : mode;
      final aiService = await _aiServiceFuture;
      
      final improved = await aiService.improveText(currentText, mode: aiMode);
      if (!mounted) return;
      
      // Convertimos el texto mejorado a Delta para el editor
      // Nota: Si improveText devuelve texto plano, lo insertamos como nuevo documento
      final newDoc = Document()..insert(0, improved);
      
      setState(() {
        _controller = QuillController(
          document: newDoc, 
          selection: const TextSelection.collapsed(offset: 0)
        );
      });
    } catch (e) {
      debugPrint("Error IA: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error IA: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // --- GENERACIÓN DE IMAGEN (Restaurada de tu archivo original) ---
  void _createAiImage() async {
    String? prompt = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String input = "";
        return AlertDialog(
          title: const Text("🎨 Generar Imagen IA"),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: "Ej: Un profesor explicando..."),
            onChanged: (v) => input = v,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, input), child: const Text("Generar")),
          ],
        );
      }
    );
    if (!mounted) return;
    if (prompt == null || prompt.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎨 Pintando imagen...")));
    try {
      final aiService = await _aiServiceFuture;
      final base64Image = await aiService.generateImage(prompt);
      if (!mounted) return;
      if (base64Image != null && base64Image.isNotEmpty) {
        final formattedImage = base64Image.startsWith('data:image') 
            ? base64Image 
            : 'data:image/png;base64,$base64Image';

        final index = _controller.selection.baseOffset;
        final safeIndex = index < 0 ? 0 : index; // Protección de índice
        
        _controller.document.replace(safeIndex, 0, BlockEmbed.image(formattedImage));
        _controller.moveCursorToPosition(safeIndex + 1);
        _controller.document.insert(safeIndex + 1, '\n');
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Imagen insertada")));
      }
    } catch (e) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error IA: $e")));
    }
  }
  void _initializeEditor() {
    if (widget.initialValue.trim().isEmpty) {
      _controller = QuillController.basic();
    } else {
      try {
        final delta = HtmlToDelta().convert(widget.initialValue);
        if (delta.isEmpty) {
           _controller = QuillController.basic();
        } else {
           _controller = QuillController(
            document: Document.fromDelta(delta),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
      } catch (e) {
        debugPrint("⚠️ Error inicializando. Usando básico.");
        _controller = QuillController.basic();
      }
    }
    _controller.addListener(_onEditorChanged);
  }

  void _onEditorChanged() {
    widget.onChanged(_getHtmlFromDelta(_controller.document.toDelta()));
  }

  @override
  void dispose() {
    _controller.removeListener(_onEditorChanged);
    _controller.dispose();
    _focusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200, 
        child: Center(child: CircularProgressIndicator())
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. CABECERA: ETIQUETA Y CAMPO DE NOMBRE (NUEVO)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Text(
                widget.label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: "Nombre del archivo...",
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.save, color: Colors.blue),
                tooltip: "Guardar contenido",
                onPressed: _generarCurso,
              ),
            ],
          ),
        ),

        // 2. TOOLBAR (BARRA DE HERRAMIENTAS)
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            color: Colors.grey.shade50,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuillToolbar.simple(
                controller: _controller,
                configurations: const QuillSimpleToolbarConfigurations(
                  showFontFamily: false,
                  showFontSize: false,
                  sharedConfigurations: QuillSharedConfigurations(
                    locale: Locale('es'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  alignment: WrapAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _applyAiChange('summarize'),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text(
                        "Reducir",
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade50,
                        foregroundColor: Colors.indigo,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.indigo.shade200),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _applyAiChange('expand'),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text(
                        "Ampliar",
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade50,
                        foregroundColor: Colors.indigo,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.indigo.shade200),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _applyAiChange('fix'),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text(
                        "Mejorar",
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade50,
                        foregroundColor: Colors.indigo,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.indigo.shade200),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _createAiImage,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text(
                        "Generar Imagen",
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade50,
                        foregroundColor: Colors.indigo,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.indigo.shade200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 3. ÁREA DEL EDITOR (SOLUCIÓN AL CRASH DE ALTURA)
        // Usamos altura fija en lugar de Expanded
        Container(
          height: 500, // Altura fija segura
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            color: Colors.white,
          ),
          child: QuillEditor.basic(
            controller: _controller,
            focusNode: _focusNode,
            configurations: QuillEditorConfigurations(
              placeholder: 'Escribe aquí el contenido...',
              sharedConfigurations: const QuillSharedConfigurations(
                locale: Locale('es'),
              ),
              embedBuilders: [
                ImageEmbedBuilder(),
              ],
            ),
          ),
        ),

      ],
    );
  }
}

// =============================================================================
// CLASE AUXILIAR PARA IMÁGENES
// =============================================================================
class ImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node, bool readOnly, bool inline, TextStyle textStyle) {
    final imageUrl = node.value.data as String;

    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIndex = imageUrl.indexOf(',');
        if (commaIndex != -1) {
          final base64Data = imageUrl.substring(commaIndex + 1);
          final bytes = base64Decode(base64Data);
          return Image.memory(bytes);
        }
      } catch (e) {
        return const Icon(Icons.broken_image, color: Colors.red);
      }
    }
    
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
      );
    }

    try {
      return Image.memory(base64Decode(imageUrl));
    } catch (e) {
      return const Icon(Icons.image_not_supported, color: Colors.grey);
    }
  }
}
