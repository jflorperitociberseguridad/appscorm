import 'dart:convert';
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
  static const String _geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _huggingFaceToken = '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'; 
  static const String _geminiReferer = 'http://localhost:8080';
  // ===========================================================================

  final Uuid _uuid = const Uuid();
  late final GenerativeModel? _textModel;
  late final http.Client _geminiHttpClient;

  AiService() {
    _geminiHttpClient = _RefererHttpClient(http.Client(), _geminiReferer);
    _textModel = _geminiKey.isNotEmpty
        ? GenerativeModel(
            model: 'gemini-2.5-flash',
            apiKey: _geminiKey,
            httpClient: _geminiHttpClient,
          )
        : null;
  }

  Future<CourseModel> generateMockCourse() async {
    return _generateVisualFallback("Curso de Prueba (Mock)");
  }

  // 1. EL ARQUITECTO (Generador Maestro)
  Future<CourseModel> generateCourseFromText(String text, {Map<String, dynamic>? config}) async {
    try {
      if (!_hasGeminiKey()) return _generateVisualFallback(text);
      final prompt = AiPrompts.generateCourse(text, config: _withSystemTags(config));
      final response = await _textModel!.generateContent([Content.text(prompt)]);
      
      if (response.text != null && response.text!.isNotEmpty) {
        // Limpiamos JSON
        final cleanJson = _cleanJson(response.text!);
        try {
          final decoded = jsonDecode(cleanJson);
          if (decoded is Map<String, dynamic>) {
            return _mapJsonToCourse(decoded);
          }
        } catch (_) {
          // Se ignora para permitir una salida segura.
        }
      }
    } catch (_) {
      // Se ignora para permitir una salida segura.
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
    } catch (_) {
      // Se ignora para permitir una salida segura.
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
    } catch (_) {
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
    } catch (_) {
      // Se ignora para permitir una salida segura.
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
        } catch (_) {
          // Se ignora para permitir una salida segura.
          return {};
        }
      }
      return {};
    } catch (_) {
      // Se ignora para permitir una salida segura.
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

  // 8. GENERADOR CONTEXTUAL POR SECCIÓN
  Future<SectionGenerationResult> generateSectionContent({
    required int sectionIndex,
    required String sectionName,
    required String context,
    required Map<String, String> panelConfig,
  }) async {
    try {
      if (!_hasGeminiKey()) {
        return const SectionGenerationResult(format: 'text', content: '');
      }
      final prompt = AiPrompts.generateSectionContent(
        sectionIndex: sectionIndex,
        sectionName: sectionName,
        context: context,
        audience: panelConfig['audience'] ?? 'General',
        tone: panelConfig['tone'] ?? 'Profesional',
        methodology: panelConfig['methodology'] ?? 'Expositiva',
      );
      final response = await _textModel!.generateContent([Content.text(prompt)]);
      final rawText = response.text?.trim() ?? '';
      if (rawText.isEmpty) {
        return const SectionGenerationResult(format: 'text', content: '');
      }

      if (sectionIndex == 10) {
        return SectionGenerationResult(format: 'json', content: _cleanJson(rawText));
      }
      if (sectionIndex == 2) {
        return SectionGenerationResult(format: 'rich_text', content: rawText);
      }
      return SectionGenerationResult(format: 'text', content: rawText);
    } catch (e) {
      return SectionGenerationResult(format: 'text', content: 'Error generando: $e');
    }
  }

  // ===========================================================================
  // 🛠️ MÉTODOS PRIVADOS (BLINDAJE TOTAL CONTRA CRASHES)
  // ===========================================================================
  bool _hasGeminiKey() {
    if (_geminiKey.isEmpty || _textModel == null) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> _withSystemTags(Map<String, dynamic>? config) {
    final merged = <String, dynamic>{};
    if (config != null) {
      merged.addAll(config);
    }
    final systemTags = _buildSystemTags(merged);
    if (systemTags.isNotEmpty) {
      merged['systemTags'] = systemTags;
    }
    return merged;
  }

  String _buildSystemTags(Map<String, dynamic> config) {
    final tags = <String>[];
    void addTag(String label, dynamic value) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        tags.add('$label: $text');
      }
    }

    addTag('Tono', config['tone'] ?? config['strategyTone'] ?? config['panelTone']);
    addTag('Nivel', config['difficulty'] ?? config['strategyDifficulty']);
    addTag('Metodología', config['methodology'] ?? config['strategyMethodology']);
    addTag('Público', config['audience'] ?? config['strategyAudience']);
    addTag('Estilo', config['styleVisual'] ?? config['style']);
    addTag('Narrativa', config['styleNarrative']);
    addTag('Notas de estilo', config['styleNotes']);
    addTag('SCORM', config['scormVersion']);
    addTag('Reglas SCORM', config['scormNotes']);
    addTag('Ecosistema', config['ecosystemNotes']);
    addTag('LMS', config['lms']);
    return tags.join(' + ');
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

  /// MAPEO BLINDADO: Evita "Delta cannot be empty" poniendo espacios en textos vacíos
  CourseModel _mapJsonToCourse(Map<String, dynamic> json) {
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
        id: _uuid.v4(),
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
          id: _uuid.v4(), 
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
        id: _uuid.v4(),
        title: "Recursos y Ayuda",
        order: orderCounter++,
        blocks: resourceBlocks
      ));
    }

    return CourseModel(
      id: _uuid.v4(),
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
  final String format;
  final String content;

  const SectionGenerationResult({required this.format, required this.content});
}

class _RefererHttpClient extends http.BaseClient {
  _RefererHttpClient(this._inner, this._referer);

  final http.Client _inner;
  final String _referer;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Referer'] = _referer;
    return _inner.send(request);
  }
}
