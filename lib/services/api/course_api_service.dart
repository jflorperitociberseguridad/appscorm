import '../../models/course_model.dart';
import '../../models/module_model.dart';
import '../../models/section_model.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

class CourseApiService {
  final ApiClient _client;

  CourseApiService(this._client);

  Future<List<CourseModel>> fetchCourses() async {
    final payload = await _client.get('/courses');
    final rawList = _extractList(payload);
    return rawList.map((course) => CourseModel.fromMap(course)).toList();
  }

  Future<CourseModel> fetchCourse(String courseId) async {
    final payload = await _client.get('/courses/$courseId');
    return CourseModel.fromMap(_extractMap(payload));
  }

  Future<CourseModel> createCourse(CourseModel course) async {
    final payload = await _client.post('/courses', body: course.toMap());
    return CourseModel.fromMap(_extractMap(payload));
  }

  Future<CourseModel> updateCourse(CourseModel course) async {
    final payload = await _client.put('/courses/${course.id}', body: course.toMap());
    return CourseModel.fromMap(_extractMap(payload));
  }

  Future<void> deleteCourse(String courseId) async {
    await _client.delete('/courses/$courseId');
  }

  Future<List<ModuleModel>> fetchModules(String courseId) async {
    final payload = await _client.get('/courses/$courseId/modules');
    final rawList = _extractList(payload);
    return rawList.map((module) => ModuleModel.fromMap(module)).toList();
  }

  Future<ModuleModel> createModule(String courseId, ModuleModel module) async {
    final payload = await _client.post('/courses/$courseId/modules', body: module.toMap());
    return ModuleModel.fromMap(_extractMap(payload));
  }

  Future<ModuleModel> updateModule(ModuleModel module) async {
    final payload = await _client.put('/modules/${module.id}', body: module.toMap());
    return ModuleModel.fromMap(_extractMap(payload));
  }

  Future<List<SectionModel>> fetchSections(String moduleId) async {
    final payload = await _client.get('/modules/$moduleId/sections');
    final rawList = _extractList(payload);
    return rawList.map((section) => SectionModel.fromMap(section)).toList();
  }

  Future<SectionModel> createSection(String moduleId, SectionModel section) async {
    final payload = await _client.post('/modules/$moduleId/sections', body: section.toMap());
    return SectionModel.fromMap(_extractMap(payload));
  }

  Future<SectionModel> updateSection(SectionModel section) async {
    final payload = await _client.put('/sections/${section.id}', body: section.toMap());
    return SectionModel.fromMap(_extractMap(payload));
  }

  List<Map<String, dynamic>> _extractList(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }
    if (payload is Map<String, dynamic>) {
      final candidate = payload['data'] ?? payload['items'] ?? payload['modules'] ?? payload['courses'];
      if (candidate is List) {
        return candidate
            .whereType<Map<String, dynamic>>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList();
      }
    }
    return [];
  }

  Map<String, dynamic> _extractMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (payload.containsKey('course') && payload['course'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(payload['course'] as Map<String, dynamic>);
      }
      return payload;
    }
    throw ApiException('Unexpected payload format');
  }
}
