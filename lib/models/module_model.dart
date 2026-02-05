import 'interactive_block.dart';

// =============================================================================
// ENUMERACIÓN DE TIPOS (Para que la IA sepa qué generar)
// =============================================================================
enum ModuleType {
  text,         // Teoría (La IA genera texto explicativo)
  quiz,         // Examen (La IA genera preguntas)
  video,        // Video (La IA genera guion)
  interactive,  // Práctica
  tools         // Herramientas
}

// =============================================================================
// CLASE MODULE MODEL
// =============================================================================
class ModuleModel {
  final String id;
  String title; // Quitado 'final' para permitir edición en Dashboard
  int order;    // Quitado 'final' para permitir reordenar
  final List<InteractiveBlock> blocks; // Tu lista de widgets existente

  // ✅ NUEVAS PROPIEDADES PARA LA IA Y EL EDITOR
  String content;  // HTML del contenido (para el WYSIWYG simple)
  ModuleType type; // Tipo de contenido (Contexto para la IA)
  bool isCompleted;
  bool isSource;

  ModuleModel({
    required this.id,
    required this.title,
    required this.order,
    required this.blocks,
    // Valores por defecto para las nuevas propiedades
    this.content = '',
    this.type = ModuleType.text,
    this.isCompleted = false,
    this.isSource = false,
  });

  // ✅ PUENTE JSON
  Map<String, dynamic> toJson() => toMap();
  factory ModuleModel.fromJson(Map<String, dynamic> json) => ModuleModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'order': order,
      'blocks': blocks.map((x) => x.toMap()).toList(),
      // Serializamos lo nuevo
      'content': content,
      'type': type.toString().split('.').last, // Guarda "text", "quiz", etc.
      'is_completed': isCompleted,
      'is_source': isSource,
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
      // Recuperamos lo nuevo
      content: map['content'] ?? '',
      type: _stringToType(map['type'] ?? 'text'),
      isCompleted: map['is_completed'] ?? false,
      isSource: map['is_source'] ?? false,
    );
  }

  // Helper para convertir el String del JSON al Enum correcto
  static ModuleType _stringToType(String typeStr) {
    switch (typeStr) {
      case 'quiz': return ModuleType.quiz;
      case 'video': return ModuleType.video;
      case 'interactive': return ModuleType.interactive;
      case 'tools': return ModuleType.tools;
      case 'text':
      default: return ModuleType.text;
    }
  }
}
