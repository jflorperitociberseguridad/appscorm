import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

// TUS IMPORTS (Respetados)
import '../providers/api_providers.dart';
import '../providers/course_provider.dart';
import '../services/scorm/scorm_export_service.dart'; 
import '../models/interactive_block.dart';
import '../widgets/wysiwyg_editor.dart'; // Mantenemos tu editor WYSIWYG

// --- EL ÚNICO IMPORT NUEVO ---
import '../widgets/interactive_block_renderer.dart'; 
import '../services/scorm/ai_service.dart'; 

class CourseEditorScreen extends ConsumerStatefulWidget {
  const CourseEditorScreen({super.key});

  @override
  ConsumerState<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _CourseEditorScreenState extends ConsumerState<CourseEditorScreen> {
  final ScormExportService _exportService = ScormExportService();
  bool _isExporting = false;
  bool _isSavingCourse = false;
  int _selectedModuleIndex = 0;

  // --- MENÚ MAESTRO (TU LÓGICA EXACTA CON addDirectBlock) ---
  void _showAddBlockMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Catálogo de Funcionalidades", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                controller: ScrollController(), 
                children: [
                  _buildSectionHeader("Contenido Multimedia"),
                  _buildOption(BlockType.textPlain, "Texto / HTML", Icons.text_fields),
                  _buildOption(BlockType.video, "Video (YouTube/MP4)", Icons.video_library), 
                  _buildOption(BlockType.accordion, "Acordeón", Icons.expand_more),
                  _buildOption(BlockType.column, "Columna", Icons.view_column),
                  _buildOption(BlockType.coursePresentation, "Presentación", Icons.slideshow),
                  _buildOption(BlockType.interactiveBook, "Libro Interactivo", Icons.book),

                  _buildSectionHeader("Interacciones Visuales"),
                  _buildOption(BlockType.imageHotspot, "Image Hotspots", Icons.touch_app),
                  _buildOption(BlockType.findHotspot, "Find the Hotspot", Icons.search),
                  _buildOption(BlockType.findMultipleHotspots, "Find Multiple", Icons.manage_search),
                  _buildOption(BlockType.dragAndDrop, "Drag and Drop", Icons.drag_indicator),

                  _buildSectionHeader("Evaluación y Práctica"),
                  _buildOption(BlockType.singleChoice, "Selección Única", Icons.radio_button_checked),
                  _buildOption(BlockType.multipleChoice, "Selección Múltiple", Icons.check_box),
                  _buildOption(BlockType.trueFalse, "Verdadero/Falso", Icons.rule),
                  _buildOption(BlockType.questionSet, "Conjunto de Preguntas", Icons.quiz),
                  _buildOption(BlockType.fillBlanks, "Rellenar Huecos", Icons.short_text),
                  _buildOption(BlockType.markWords, "Marcar Palabras", Icons.highlight_alt),
                  _buildOption(BlockType.essay, "Ensayo", Icons.edit_note),
                  
                  _buildSectionHeader("Tarjetas y Listas"),
                  _buildOption(BlockType.flashcards, "Flashcards", Icons.style),
                  _buildOption(BlockType.dialogCards, "Dialog Cards", Icons.flip),
                  _buildOption(BlockType.carousel, "Image Carousel", Icons.view_carousel),
                  _buildOption(BlockType.agamotto, "Agamotto (Blender)", Icons.layers),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOption(BlockType type, String label, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.indigo),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {
        Navigator.pop(context);
        final newBlock = InteractiveBlock.create(type: type, content: {});
        // RESTAURADO: Tu llamada a addDirectBlock
        ref.read(courseProvider.notifier).addDirectBlock(_selectedModuleIndex, newBlock);
        
        // RESTAURADO: Tu lógica de auto-apertura
        Future.delayed(const Duration(milliseconds: 300), () {
           final course = ref.read(courseProvider);
           if (course != null) {
              _handleEdit(course.modules[_selectedModuleIndex].blocks.length - 1, newBlock);
           }
        });
      },
    );
  }

  // --- 1. ENRUTADOR DE EDICIÓN INTELIGENTE ---
  void _handleEdit(int index, InteractiveBlock block) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SmartBlockEditor(
        block: block,
        onSave: (newContent) {
          final newBlock = InteractiveBlock(id: block.id, type: block.type, content: newContent);
          ref.read(courseProvider.notifier).updateBlock(_selectedModuleIndex, index, newBlock);
          Navigator.pop(ctx);
          setState(() {});
        },
      ),
    );
  }

  void _deleteBlock(int blockIndex) {
    ref.read(courseProvider.notifier).removeBlock(_selectedModuleIndex, blockIndex);
  }

  Future<void> _exportCourse() async {
    final course = ref.read(courseProvider);
    if (course == null) return;
    setState(() => _isExporting = true);
    try {
      await _exportService.exportCourse(course);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ SCORM exportado'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _saveCourseToApi() async {
    final course = ref.read(courseProvider);
    if (course == null) return;

    if (ref.read(authNotifierProvider).token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Inicia sesión JWT antes de sincronizar con la API.'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }

    setState(() => _isSavingCourse = true);
    try {
      final savedCourse = await ref.read(courseRepositoryProvider).persistCourse(course);
      ref.read(courseProvider.notifier).setCourse(savedCourse);
      await ref.read(coursesListProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Curso sincronizado con la API'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error guardando el curso: $error'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingCourse = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = ref.watch(courseProvider);
    if (course == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text("No hay ningún curso cargado.", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Es necesario crear o seleccionar uno para editarlo."),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text("Volver al Inicio"),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedModuleIndex >= course.modules.length) _selectedModuleIndex = 0;
    final currentModule = course.modules.isNotEmpty ? course.modules[_selectedModuleIndex] : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Aula Cibermedida S.A.'), backgroundColor: Colors.indigo, foregroundColor: Colors.white, actions: [
         Padding(
           padding: const EdgeInsets.only(right: 8),
           child: ElevatedButton.icon(
             onPressed: _isSavingCourse ? null : _saveCourseToApi,
             icon: _isSavingCourse
                 ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                 : const Icon(Icons.cloud_upload),
             label: Text(_isSavingCourse ? "Guardando..." : "Guardar API"),
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.green.shade800,
               foregroundColor: Colors.white,
             ),
           ),
         ),
         Padding(padding: const EdgeInsets.only(right: 16), child: ElevatedButton.icon(onPressed: _exportCourse, icon: const Icon(Icons.download), label: const Text("EXPORTAR SCORM"), style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black)))
      ]),
      body: Row(
        children: [
          // PANEL IZQUIERDO
          Expanded(flex: 2, child: Container(color: Colors.grey[50], child: Column(children: [
            Padding(padding: const EdgeInsets.all(16.0), child: OutlinedButton.icon(onPressed: () => ref.read(courseProvider.notifier).addModule(), icon: const Icon(Icons.add), label: const Text("NUEVO MÓDULO"))),
            Expanded(child: ListView(children: [
              ...course.modules.asMap().entries.map((entry) {
                final isSelected = entry.key == _selectedModuleIndex;
                return ListTile(title: Text(entry.value.title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)), selected: isSelected, selectedTileColor: Colors.indigo[50], onTap: () => setState(() => _selectedModuleIndex = entry.key), trailing: const Icon(Icons.chevron_right));
              }),
            ]))
          ]))),
          
          // PANEL DERECHO
          Expanded(flex: 3, child: Container(color: Colors.white, padding: const EdgeInsets.all(16), child: currentModule == null ? const Center(child: Text("Añade un módulo")) : Column(children: [
            // --- CABECERA MEJORADA CON EXAMINADOR ---
            Row(
              children: [
                Expanded(child: Text(currentModule.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                
                // BOTÓN: GENERAR EXAMEN (5 PREGUNTAS)
                Tooltip(
                  message: "La IA leerá el módulo y creará un examen de 5 preguntas",
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade50, 
                      foregroundColor: Colors.deepOrange,
                      elevation: 0,
                      side: BorderSide(color: Colors.orange.shade200)
                    ),
                    icon: const Icon(Icons.school),
                    label: const Text("Examen IA"),
                    onPressed: () async {
                      // 1. Recopilamos el texto del módulo
                      final sb = StringBuffer();
                      for (var b in currentModule.blocks) {
                        if (b.content['text'] != null) sb.writeln(b.content['text']);
                        if (b.content['caption'] != null) sb.writeln(b.content['caption']);
                        // Si hay acordeones o listas, también podríamos extraerlos
                        if (b.content['items'] != null) sb.writeln(jsonEncode(b.content['items']));
                      }
                      final contextText = sb.toString();

                      if (contextText.length < 50) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Escribe más contenido antes de generar el examen.")));
                        return;
                      }

                      // 2. Feedback visual
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🧠 Leyendo contenido y redactando 5 preguntas...")));

                      // 3. Llamada al servicio
                      final ai = AiService();
                      // AQUÍ PUEDES CAMBIAR EL NÚMERO DE PREGUNTAS (ej: numQuestions: 10)
                      final quizData = await ai.generateQuizFromContext(contextText, numQuestions: 5);

                      if (quizData != null) {
                         // 4. Añadimos el bloque al final
                         final newBlock = InteractiveBlock.create(
                           type: BlockType.questionSet, 
                           content: quizData['content'] ?? quizData // Protegemos si el JSON no tiene 'content' wrapper
                         );
                         ref.read(courseProvider.notifier).addDirectBlock(_selectedModuleIndex, newBlock);
                         
                         // Forzar repintado para ver el bloque nuevo
                         setState(() {}); 
                         
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ ¡Examen añadido al final del módulo!"), backgroundColor: Colors.green));
                      } else {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Error al generar el examen."), backgroundColor: Colors.red));
                      }
                    },
                  ),
                )
              ],
            ),
            const Divider(),
            Expanded(child: ListView.builder(itemCount: currentModule.blocks.length, itemBuilder: (ctx, i) {
              final block = currentModule.blocks[i];
              return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                  child: Column( // Cambiado a Column para soportar cabecera + renderizador
                    children: [
                        // CABECERA (Icono, Título, Acciones)
                        Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                           decoration: BoxDecoration(color: Colors.grey[100], borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                           child: Row(
                             children: [
                               const Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
                               const SizedBox(width: 8),
                               _getIconForType(block.type),
                               const SizedBox(width: 8),
                               // Usamos tu helper _getPreviewText para el subtítulo o el nombre del tipo
                               Expanded(child: Text(block.type.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo), overflow: TextOverflow.ellipsis)),
                               IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _handleEdit(i, block)),
                               IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => ref.read(courseProvider.notifier).removeBlock(_selectedModuleIndex, i)),
                             ],
                           ),
                        ),
                        const Divider(height: 1),
                        // --- AQUÍ ESTÁ EL CAMBIO CLAVE ---
                        // En lugar de usar _SmartBlockPreview (que era texto/icono simple),
                        // usamos el nuevo Renderizador Visual Completo.
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: InteractiveBlockRenderer(block: block),
                        ),
                    ],
                  ),
                );
            })),
            const SizedBox(height: 10),
            ElevatedButton.icon(onPressed: () => _showAddBlockMenu(), icon: const Icon(Icons.add_circle), label: const Text("AÑADIR CONTENIDO"), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)))
          ]))),
        ],
      ),
    );
  }

  // RESTAURADO: Tu helper de iconos original
  Icon _getIconForType(BlockType type) {
    if (type.name.contains('text') || type == BlockType.essay) return const Icon(Icons.article, color: Colors.orange);
    if (type.name.contains('image') || type == BlockType.agamotto || type == BlockType.carousel) return const Icon(Icons.image, color: Colors.blue);
    if (type.name.contains('Choice') || type == BlockType.trueFalse || type == BlockType.questionSet) return const Icon(Icons.quiz, color: Colors.purple);
    if (type == BlockType.fillBlanks || type == BlockType.markWords) return const Icon(Icons.edit_note, color: Colors.teal);
    if (type == BlockType.dragAndDrop || type.name.contains('Hotspot')) return const Icon(Icons.drag_indicator, color: Colors.pink);
    return const Icon(Icons.extension, color: Colors.grey);
  }

  // RESTAURADO: Tu helper de texto preview original (usado internamente si hace falta)
  String _getPreviewText(InteractiveBlock block) {
    final c = block.content;
    if (c['question'] != null) return "Pregunta: ${c['question']}";
    if (c['text'] != null) return c['text'];
    if (c['items'] != null && (c['items'] as List).isNotEmpty) return "Lista de ${(c['items'] as List).length} elementos";
    if (c['url'] != null) return "Recurso Multimedia";
    return 'Elemento configurado';
  }
}


// --- 2. SISTEMA MODULAR DE EDITORES (COMPLETO) ---

class _SmartBlockEditor extends StatelessWidget {
  final InteractiveBlock block;
  final Function(Map<String, dynamic>) onSave;

  const _SmartBlockEditor({required this.block, required this.onSave});

  @override
  Widget build(BuildContext context) {
    if ([BlockType.singleChoice, BlockType.multipleChoice, BlockType.questionSet, BlockType.trueFalse].contains(block.type)) {
      return _QuizEditor(block: block, onSave: onSave);
    }
    if ([BlockType.dialogCards, BlockType.flashcards, BlockType.accordion, BlockType.carousel, BlockType.agamotto].contains(block.type)) {
      return _ListItemsEditor(block: block, onSave: onSave);
    }
    if (block.type == BlockType.video) {
        return _VideoEditor(block: block, onSave: onSave);
    }
    if (block.type == BlockType.textPlain || block.type == BlockType.essay || 
        block.type == BlockType.fillBlanks || block.type == BlockType.markWords) {
      return _TextInteractionEditor(block: block, onSave: onSave);
    }
    if ([BlockType.imageHotspot, BlockType.findHotspot, BlockType.findMultipleHotspots, BlockType.dragAndDrop].contains(block.type)) {
      return _VisualInteractionEditor(block: block, onSave: onSave);
    }
    if ([BlockType.coursePresentation, BlockType.interactiveBook, BlockType.column].contains(block.type)) {
      return _StructureEditor(block: block, onSave: onSave);
    }
    return _GenericEditor(block: block, onSave: onSave);
  }
}

// --- A. EDITOR DE CUESTIONARIOS ---
class _QuizEditor extends StatefulWidget {
  final InteractiveBlock block;
  final Function(Map<String, dynamic>) onSave;
  const _QuizEditor({required this.block, required this.onSave});
  @override State<_QuizEditor> createState() => _QuizEditorState();
}

class _QuizEditorState extends State<_QuizEditor> {
  late TextEditingController _questionCtrl;
  List<Map<String, dynamic>> _options = [];
  bool _boolCorrect = true; 

  @override
  void initState() {
    super.initState();
    _questionCtrl = TextEditingController(text: widget.block.content['question'] ?? '');
    
    if (widget.block.type == BlockType.trueFalse) {
      _boolCorrect = widget.block.content['correctValue'] ?? true;
    } else {
      final rawOpts = widget.block.content['options'];
      if (rawOpts is List) {
         if (rawOpts.isNotEmpty && rawOpts.first is String) {
            int correctIdx = widget.block.content['correctIndex'] ?? 0;
            _options = List<String>.from(rawOpts).asMap().entries.map((e) => {'text': e.value, 'correct': e.key == correctIdx}).toList();
         } else {
            _options = List<Map<String, dynamic>>.from(rawOpts ?? []);
         }
      } else {
         _options = [{'text': 'Opción 1', 'correct': true}, {'text': 'Opción 2', 'correct': false}];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Editor de ${widget.block.type.name}"),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: _questionCtrl, decoration: const InputDecoration(labelText: "Enunciado de la Pregunta", border: OutlineInputBorder())),
              const SizedBox(height: 20),
              
              if (widget.block.type == BlockType.trueFalse) ...[
                const Text("Respuesta Correcta:", style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile(title: const Text("Verdadero"), value: true, groupValue: _boolCorrect, onChanged: (v)=>setState(()=>_boolCorrect=v!)),
                RadioListTile(title: const Text("Falso"), value: false, groupValue: _boolCorrect, onChanged: (v)=>setState(()=>_boolCorrect=v!)),
              ] else ...[
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("Opciones:", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(icon: const Icon(Icons.add), label: const Text("Añadir"), onPressed: () => setState(() => _options.add({'text': '', 'correct': false})))
                ]),
                ..._options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final opt = entry.value;
                  return Card(
                    child: ListTile(
                      leading: Checkbox(
                        value: opt['correct'] ?? false, 
                        onChanged: (v) {
                           setState(() {
                             if (widget.block.type == BlockType.singleChoice) {
                               for(var o in _options) { o['correct'] = false; }
                             }
                             _options[idx]['correct'] = v;
                           });
                        }
                      ),
                      title: TextFormField(
                        initialValue: opt['text'],
                        decoration: const InputDecoration(border: InputBorder.none, hintText: "Texto de la opción"),
                        onChanged: (val) => _options[idx]['text'] = val,
                      ),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => setState(() => _options.removeAt(idx))),
                    ),
                  );
                }),
              ]
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(onPressed: () {
           final content = Map<String, dynamic>.from(widget.block.content);
           content['question'] = _questionCtrl.text;
           if (widget.block.type == BlockType.trueFalse) {
             content['correctValue'] = _boolCorrect;
           } else {
             content['options'] = _options;
           }
           widget.onSave(content);
        }, child: const Text("Guardar Cambios"))
      ],
    );
  }
}

// --- B. EDITOR DE LISTAS ---
class _ListItemsEditor extends StatefulWidget {
  final InteractiveBlock block;
  final Function(Map<String, dynamic>) onSave;
  const _ListItemsEditor({required this.block, required this.onSave});
  @override State<_ListItemsEditor> createState() => _ListItemsEditorState();
}

class _ListItemsEditorState extends State<_ListItemsEditor> {
  late TextEditingController _titleCtrl;
  List<Map<String, String>> _items = [];

  @override
  void initState() {
    super.initState();
     _titleCtrl = TextEditingController(text: widget.block.content['title'] ?? widget.block.content['text'] ?? '');
     final rawItems = widget.block.content['items'];
     if (rawItems is List) {
       _items = List<Map<String, String>>.from(rawItems.map((e) => Map<String, String>.from(e)));
     } else {
       _items = [{'front': 'Cara A', 'back': 'Cara B / Info'}];
     }
  }

  Future<void> _pickImageForItem(int index) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final base64Image = "data:image/png;base64,${base64.encode(bytes)}";
      setState(() {
        _items[index]['front'] = base64Image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = [BlockType.carousel, BlockType.agamotto].contains(widget.block.type);
    
    return AlertDialog(
      title: Text("Editor de ${widget.block.type.name} (Lista)"),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Título / Descripción General", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (ctx, i) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(children: [Text("Elemento ${i+1}", style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(), IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _items.removeAt(i)))]),
                        
                        if (isImage) 
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: Key('item_front_$i'),
                                  initialValue: _items[i]['front'],
                                  decoration: const InputDecoration(labelText: "URL Imagen"),
                                  onChanged: (v) => _items[i]['front'] = v,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.image), 
                                onPressed: () => _pickImageForItem(i),
                                tooltip: "Subir Imagen",
                              )
                            ],
                          )
                        else
                          TextFormField(
                            initialValue: _items[i]['front'],
                            decoration: const InputDecoration(labelText: "Frente / Pregunta"),
                            onChanged: (v) => _items[i]['front'] = v,
                          ),

                        if (isImage && (_items[i]['front'] ?? '').startsWith('data:'))
                           Container(
                             height: 100, 
                             alignment: Alignment.centerLeft,
                             child: Image.memory(base64Decode((_items[i]['front']!).split(',').last), errorBuilder: (_,__,___)=>const SizedBox())
                           ),
                           
                        TextFormField(
                          initialValue: _items[i]['back'],
                          decoration: InputDecoration(labelText: isImage ? "Pie de Foto / Alt" : "Dorso / Respuesta"),
                          onChanged: (v) => _items[i]['back'] = v,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ElevatedButton.icon(onPressed: () => setState(() => _items.add({'front': '', 'back': ''})), icon: const Icon(Icons.add), label: const Text("Añadir Elemento"))
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(onPressed: () {
           final content = Map<String, dynamic>.from(widget.block.content);
           content['text'] = _titleCtrl.text;
           content['items'] = _items;
           widget.onSave(content);
        }, child: const Text("Guardar Cambios"))
      ],
    );
  }
}

// --- C. EDITOR DE INTERACCIONES DE TEXTO (MODO LINUX / SAFE MODE) ---
// --- C. EDITOR DE INTERACCIONES DE TEXTO (MODO RICH TEXT / FLUTTER QUILL) ---
class _TextInteractionEditor extends StatefulWidget {
  final InteractiveBlock block;
  final Function(Map<String, dynamic>) onSave;
  const _TextInteractionEditor({required this.block, required this.onSave});
  @override State<_TextInteractionEditor> createState() => _TextInteractionEditorState();
}

class _TextInteractionEditorState extends State<_TextInteractionEditor> {
  String _currentContent = '';
  final _feedbackCtrl = TextEditingController();
  final _ai = AiService(); 
  bool _isLoadingAi = false;

  @override
  void initState() {
    super.initState();
    _currentContent = widget.block.content['text'] ?? widget.block.content['question'] ?? '';
    _feedbackCtrl.text = widget.block.content['feedback'] ?? '¡Bien hecho!';
  }

  Future<void> _runAi(String mode) async {
    setState(() => _isLoadingAi = true);
    String promptMode = mode;
    if (mode == 'improve') promptMode = 'Mejorar';
    if (mode == 'summarize') promptMode = 'Resumir';
    if (mode == 'expand') promptMode = 'Expandir';
    if (mode == 'fix') promptMode = 'Corregir';

    // Nota: Enviamos el HTML tal cual. La IA suele ser capaz de manejarlo o devolver texto plano.
    // Idealmente se limpiaría el HTML antes, pero por simplicidad probamos así.
    final improved = await _ai.improveText(_currentContent, promptMode);
    
    setState(() {
      _currentContent = improved;
      _isLoadingAi = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEssay = widget.block.type == BlockType.essay;
    final isPlain = widget.block.type == BlockType.textPlain;
    
    String helpText = "Escribe el contenido.";
    if (widget.block.type == BlockType.fillBlanks) helpText = "Usa *asteriscos* para las palabras ocultas. Ej: La casa es *roja*.";
    if (widget.block.type == BlockType.markWords) helpText = "Usa *asteriscos* para la palabra correcta. Ej: Marca el *verbo* en esta frase.";
    
    return AlertDialog(
      title: Text("Editor: ${widget.block.type.name}"),
      content: SizedBox(
        width: 800, 
        height: 600,
        child: Column(
          children: [
               Container(
                 padding: const EdgeInsets.all(8), 
                 color: Colors.blue[50], 
                 child: Row(children: [const Icon(Icons.info, color: Colors.blue), const SizedBox(width: 8), Expanded(child: Text(helpText))])
               ),
               const SizedBox(height: 10),

               // --- BARRA DE HERRAMIENTAS IA ---
               if (_isLoadingAi) 
                  const LinearProgressIndicator()
               else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text("IA Mágica: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ActionChip(avatar: const Icon(Icons.auto_fix_high, size: 16), label: const Text("Mejorar"), onPressed: () => _runAi('improve')),
                        const SizedBox(width: 8),
                        ActionChip(avatar: const Icon(Icons.short_text, size: 16), label: const Text("Resumir"), onPressed: () => _runAi('summarize')),
                        const SizedBox(width: 8),
                        ActionChip(avatar: const Icon(Icons.playlist_add, size: 16), label: const Text("Expandir"), onPressed: () => _runAi('expand')),
                        const SizedBox(width: 8),
                        ActionChip(avatar: const Icon(Icons.spellcheck, size: 16), label: const Text("Corregir"), onPressed: () => _runAi('fix')),
                      ],
                    ),
                  ),
               const SizedBox(height: 10),
               
               // --- WYSIWYG EDITOR ---
               Expanded(
                 child: WysiwygEditor(
                   initialContent: _currentContent,
                   label: "Contenido",
                   onChanged: (val) {
                     // Actualizamos variable local pero SIN setState para no resetear el editor mientras escribes
                     _currentContent = val;
                   },
                 ),
               ),
               
               if (!isPlain) ...[
                 const SizedBox(height: 10),
                 TextField(controller: _feedbackCtrl, decoration: const InputDecoration(labelText: "Mensaje de Retroalimentación", border: OutlineInputBorder())),
               ]
            ],
          ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(onPressed: () {
           final c = Map<String, dynamic>.from(widget.block.content);
           c['text'] = _currentContent;
           c['question'] = _currentContent; 
           c['feedback'] = _feedbackCtrl.text;
           widget.onSave(c);
        }, child: const Text("Guardar"))
      ],
    );
  }
}
// --- D. EDITOR VISUAL & HOTSPOTS ---
class _VisualInteractionEditor extends StatefulWidget {
  final InteractiveBlock block;
  final Function(Map<String, dynamic>) onSave;
  const _VisualInteractionEditor({required this.block, required this.onSave});
  @override State<_VisualInteractionEditor> createState() => _VisualInteractionEditorState();
}

class _VisualInteractionEditorState extends State<_VisualInteractionEditor> {
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  List<Map<String, dynamic>> _zones = [];

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = widget.block.content['url'] ?? 'https://placehold.co/600x400';
    _titleCtrl.text = widget.block.content['title'] ?? widget.block.content['question'] ?? '';
    if (widget.block.content['zones'] != null) {
      _zones = List<Map<String, dynamic>>.from(widget.block.content['zones']);
    } else {
      _zones = [{'label': 'Zona 1', 'x': 50, 'y': 50}];
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final base64Image = "data:image/png;base64,${base64.encode(bytes)}";
      setState(() {
        _urlCtrl.text = base64Image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Configurar ${widget.block.type.name}"),
      content: SizedBox(
        width: 600,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Título / Instrucción", border: OutlineInputBorder())),
               const SizedBox(height: 10),
               Row(
                 children: [
                   Expanded(child: TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: "URL Imagen", border: OutlineInputBorder()))),
                   const SizedBox(width: 8),
                   // Botón Subir
                   IconButton(
                     icon: const Icon(Icons.upload_file, color: Colors.blue),
                     tooltip: "Subir archivo local",
                     onPressed: _pickImage,
                   ),
                   // Botón Generar IA
                   IconButton(
                     icon: const Icon(Icons.auto_awesome, color: Colors.pink),
                     tooltip: "Generar con IA",
                     onPressed: () async {
                        // Usamos el título como prompt por defecto
                        final prompt = _titleCtrl.text.isNotEmpty ? _titleCtrl.text : "illustration";
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("🎨 Generando imagen para: $prompt...")));
                        
                        final ai = AiService();
                        final url = await ai.generateImage(prompt);
                        setState(() => _urlCtrl.text = url);
                     },
                   )
                 ],
               ),
               if (_urlCtrl.text.isNotEmpty) 
                 Padding(
                   padding: const EdgeInsets.symmetric(vertical: 10),
                   child: SizedBox(
                     height: 150, 
                     child: _urlCtrl.text.startsWith('data:') 
                         ? Image.memory(base64Decode(_urlCtrl.text.split(',').last), fit: BoxFit.contain)
                         : Image.network(_urlCtrl.text, fit: BoxFit.contain, errorBuilder: (_,__,___)=>const Icon(Icons.broken_image))
                   ),
                 ),
               
               const SizedBox(height: 20),
               Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                 const Text("Zonas Interactivas (Spots):", style: TextStyle(fontWeight: FontWeight.bold)),
                 TextButton.icon(icon: const Icon(Icons.add_location), label: const Text("Añadir Zona"), onPressed: () => setState(() => _zones.add({'label': 'Nueva Zona', 'x': 10, 'y': 10})))
               ]),
               const Text("Define las coordenadas (0-100%) donde el usuario debe interactuar.", style: TextStyle(fontSize: 12, color: Colors.grey)),
               
               ..._zones.asMap().entries.map((e) => Card(
                 child: Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: Row(
                     children: [
                       Expanded(flex: 2, child: TextFormField(initialValue: e.value['label'], decoration: const InputDecoration(labelText: "Etiqueta"), onChanged: (v) => e.value['label'] = v)),
                       const SizedBox(width: 8),
                       Expanded(child: TextFormField(initialValue: e.value['x'].toString(), decoration: const InputDecoration(labelText: "X %"), keyboardType: TextInputType.number, onChanged: (v) => e.value['x'] = int.tryParse(v) ?? 0)),
                       const SizedBox(width: 8),
                       Expanded(child: TextFormField(initialValue: e.value['y'].toString(), decoration: const InputDecoration(labelText: "Y %"), keyboardType: TextInputType.number, onChanged: (v) => e.value['y'] = int.tryParse(v) ?? 0)),
                       IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _zones.removeAt(e.key)))
                     ],
                   ),
                 ),
               )),
            ],
          ),
        ),
      ),
      actions: [
         TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
         ElevatedButton(onPressed: () {
           final c = Map<String, dynamic>.from(widget.block.content);
           c['url'] = _urlCtrl.text;
           c['title'] = _titleCtrl.text;
           c['question'] = _titleCtrl.text;
           c['zones'] = _zones;
           widget.onSave(c);
         }, child: const Text("Guardar"))
      ],
    );
  }
}

// --- E. EDITOR DE ESTRUCTURA ---
class _StructureEditor extends StatefulWidget {
  final InteractiveBlock block;
  final Function(Map<String, dynamic>) onSave;
  const _StructureEditor({required this.block, required this.onSave});
  @override State<_StructureEditor> createState() => _StructureEditorState();
}

class _StructureEditorState extends State<_StructureEditor> {
  final _titleCtrl = TextEditingController();
  List<String> _sections = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.block.content['title'] ?? 'Mi Contenido';
    if (widget.block.content['sections'] != null) {
       _sections = List<String>.from(widget.block.content['sections']);
    } else {
       _sections = ['Sección 1', 'Sección 2'];
    }
  }

  @override
  Widget build(BuildContext context) {
    String itemLabel = "Sección";
    if (widget.block.type == BlockType.coursePresentation) itemLabel = "Diapositiva";
    
    return AlertDialog(
      title: Text("Estructura: ${widget.block.type.name}"),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          children: [
             TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Título Principal", border: OutlineInputBorder())),
             const SizedBox(height: 10),
             Expanded(
               child: ListView.builder(
                 itemCount: _sections.length,
                 itemBuilder: (ctx, i) => ListTile(
                   leading: CircleAvatar(child: Text("${i+1}")),
                   title: TextFormField(
                     initialValue: _sections[i],
                     decoration: InputDecoration(labelText: "$itemLabel ${i+1}"),
                     onChanged: (v) => _sections[i] = v,
                   ),
                   trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _sections.removeAt(i))),
                 ),
               ),
             ),
             ElevatedButton.icon(onPressed: () => setState(() => _sections.add("Nueva $itemLabel")), icon: const Icon(Icons.add), label: const Text("Añadir Elemento"))
          ],
        ),
      ),
      actions: [
         TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
         ElevatedButton(onPressed: () {
           final c = Map<String, dynamic>.from(widget.block.content);
           c['title'] = _titleCtrl.text;
           c['sections'] = _sections;
           widget.onSave(c);
         }, child: const Text("Guardar"))
      ],
    );
  }
}

// --- F. EDITOR GENÉRICO SIMPLE ---
class _GenericEditor extends StatefulWidget {
  final InteractiveBlock block;
  final Function(Map<String, dynamic>) onSave;
  const _GenericEditor({required this.block, required this.onSave});
  @override State<_GenericEditor> createState() => _GenericEditorState();
}

class _GenericEditorState extends State<_GenericEditor> {
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textCtrl.text = widget.block.content['text'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Opción: ${widget.block.type.name}"),
      content: TextField(controller: _textCtrl, maxLines: 5, decoration: const InputDecoration(labelText: "Configuración JSON / Texto", border: OutlineInputBorder())),
      actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () {
             final c = Map<String, dynamic>.from(widget.block.content);
             c['text'] = _textCtrl.text;
             widget.onSave(c);
          }, child: const Text("Guardar"))
      ],
    );
  }
}

// --- VIDEO EDITOR ---
class _VideoEditor extends StatefulWidget {
  final InteractiveBlock block;
  final Function(Map<String, dynamic>) onSave;
  const _VideoEditor({required this.block, required this.onSave});
  @override State<_VideoEditor> createState() => _VideoEditorState();
}

class _VideoEditorState extends State<_VideoEditor> {
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlCtrl.text = widget.block.content['url'] ?? '';
    _titleCtrl.text = widget.block.content['title'] ?? widget.block.content['description'] ?? '';
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final base64Video = "data:video/mp4;base64,${base64.encode(bytes)}";
      setState(() {
         _urlCtrl.text = base64Video; 
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video cargado. Guardar puede tardar un poco.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBase64 = _urlCtrl.text.startsWith('data:');
    return AlertDialog(
      title: const Text("Editor de Video"),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Título del Video", border: OutlineInputBorder())),
            const SizedBox(height: 15),
              Row(
              children: [
                Expanded(child: TextField(controller: _urlCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "URL Video", border: OutlineInputBorder(), hintText: "https://youtube.com/..."))),
                const SizedBox(width: 10),
                Column(
                  children: [
                    IconButton(onPressed: _pickVideo, icon: const Icon(Icons.video_file, color: Colors.deepOrange), tooltip: "Subir Video Local"),
                    // Botón Sugerir IA
                    IconButton(
                      icon: const Icon(Icons.movie_filter, color: Colors.purple), 
                      tooltip: "Sugerir Video IA",
                      onPressed: () async {
                         final topic = _titleCtrl.text.isNotEmpty ? _titleCtrl.text : "general";
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎬 Buscando el mejor video...")));
                         final ai = AiService();
                         final content = await ai.suggestVideoContent(topic);
                         
                         setState(() {
                            // Si sugiere una URL válida, la ponemos
                            if (content['url'] != null && content['url']!.isNotEmpty) {
                               _urlCtrl.text = content['url']!;
                            }
                            // Si sugiere un mejor título
                            if (content['title'] != null) {
                               // No sobreescribimos título si ya tiene uno, o preguntamos. 
                               // Aquí lo dejamos opcional/informativo
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sugerencia: ${content['title']}")));
                            }
                         });
                      }
                    ),
                  ],
                )
              ],
            ),
            if (isBase64) 
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("⚠️ Video local seleccionado.", style: TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            if (!isBase64 && _urlCtrl.text.isNotEmpty)
               const Padding(
                 padding: EdgeInsets.all(8.0),
                 child: Text("ℹ️ Se usará como video externo (streaming). Requiere internet.", style: TextStyle(color: Colors.blue, fontSize: 12)),
               )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(onPressed: () {
          widget.onSave({
            'url': _urlCtrl.text,
            'title': _titleCtrl.text
          });
        }, child: const Text("Guardar"))
      ],
    );
  }
}

// --- RESTAURADO: SMART PREVIEW COMPONENT ---
class _SmartBlockPreview extends StatelessWidget {
  final InteractiveBlock block;
  const _SmartBlockPreview({required this.block});

  @override
  Widget build(BuildContext context) {
    Widget? mediaPreview;
    String? thumbUrl;
    
    if ([BlockType.imageHotspot, BlockType.findHotspot, BlockType.dragAndDrop].contains(block.type)) {
      thumbUrl = block.content['url'];
    } else if ([BlockType.carousel, BlockType.agamotto, BlockType.dialogCards].contains(block.type)) {
      final items = block.content['items'] as List?;
      if (items != null && items.isNotEmpty && items[0]['front'] != null) {
        String front = items[0]['front'];
        if (front.startsWith('http') || front.startsWith('data:')) thumbUrl = front;
      }
    } else if (block.type == BlockType.video) {
        return Row(children: [
        Container(width: 80, height: 60, color: Colors.black12, child: const Icon(Icons.play_circle_fill, size: 40, color: Colors.redAccent)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(block.content['title'] ?? 'Video', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text("Video Multimedia", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]))
      ]);
    }

    if (thumbUrl != null && thumbUrl.isNotEmpty) {
      mediaPreview = Container(
        width: 80, height: 60,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4), color: Colors.grey.shade100),
        child: thumbUrl.startsWith('data:') 
            ? Image.memory(base64Decode(thumbUrl.split(',').last), fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.broken_image))
            : Image.network(thumbUrl, fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.broken_image)),
      );
    }

    String title = "Nuevo ${block.type.name}";
    String subtitle = "";
    
    if (block.content['title'] != null && block.content['title'].toString().isNotEmpty) {
      title = block.content['title'];
    } else if (block.content['question'] != null) {
      title = block.content['question'];
    } else if (block.content['text'] != null) {
      title = block.content['text'].toString().replaceAll(RegExp(r'<[^>]*>'), '');
      if (title.length > 50) title = "${title.substring(0, 50)}...";
    } else if (block.type == BlockType.accordion) {
       title = "Grupo de Acordeón";
       final count = (block.content['items'] as List?)?.length ?? 0;
       subtitle = "$count elementos";
    }

    return Row(
      children: [
        if (mediaPreview != null) mediaPreview,
        if (mediaPreview == null) Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle), child: const Icon(Icons.extension, color: Colors.indigo, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))
        ]))
      ],
    );
  }
}
