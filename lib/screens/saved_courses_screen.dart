import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart'; // ✅ Necesario para elegir el archivo
import 'dart:convert'; // ✅ Para decodificar el JSON
import '../services/storage_service.dart';

class SavedCoursesScreen extends StatefulWidget {
  const SavedCoursesScreen({super.key});

  @override
  State<SavedCoursesScreen> createState() => _SavedCoursesScreenState();
}

class _SavedCoursesScreenState extends State<SavedCoursesScreen> {
  final StorageService _storageService = StorageService();

  // ✅ NUEVA FUNCIÓN: Importar Backup JSON
  Future<void> _importBackup() async {
    try {
      // 1. Seleccionar el archivo del disco duro
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.bytes != null) {
        // 2. Leer los bytes y convertirlos a texto JSON
        final fileBytes = result.files.single.bytes!;
        final String jsonString = utf8.decode(fileBytes);
        
        // 3. Decodificar el JSON a un Mapa
        final Map<String, dynamic> courseData = jsonDecode(jsonString);

        // 4. Validar mínimamente que sea un curso (que tenga ID y Título)
        if (courseData.containsKey('id') && courseData.containsKey('title')) {
          await _storageService.saveCourse(courseData);
          
          if (mounted) {
            setState(() {}); // Refrescar la lista para mostrar el nuevo curso
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Curso importado con éxito"),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception("El archivo no tiene el formato de curso válido.");
        }
      }
    } catch (e) {
      debugPrint("Error importando backup: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error al importar: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Mis Cursos Guardados", 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.indigo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        // ✅ BOTÓN AÑADIDO: Importar JSON
        actions: [
          TextButton.icon(
            onPressed: _importBackup,
            icon: const Icon(Icons.upload_file, size: 20),
            label: const Text("IMPORTAR BACKUP"),
            style: TextButton.styleFrom(foregroundColor: Colors.indigo),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _storageService.loadCourseList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  const Text("No tienes cursos guardados aún.", 
                    style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 10),
                  const Text("Puedes importar un backup con el botón superior.", 
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          final courses = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigoAccent,
                    child: Icon(Icons.book, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    course['title'] ?? 'Sin título',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("ID: ${course['id']}", 
                    style: const TextStyle(fontSize: 10)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.blue),
                        tooltip: "Abrir en el editor",
                        onPressed: () => context.go('/course-dashboard', extra: course),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: "Eliminar permanentemente",
                        onPressed: () => _confirmDelete(context, course),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar curso?"),
        content: Text("Estás a punto de borrar '${course['title']}'. Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              await _storageService.deleteCourse(course['id']);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {}); // Refresca la lista dinámica
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Curso eliminado correctamente"))
                );
              }
            }, 
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}