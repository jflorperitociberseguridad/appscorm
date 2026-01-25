import 'package:uuid/uuid.dart';

// ✅ ENUM COMPLETO CON LAS 22 FUNCIONALIDADES
enum BlockType {
  // --- ESTRUCTURA Y VISUAL BÁSICO ---
  textPlain, textRich, 
  image, video, audio, pdf,
  accordion, tabs, process, timeline, comparison, carousel,
  
  // --- INTERACTIVOS / QUIZ ---
  singleChoice, multipleChoice, trueFalse, fillBlanks, 
  sorting, matching,
  flashcards, stats,
  
  // --- VISUALES EXTRA (WOW) ---
  flipCard, quote, embed, imageHotspot, scenario,

  // --- LEGACY / FUTUROS ---
  interactiveBook, column, coursePresentation, agamotto,
  dragAndDrop, markWords, dialogCards, findHotspot, findMultipleHotspots,
  urlResource, questionSet, essay,

  // --- FALLBACK ---
  unknown
}

class InteractiveBlock {
  final String id;
  final BlockType type;
  final Map<String, dynamic> content;

  InteractiveBlock({
    required this.id,
    required this.type,
    required this.content,
  });

  Map<String, dynamic> toJson() => toMap();
  factory InteractiveBlock.fromJson(Map<String, dynamic> json) => InteractiveBlock.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
    };
  }

  factory InteractiveBlock.create({required BlockType type, required Map<String, dynamic> content}) {
    return InteractiveBlock(id: const Uuid().v4(), type: type, content: content);
  }

  factory InteractiveBlock.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'unknown';
    
    // Buscamos el tipo en el ENUM de forma segura
    final type = BlockType.values.firstWhere(
        (e) => e.name == typeStr, 
        orElse: () => BlockType.unknown
    );
    
    final content = Map<String, dynamic>.from(map['content'] ?? {});
    final id = map['id'] ?? const Uuid().v4();

    // RENDERIZACIÓN DE SUBCLASES
    switch (type) {
      case BlockType.textPlain:
      case BlockType.textRich:
      case BlockType.essay:
        // 🔴 CORRECCIÓN CRÍTICA AQUÍ:
        // Evitamos que el texto sea '' (vacío) porque rompe el editor (Document Delta error).
        // Si es nulo o vacío, ponemos un espacio en blanco " ".
        String safeText = content['text']?.toString() ?? ' ';
        if (safeText.trim().isEmpty) safeText = ' ';

        return TextBlock(id: id, content: safeText);
        
      case BlockType.image:
      case BlockType.imageHotspot:
      case BlockType.agamotto:
        return ImageBlock(
          id: id, 
          url: content['url'] ?? 'https://placehold.co/600x400', 
          caption: content['caption'] ?? '',
          type: type 
        );
        
      case BlockType.multipleChoice:
      case BlockType.singleChoice:
      case BlockType.trueFalse:
      case BlockType.questionSet:
        return QuestionBlock(
          id: id,
          question: content['question'] ?? 'Pregunta...',
          options: (content['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
          correctIndex: content['correctIndex'] ?? 0,
          type: type 
        );
        
      case BlockType.video:
        return VideoBlock(
          id: id,
          url: content['url'] ?? '',
          isLocal: content['isLocal'] ?? false,
        );

      default:
        return InteractiveBlock(id: id, type: type, content: content);
    }
  }
}

// --- SUBCLASES ---

class TextBlock extends InteractiveBlock {
  TextBlock({required String id, required String content})
      : super(id: id, type: BlockType.textPlain, content: {'text': content});
  
  String get text => content['text'] ?? ' ';
}

class ImageBlock extends InteractiveBlock {
  ImageBlock({
    required String id, 
    required String url, 
    String caption = '', 
    BlockType type = BlockType.image 
  }) : super(id: id, type: type, content: {'url': url, 'caption': caption});

  String get url => content['url'];
  String get caption => content['caption'];
}

class QuestionBlock extends InteractiveBlock {
  QuestionBlock({
    required String id, 
    required String question, 
    List<String> options = const [], 
    int correctIndex = 0, 
    required BlockType type,
  }) : super(id: id, type: type, content: {
    'question': question, 
    'options': options, 
    'correctIndex': correctIndex
  });
  
  String get question => content['question'];
  List<String> get options => List<String>.from(content['options'] ?? []);
  int get correctIndex => content['correctIndex'];
}

class VideoBlock extends InteractiveBlock {
  VideoBlock({
    required String id,
    required String url,
    bool isLocal = false,
  }) : super(id: id, type: BlockType.video, content: {
    'url': url,
    'isLocal': isLocal,
  });

  String get url => content['url'];
  bool get isLocal => content['isLocal'];
}
