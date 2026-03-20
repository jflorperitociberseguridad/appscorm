import 'module_model.dart';

class CourseModel {
  final String id;
  final String userId; // ID del autor (opcional por ahora)
  final String title;
  final String description;
  final DateTime createdAt;
  final String scormVersion; // "1.2" o "2004"
  final List<ModuleModel> modules;

  CourseModel({
    required this.id,
    this.userId = 'local_user',
    required this.title,
    required this.description,
    required this.createdAt,
    this.scormVersion = '1.2',
    required this.modules,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'scorm_version': scormVersion,
      'modules': modules.map((x) => x.toMap()).toList(),
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? 'local_user',
      title: map['title'] ?? 'Sin Título',
      description: map['description'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      scormVersion: map['scorm_version'] ?? '1.2',
      modules: List<ModuleModel>.from(
        (map['modules'] as List? ?? []).map<ModuleModel>(
          (x) => ModuleModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}