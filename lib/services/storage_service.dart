import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _storageKey = 'aula_cibermedida_courses_data';

  Future<List<Map<String, dynamic>>> loadCourseList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_storageKey);
      
      if (data == null) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(data);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
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
      } else {
        currentList.add(courseData);
      }

      await prefs.setString(_storageKey, jsonEncode(currentList));
    } catch (_) {
      // Se ignora para permitir una salida segura.
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> currentList = await loadCourseList();
      
      currentList.removeWhere((c) => c['id'] == courseId);
      await prefs.setString(_storageKey, jsonEncode(currentList));
    } catch (_) {
      // Se ignora para permitir una salida segura.
    }
  }
}
