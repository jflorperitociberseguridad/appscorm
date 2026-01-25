import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _storageKey = 'aula_cibermedida_courses_data';

  Future<List<Map<String, dynamic>>> loadCourseList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      
      if (data == null) {
        print("📁 Storage: No hay cursos guardados aún.");
        return [];
      }

      final List<dynamic> decoded = jsonDecode(data);
      print("📁 Storage: Cargados ${decoded.length} cursos.");
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print("❌ Error cargando cursos: $e");
      return [];
    }
  }

  Future<void> saveCourse(Map<String, dynamic> courseData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> currentList = await loadCourseList();

      final index = currentList.indexWhere((c) => c['id'] == courseData['id']);

      if (index >= 0) {
        currentList[index] = courseData;
        print("🔄 Storage: Actualizando curso existente: ${courseData['title']}");
      } else {
        currentList.add(courseData);
        print("➕ Storage: Guardando nuevo curso: ${courseData['title']}");
      }

      // Guardamos y forzamos el guardado
      bool success = await prefs.setString(_storageKey, jsonEncode(currentList));
      if (success) {
        print("✅ Curso guardado correctamente en local");
      } else {
        print("⚠️ No se pudo confirmar el guardado en SharedPreferences");
      }
    } catch (e) {
      print("❌ Error guardando curso: $e");
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> currentList = await loadCourseList();
      
      currentList.removeWhere((c) => c['id'] == courseId);
      await prefs.setString(_storageKey, jsonEncode(currentList));
      print("🗑️ Storage: Curso eliminado: $courseId");
    } catch (e) {
      print("❌ Error borrando curso: $e");
    }
  }
}