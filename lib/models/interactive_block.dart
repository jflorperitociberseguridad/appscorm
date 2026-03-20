import 'package:uuid/uuid.dart';

enum BlockType {
  interactiveBook, column, accordion, coursePresentation, carousel,
  textPlain, imageHotspot, agamotto, findHotspot, findMultipleHotspots,
  dragAndDrop, markWords, dialogCards, fillBlanks, flashcards,
  trueFalse, singleChoice, multipleChoice, questionSet, essay, video,
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
    final type = BlockType.values.firstWhere(
        (e) => e.name == typeStr, 
        orElse: () => BlockType.unknown
    );
    final content = Map<String, dynamic>.from(map['content'] ?? {});
    final id = map['id'] ?? const Uuid().v4();

    if (type == BlockType.textPlain) {
      return TextBlock(id: id, content: content['text'] ?? '');
    } else if (type == BlockType.imageHotspot || type == BlockType.findHotspot) {
      return ImageBlock(
        id: id, 
        url: content['url'] ?? 'https://placehold.co/600x400', 
        caption: content['caption'] ?? ''
      );
    } else if (type == BlockType.multipleChoice || type == BlockType.singleChoice || type == BlockType.trueFalse || type == BlockType.questionSet) {
      return QuestionBlock(
        id: id,
        question: content['question'] ?? 'Pregunta...',
        options: List<String>.from(content['options'] ?? []),
        correctIndex: content['correctIndex'] ?? 0,
        type: type 
      );
    }

    return InteractiveBlock(id: id, type: type, content: content);
  }
}

// SUBCLASES NECESARIAS
class TextBlock extends InteractiveBlock {
  TextBlock({required super.id, required String content})
      : super(type: BlockType.textPlain, content: {'text': content});
}

class ImageBlock extends InteractiveBlock {
  ImageBlock({required super.id, required String url, String caption = ''})
      : super(type: BlockType.imageHotspot, content: {'url': url, 'caption': caption});
  String get url => content['url'];
  String get caption => content['caption'];
}

class QuestionBlock extends InteractiveBlock {
  QuestionBlock({
    required super.id, required String question, List<String> options = const [], int correctIndex = 0, super.type = BlockType.multipleChoice,
  }) : super(content: {'question': question, 'options': options, 'correctIndex': correctIndex});
  String get question => content['question'];
  List<String> get options => List<String>.from(content['options'] ?? []);
  int get correctIndex => content['correctIndex'];
}