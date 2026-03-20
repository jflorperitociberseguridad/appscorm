import 'package:uuid/uuid.dart';

class SectionModel {
  final String id;
  final String moduleId;
  final String title;
  final int order;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime updatedAt;

  SectionModel({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.order,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : payload = payload ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  SectionModel copyWith({
    String? title,
    int? order,
    Map<String, dynamic>? payload,
    DateTime? updatedAt,
  }) {
    return SectionModel(
      id: id,
      moduleId: moduleId,
      title: title ?? this.title,
      order: order ?? this.order,
      payload: payload ?? Map<String, dynamic>.from(this.payload),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'order': order,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SectionModel.fromMap(Map<String, dynamic> map) {
    return SectionModel(
      id: map['id'] ?? const Uuid().v4(),
      moduleId: map['module_id'] ?? '',
      title: map['title'] ?? 'Nueva Sección',
      order: map['order'] ?? 0,
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}
