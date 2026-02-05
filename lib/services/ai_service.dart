import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'config/secret_loader.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/course_model.dart';
import '../models/module_model.dart';
import '../models/interactive_block.dart';
import 'package:scorm_master/services/ai/ai_prompts.dart';

class AiService {
  // ===========================================================================
  // 🔑 ZONA DE CLAVES API
  // ===========================================================================
  static const String _huggingFaceToken = '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';
  // ===========================================================================
  final Uuid _uuid = const Uuid();
  final GenerativeModel? _textModel;

  AiService._(this._textModel);

  static const _geminiKeyName = 'gemini_api_key';

  static Future<AiService> create() async {
    final secrets = await SecretLoader.load();
    final apiKey = secrets[_geminiKeyName] ?? '';
    if (apiKey.isEmpty) {
      debugPrint(
        '⚠️ gemini_api_key ausente en secrets.json. Las llamadas a Gemini se desactivan hasta que se añada la clave.',
      );
    }
    final model = apiKey.isNotEmpty
        ? GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey)
        : null;
    return AiService._(model);
  }

  Future<CourseModel> generateMockCourse() async {
    return _generateVisualFallback("Curso de Prueba (Mock)");
  }

  // 1. EL ARQUITECTO (Generador Maestro)
  Future<CourseModel> generateCourseFromText(String text, {Map<String, dynamic>? config}) async {
    try {
      if (!_hasGeminiKey()) return _generateVisualFallback(text);
      debugPrint("🚀 [AI] Generando curso...");
      final prompt = AiPrompts.generateCourse(text, config: config);
      final response = await _textModel!.generateContent([Content.text(prompt)]);
      
      final rawText = response.text;
      if (rawText != null && rawText.isNotEmpty) {
        final parsed = await compute<_ParseCourseResultPayload, Object?>(
          _parseCourseResult,
          _ParseCourseResultPayload.course(rawText),
        );
        if (parsed is CourseModel) {
          debugPrint("✅ [AI] JSON válido. Mapeando estructura...");
          return parsed;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error Generación: $e");
    }
    return _generateVisualFallback(text);
  }

  // 2. EL PINTOR PRO (Imágenes)
  Future<String?> generateImage(String prompt) async {
    const modelUrl = "https://api-inference.huggingface.co/models/runwayml/stable-diffusion-v1-4";
    try {
      final response = await http.post(
        Uri.parse(modelUrl),
        headers: {
          "Authorization": "Bearer $_huggingFaceToken",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "inputs": "educational illustration, clear, 4k, $prompt", 
          "parameters": {"negative_prompt": "blurry, text, watermark"} 
        }),
      );
      if (response.statusCode == 200) {
        return "data:image/jpeg;base64,${base64Encode(response.bodyBytes)}";
      }
    } catch (e) {
      debugPrint("Error Imagen: $e");
    }
    return null;
  }

  // 3. EL EDITOR (Mejorar texto)
  Future<String> improveText(String originalText, {String mode = 'fix'}) async {
    try {
      if (!_hasGeminiKey()) return originalText;
      final response = await _textModel!.generateContent([
        Content.text(AiPrompts.improveText(originalText, mode))
      ]);
      // IMPORTANTE: Aseguramos que nunca devuelva vacío
      String res = response.text?.replaceAll(RegExp(r'[*#_`]'), '').trim() ?? originalText;
      return res.isEmpty ? originalText : res;
    } catch (e) {
      return originalText;
    }
  }

  // 4. EL PRODUCTOR (Video)
  Future<Map<String, String>> suggestVideoContent(String topic) async {
    try {
      if (!_hasGeminiKey()) return {'url': '', 'title': topic, 'description': ''};
      final response = await _textModel!.generateContent([
        Content.text(AiPrompts.suggestVideo(topic))
      ]);
      if (response.text != null) {
        final data = jsonDecode(_cleanJson(response.text!));
        final searchTerm = data['search'] ?? topic;
        return {
          'url': "https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchTerm)}",
          'title': "Video sugerido: $searchTerm",
          'description': data['script'] ?? "Video relacionado"
        };
      }
    } catch (e) {
      debugPrint("Error Video: $e");
    }
    return {'url': '', 'title': topic, 'description': ''};
  }
  // 5. MODO NOTEBOOKLM (Analizador de documentos)
  Future<String> analyzeDocument(String rawText) async {
    try {
      if (!_hasGeminiKey()) return "Sin análisis disponible.";
      final response = await _textModel!.generateContent([
        Content.text(AiPrompts.analyzeDocument(rawText))
      ]);
      // Aseguramos que nunca devuelva vacío
      String text = response.text?.replaceAll('*', '').replaceAll('#', '').trim() ?? "";
      return text.isEmpty ? "Sin análisis disponible." : text;
    } catch (e) {
      return "Error analizando documento: $e";
    }
  }

  // 6. ASISTENTE DE BLOQUE (Universal Block Constructor)
  Future<Map<String, dynamic>> assistBlock(BlockType type, String topic, {String? extraContext}) async {
    try {
      if (!_hasGeminiKey()) return {};
      final prompt = AiPrompts.assistBlock(type, topic, extraContext);
      final response = await _textModel!.generateContent([Content.text(prompt)]);
      
      final text = response.text;
      if (text != null) {
        final clean = _cleanJson(text);
        try {
            final decoded = jsonDecode(clean);
            return decoded is Map<String, dynamic> ? decoded : {};
        } catch (e) {
            return {};
        }
      }
      return {};
    } catch (e) {
      debugPrint("Error en assistBlock: $e");
      return {};
    }
  }

  // 7. GENERADOR DE QUIZ (Evaluación)
  Future<CourseModel> generateQuizFromContext(String contextText, int numQuestions) async {
    try {
      if (!_hasGeminiKey()) return _generateVisualFallback("Error en Quiz");
      final prompt = AiPrompts.generateQuiz(contextText, numQuestions);
      final response = await _textModel!.generateContent([Content.text(prompt)]);
      
      final text = response.text;
      if (text == null) return _generateVisualFallback("Error en Quiz");

      final clean = _cleanJson(text);
      final decoded = jsonDecode(clean);
      
      if (decoded is Map<String, dynamic>) {
        return _mapJsonToCourse(decoded);
      }
      return _generateVisualFallback("Formato de Quiz inválido");
    } catch (e) {
      return _generateVisualFallback("Error generando Quiz: $e");
    }
  }


  Future<SectionGenerationResult> generateSectionContent({
    required int sectionIndex,
    required String sectionName,
    required String context,
    required Map<String, String> panelConfig,
  }) async {
    final defaultResult = SectionGenerationResult(
      title: sectionName,
      content: '',
      format: _formatForSection(sectionIndex),
    );

    if (!_hasGeminiKey()) return defaultResult;

    try {
      final prompt = AiPrompts.generateSectionContent(
        sectionIndex: sectionIndex,
        sectionName: sectionName,
        context: context,
        audience: panelConfig['audience'] ?? 'General',
        tone: panelConfig['tone'] ?? 'Profesional',
        methodology: panelConfig['methodology'] ?? 'Expositiva',
      );

      final response = await _textModel!.generateContent([Content.text(prompt)]);
      final rawText = response.text;
      if (rawText == null || rawText.isEmpty) return defaultResult;

      final result = await compute<_ParseCourseResultPayload, Object?>(
        _parseCourseResult,
        _ParseCourseResultPayload.section(
          response: rawText,
          sectionIndex: sectionIndex,
          sectionName: sectionName,
        ),
      );
      if (result is SectionGenerationResult) {
        return result;
      }
    } catch (e) {
      debugPrint("⚠️ Error generando sección: $e");
      return defaultResult;
    }
    return defaultResult;
  }

  // ===========================================================================
  // 🛠️ MÉTODOS PRIVADOS (BLINDAJE TOTAL CONTRA CRASHES)
  // ===========================================================================
  bool _hasGeminiKey() {
    if (_textModel == null) {
      debugPrint("⚠️ gemini_api_key no configurada. Se omite llamada a Gemini.");
      return false;
    }
    return true;
  }

  CourseModel _generateVisualFallback(String text) {
    return CourseModel(
      id: _uuid.v4(),
      title: "Respuesta Parcial",
      description: "Se ha recuperado el contenido parcialmente.",
      createdAt: DateTime.now(),
      modules: [
        ModuleModel(
          id: _uuid.v4(), 
          title: "Contenido", 
          order: 0, 
          blocks: [
            InteractiveBlock.create(
              type: BlockType.textPlain, 
              // Ponemos texto por defecto si viene vacío
              content: {"text": text.isNotEmpty ? text : "Contenido no disponible."}
            )
          ]
        )
      ]
    );
  }
}

class SectionGenerationResult {
  final String title;
  final String content;
  final String format;

  const SectionGenerationResult({
    required this.title,
    required this.content,
    this.format = 'text',
  });
}

enum _ParseTarget { course, section }

class _ParseCourseResultPayload {
  final String response;
  final _ParseTarget target;
  final int? sectionIndex;
  final String? sectionName;

  const _ParseCourseResultPayload._({
    required this.response,
    required this.target,
    this.sectionIndex,
    this.sectionName,
  });

  factory _ParseCourseResultPayload.course(String response) {
    return _ParseCourseResultPayload._(
      response: response,
      target: _ParseTarget.course,
    );
  }

  factory _ParseCourseResultPayload.section({
    required String response,
    required int sectionIndex,
    required String sectionName,
  }) {
    return _ParseCourseResultPayload._(
      response: response,
      target: _ParseTarget.section,
      sectionIndex: sectionIndex,
      sectionName: sectionName,
    );
  }
}

FutureOr<Object?> _parseCourseResult(_ParseCourseResultPayload payload) {
  switch (payload.target) {
    case _ParseTarget.course:
      try {
        final clean = _cleanJson(payload.response);
        final decoded = jsonDecode(clean);
        if (decoded is Map<String, dynamic>) {
          return _mapJsonToCourse(decoded);
        }
      } catch (_) {
        return null;
      }
      return null;
    case _ParseTarget.section:
      final index = payload.sectionIndex ?? 0;
      final content = _sanitizeSectionResponse(payload.response, index);
      final title = _deriveSectionTitle(payload.sectionName ?? 'Sección', content, index);
      final format = _formatForSection(index, content: content);
      return SectionGenerationResult(title: title, content: content, format: format);
  }
}

String _sanitizeSectionResponse(String raw, int sectionIndex) {
  var text = raw.trim().replaceAll(RegExp(r'```json\s*'), '').replaceAll('```', '').trim();
  if (sectionIndex == 10) {
    final cleaned = _cleanJson(text);
    return cleaned.isNotEmpty ? cleaned : text;
  }
  return text;
}

String _deriveSectionTitle(String fallback, String content, int sectionIndex) {
  if (sectionIndex == 10) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        final title = decoded['title']?.toString().trim();
        if (title != null && title.isNotEmpty) return title;
      }
    } catch (_) {
      // ignore
    }
  }
  final firstLine = content
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => '');
  if (firstLine.isEmpty) return fallback;
  final cleaned = firstLine.replaceAll(RegExp(r'^#+\s*'), '').trim();
  return cleaned.isEmpty ? fallback : cleaned;
}

String _formatForSection(int sectionIndex, {String? content}) {
  if (sectionIndex == 10) return 'json';
  if (sectionIndex == 2) return 'rich_text';
  if (content != null && content.contains('<h3>')) return 'rich_text';
  return 'text';
}

String _cleanJson(String text) {
  String clean = text.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```'), '');
  final startIndex = clean.indexOf('{');
  final endIndex = clean.lastIndexOf('}');

  if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
    return clean.substring(startIndex, endIndex + 1);
  }
  return clean.trim();
}

CourseModel _mapJsonToCourse(Map<String, dynamic> json) {
  const Uuid uuid = Uuid();
  List<ModuleModel> modules = [];
  int orderCounter = 0;
  final String introText = json['intro'] is String ? json['intro'] : '';
  final List<String> objectives = _parseObjectives(json['objectives']);
  final List<GlossaryItem> glossaryItems = _parseGlossaryItems(json['glossary']);
  final List<FaqItem> faqItems = _parseFaqItems(json['faqs'] ?? json['faq']);

  // --- A. MÓDULO 0: GUÍA DIDÁCTICA ---
  List<InteractiveBlock> guideBlocks = [];
  
  // Intro
  if (json['intro'] != null && json['intro'].toString().trim().isNotEmpty) {
    guideBlocks.add(InteractiveBlock.create(
      type: BlockType.textPlain,
      content: {"text": "## Introducción\n\n${json['intro']}"}
    ));
  }
  
  // Objetivos
  if (json['objectives'] != null) {
     String objText = "";
     if (json['objectives'] is List) {
       objText = (json['objectives'] as List).join("\n- ");
     } else {
       objText = json['objectives'].toString();
     }
     
     if (objText.trim().isNotEmpty) {
       guideBlocks.add(InteractiveBlock.create(
        type: BlockType.textPlain,
        content: {"text": "### Objetivos de Aprendizaje\n\n- $objText"}
      ));
     }
  }

  if (guideBlocks.isNotEmpty) {
    modules.add(ModuleModel(
      id: uuid.v4(),
      title: "Guía Didáctica",
      order: orderCounter++,
      blocks: guideBlocks
    ));
  }

  // --- B. MÓDULOS DEL TEMARIO ---
  if (json['modules'] != null && json['modules'] is List) {
    for (var m in json['modules']) {
      List<InteractiveBlock> blocks = [];
      if (m['blocks'] != null && m['blocks'] is List) {
        for (var b in m['blocks']) {
          BlockType type = BlockType.textPlain;
          if (b['type'] != null) {
              type = BlockType.values.firstWhere(
                (e) => e.name == b['type'], 
                orElse: () => BlockType.textPlain
              );
          }

          // CORRECCIÓN CRÍTICA PARA EL EDITOR:
          Map<String, dynamic> finalContent = {};
          var rawContent = b['content'];

          if (rawContent is Map<String, dynamic>) {
              finalContent = rawContent;
          } else if (rawContent is String) {
              finalContent = {"text": rawContent};
          } else {
              finalContent = {"text": rawContent?.toString() ?? " "};
          }
          
          // Si el texto es nulo o vacío, ponemos un espacio para evitar el crash
          if (!finalContent.containsKey('text') || finalContent['text'] == null || finalContent['text'].toString().isEmpty) {
              finalContent['text'] = " "; 
          }

          blocks.add(InteractiveBlock.create(
            type: type, 
            content: finalContent
          ));
        }
      }
      modules.add(ModuleModel(
        id: uuid.v4(), 
        title: m['title'] ?? 'Módulo Temático', 
        order: orderCounter++, 
        blocks: blocks
      ));
    }
  }

  // --- C. MÓDULO FINAL: RECURSOS ---
  List<InteractiveBlock> resourceBlocks = [];

  // Glosario
  if (json['glossary'] != null) {
    String glossaryText = "";
    if (json['glossary'] is List) {
      for (var term in json['glossary']) {
         if (term is Map) {
           glossaryText += "**${term['term']}**: ${term['definition']}\n\n";
         } else {
           glossaryText += "- $term\n";
         }
      }
    } else {
      glossaryText = json['glossary'].toString();
    }
    
    if (glossaryText.trim().isNotEmpty) {
      resourceBlocks.add(InteractiveBlock.create(
        type: BlockType.textPlain,
        content: {"text": "### Glosario\n\n$glossaryText"}
      ));
    }
  }

  // FAQs
  if (json['faqs'] != null && json['faqs'] is List) {
    String faqText = "";
    for (var f in json['faqs']) {
      if (f is Map) {
        faqText += "**P: ${f['question']}**\nR: ${f['answer']}\n\n";
      }
    }
    if (faqText.trim().isNotEmpty) {
      resourceBlocks.add(InteractiveBlock.create(
        type: BlockType.textPlain,
        content: {"text": "### Preguntas Frecuentes\n\n$faqText"}
      ));
    }
  }

  if (resourceBlocks.isNotEmpty) {
    modules.add(ModuleModel(
      id: uuid.v4(),
      title: "Recursos y Ayuda",
      order: orderCounter++,
      blocks: resourceBlocks
    ));
  }

  return CourseModel(
    id: uuid.v4(),
    userId: 'ia_gen',
    title: json['title'] ?? 'Curso Generado',
    description: json['description'] ?? 'Generado automáticamente',
    createdAt: DateTime.now(),
    introText: introText,
    objectives: objectives,
    glossaryItems: glossaryItems,
    faqItems: faqItems,
    modules: modules
  );
}

List<String> _parseObjectives(dynamic objectives) {
  if (objectives is List) {
    return objectives.map((item) => item.toString()).toList();
  }
  if (objectives is String && objectives.trim().isNotEmpty) {
    return [objectives];
  }
  return <String>[];
}

List<GlossaryItem> _parseGlossaryItems(dynamic glossary) {
  if (glossary is List) {
    return glossary.map((item) {
      if (item is Map) {
        return GlossaryItem.fromMap(Map<String, dynamic>.from(item));
      }
      return GlossaryItem(term: item.toString(), definition: '');
    }).toList();
  }
  if (glossary is Map) {
    return [GlossaryItem.fromMap(Map<String, dynamic>.from(glossary))];
  }
  return <GlossaryItem>[];
}

List<FaqItem> _parseFaqItems(dynamic faqs) {
  if (faqs is List) {
    return faqs.map((item) {
      if (item is Map) {
        return FaqItem.fromMap(Map<String, dynamic>.from(item));
      }
      return FaqItem(question: item.toString(), answer: '');
    }).toList();
  }
  if (faqs is Map) {
    return [FaqItem.fromMap(Map<String, dynamic>.from(faqs))];
  }
  return <FaqItem>[];
}
