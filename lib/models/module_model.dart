import 'interactive_block.dart';
import 'section_model.dart';

class ModuleModel {
  final String id;
  final String title;
  final int order;
  final List<InteractiveBlock> blocks; // Lista de widgets dentro del módulo
  final List<SectionModel> sections;

  ModuleModel({
    required this.id,
    required this.title,
    required this.order,
    required this.blocks,
    List<SectionModel>? sections,
  }) : sections = sections ?? const [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'order': order,
      'blocks': blocks.map((x) => x.toMap()).toList(),
      'sections': sections.map((section) => section.toMap()).toList(),
    };
  }

  factory ModuleModel.fromMap(Map<String, dynamic> map) {
    return ModuleModel(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Nuevo Módulo',
      order: map['order'] ?? 0,
      blocks: List<InteractiveBlock>.from(
        (map['blocks'] as List? ?? []).map<InteractiveBlock>(
          (x) => InteractiveBlock.fromMap(x as Map<String, dynamic>),
        ),
      ),
      sections: List<SectionModel>.from(
        (map['sections'] as List? ?? []).map<SectionModel>(
          (x) => SectionModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}
