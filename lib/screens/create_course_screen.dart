import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/scorm/ai_service.dart';
import '../providers/course_provider.dart';

class CreateCourseScreen extends ConsumerStatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  ConsumerState<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends ConsumerState<CreateCourseScreen> {
  final TextEditingController _textController = TextEditingController();
  // 👇 AQUÍ PEGAS TU CLAVE DE GOOGLE AI STUDIO 👇
  final AiService _aiService = AiService(); 
  
  bool _isLoading = false;
  bool _isAnalyzing = false;
  bool _isOptimizing = false;

  // NUEVA FUNCIÓN: ANALIZAR DOCUMENTO LARGO
  Future<void> _analyzeNotebookMode() async {
    final text = _textController.text.trim();
    if (text.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pega un texto largo o manual para usar este modo.")),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // Llamamos al nuevo método del servicio
      final analysis = await _aiService.analyzeDocument(text);
      
      setState(() {
        _textController.text = analysis; // Reemplazamos el tocho de texto por el análisis estructurado
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Análisis completado. Ahora dale a Generar Curso.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  // NUEVA FUNCIÓN: MEJORAR IDEA
  Future<void> _expandIdea() async {
     final text = _textController.text.trim();
     if (text.isEmpty) return;

     setState(() => _isOptimizing = true);
     try {
       final improved = await _aiService.improveText(text, 'expand');
       setState(() => _textController.text = improved);
     } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
     } finally {
       if (mounted) setState(() => _isOptimizing = false);
     }
  }

  Future<void> _generateCourse(bool isMock) async {
    setState(() => _isLoading = true);

    try {
      final course = isMock 
          ? await _aiService.generateMockCourse()
          : await _aiService.generateCourseFromText(_textController.text);

      ref.read(courseProvider.notifier).setCourse(course);
      
      if (mounted) {
        context.go('/editor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Curso'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pega tu contenido aquí:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Ej. Introducción a la Ciberseguridad...\n\n(El texto será analizado y dividido en módulos automáticamente)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
            // BOTONERA ACTUALIZADA (3 BOTONES)
            Row(
              children: [
                // 1. MODO NOTEBOOKLM (Para textos largos)
                Expanded(
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.teal.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.all(12),
                    ),
                    tooltip: "🧠 Analizar texto (Modo NotebookLM)",
                    icon: _isAnalyzing
                       ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal))
                       : const Icon(Icons.psychology, color: Colors.teal),
                    onPressed: _isAnalyzing || _isLoading ? null : _analyzeNotebookMode,
                  ),
                ),
                const SizedBox(width: 8),

                // 2. MEJORAR IDEA (Para textos cortos)
                Expanded(
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.purple.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.all(12),
                    ),
                    tooltip: "✨ Mejorar título corto",
                    icon: _isOptimizing 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple))
                        : const Icon(Icons.auto_fix_high, color: Colors.purple), 
                    onPressed: _isOptimizing || _isLoading ? null : _expandIdea,
                  ),
                ),
                const SizedBox(width: 8),

                // 3. GENERAR CURSO (El botón principal grande)
                Expanded(
                  flex: 2, // Este ocupa el doble de espacio
                  child: ElevatedButton.icon(
                    onPressed: _isOptimizing || _isLoading || _isAnalyzing ? null : () => _generateCourse(false),
                    icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.rocket_launch),
                    label: Text(_isLoading ? "Creando..." : "GENERAR"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
