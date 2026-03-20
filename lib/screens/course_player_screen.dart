import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/course_model.dart';
import '../widgets/interactive_block_renderer.dart';

class CoursePlayerScreen extends StatefulWidget {
  final CourseModel course;

  const CoursePlayerScreen({super.key, required this.course});

  @override
  State<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends State<CoursePlayerScreen> {
  int _currentModuleIndex = 0;
  final ScrollController _scrollController = ScrollController();

  void _nextModule() {
    if (_currentModuleIndex < widget.course.modules.length - 1) {
      setState(() {
        _currentModuleIndex++;
      });
      _scrollToTop();
    } else {
      // Fin del curso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🎉 ¡Has completado el curso!"), backgroundColor: Colors.green),
      );
      context.go('/'); // Volver al inicio
    }
  }

  void _prevModule() {
    if (_currentModuleIndex > 0) {
      setState(() {
        _currentModuleIndex--;
      });
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.course.modules.isEmpty) {
      return const Scaffold(body: Center(child: Text("El curso está vacío.")));
    }

    final currentModule = widget.course.modules[_currentModuleIndex];
    final progress = (_currentModuleIndex + 1) / widget.course.modules.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // BARRA DE PROGRESO
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: Colors.green,
            minHeight: 8,
          ),
          
          // CONTENIDO DEL MÓDULO
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Módulo ${_currentModuleIndex + 1}: ${currentModule.title}",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 24),
                  
                  // LISTA DE BLOQUES
                  ...currentModule.blocks.map((block) => Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: InteractiveBlockRenderer(block: block),
                  )),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
          
          // BARRA DE NAVEGACIÓN INFERIOR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentModuleIndex > 0)
                  OutlinedButton.icon(
                    onPressed: _prevModule,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("ANTERIOR"),
                  )
                else
                  const SizedBox.shrink(), // Espaciador si no hay anterior
                  
                ElevatedButton.icon(
                  onPressed: _nextModule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentModuleIndex == widget.course.modules.length - 1 ? Colors.green : Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  icon: Icon(_currentModuleIndex == widget.course.modules.length - 1 ? Icons.check_circle : Icons.arrow_forward),
                  label: Text(_currentModuleIndex == widget.course.modules.length - 1 ? "FINALIZAR" : "SIGUIENTE"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
