import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../models/course_model.dart';
import '../../models/module_model.dart';
import '../../models/interactive_block.dart';

class AiService {
  // ===========================================================================
  // 🔑 ZONA DE CLAVES API (PON LAS TUYAS AQUÍ)
  // ===========================================================================
  static const String _geminiKey = 'AIzaSyDYEPHVmaEiHg8XlcVS11zYQScmK8bHCBY';
  static const String _huggingFaceToken = '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'; // El que empieza por hf_
  // ===========================================================================

  final Uuid _uuid = const Uuid();
  late final GenerativeModel _textModel;

  AiService() {
    // Inicializamos el modelo de Google
    _textModel = GenerativeModel(model: 'gemini-pro', apiKey: _geminiKey);
  }

  /// Analiza un documento largo y devuelve un resumen estructurado
  Future<String> analyzeDocument(String text) async {
    try {
      final prompt = "Analiza el siguiente texto y extrae la estructura principal (Títulos y puntos clave) para crear un curso online. Hazlo muy resumido y directo.\n\n$text";
      final response = await _textModel.generateContent([Content.text(prompt)]);
      return response.text ?? "No se pudo analizar el texto.";
    } catch (e) {
      return "Error analizando documento: $e";
    }
  }

  // ===========================================================================
  // 1. EL ARQUITECTO: GENERAR CURSO COMPLETO (GEMINI)
  // ===========================================================================
  Future<CourseModel> generateCourseFromText(String topic) async {
    try {
      final prompt = '''
        Actúa como un experto Diseñador Instruccional (SCORM).
        Crea un curso estructurado en JSON sobre: "$topic".
        
        REGLAS:
        1. Crea 3 módulos lógicos.
        2. Usa variedad de bloques: 'textPlain', 'imageHotspot', 'multipleChoice', 'trueFalse'.
        3. IMPORTANTE: Responde SOLO con el JSON limpio, sin markdown.
        
        ESTRUCTURA JSON ESPERADA:
        {
          "title": "Título del Curso",
          "description": "Descripción pedagógica",
          "modules": [
            {
              "title": "Nombre Módulo",
              "blocks": [
                { "type": "textPlain", "content": { "text": "..." } },
                { "type": "imageHotspot", "content": { "url": "https://placehold.co/600x400?text=Imagen+IA", "caption": "Descripción..." } }
              ]
            }
          ]
        }
      ''';

      final response = await _textModel.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        final cleanJson = _cleanJson(response.text!);
        final Map<String, dynamic> data = jsonDecode(cleanJson);
        return _mapJsonToCourse(data);
      }
    } catch (e) {
      print("⚠️ Error Gemini Architect: $e");
    }
    
    // Si falla la IA o no hay internet, usamos tu generador básico de respaldo
    return _generateVisualFallback(topic);
  }

  // ===========================================================================
  // 2. EL PINTOR: GENERADOR DE IMÁGENES (HUGGING FACE)
  // ===========================================================================
  /// Sustituye a Pollinations. Usa Stable Diffusion XL (Calidad Pro).
  Future<String> generateImage(String prompt) async {
    const modelUrl = "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0";
    
    try {
      if (_huggingFaceToken.contains('TU_TOKEN')) throw Exception("Falta Token HF");

      final response = await http.post(
        Uri.parse(modelUrl),
        headers: {
          "Authorization": "Bearer $_huggingFaceToken",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "inputs": "educational illustration, high quality, 4k, $prompt",
          "parameters": {"negative_prompt": "blurry, text, watermark, bad quality"} 
        }),
      );

      if (response.statusCode == 200) {
        // Hugging Face devuelve la imagen binaria. La convertimos a Base64 para Flutter.
        final base64Image = base64Encode(response.bodyBytes);
        return "data:image/jpeg;base64,$base64Image";
      } else {
        print("Error HF: ${response.statusCode}");
      }
    } catch (e) {
      print("Error Generando Imagen: $e");
    }
    // Fallback si falla
    return "https://placehold.co/1024x1024/png?text=${Uri.encodeComponent(prompt)}";
  }

  // ===========================================================================
  // 3. EL EDITOR: MEJORADOR DE TEXTO
  // ===========================================================================
  Future<String> improveText(String originalText, String mode) async {
    String instruction = "Mejora este texto.";
    if (mode == 'summarize') instruction = "Resume este texto en un párrafo.";
    if (mode == 'expand') instruction = "Expande este texto con detalles explicativos.";
    if (mode == 'fix') instruction = "Corrige gramática y estilo profesional.";
    if (mode == 'simplify') instruction = "Explícalo para un niño de 12 años.";

    try {
      final response = await _textModel.generateContent([
        Content.text('$instruction\nTexto original: "$originalText"')
      ]);
      return response.text?.replaceAll('*', '').trim() ?? originalText;
    } catch (e) {
      return originalText;
    }
  }

  // ===========================================================================
  // 4. EL PRODUCTOR: SUGERENCIA DE VÍDEO (YOUTUBE SMART LINK)
  // ===========================================================================
  Future<Map<String, String>> suggestVideoContent(String topic) async {
    try {
      final prompt = 'Para un curso sobre "$topic", dame 1 término de búsqueda exacto para YouTube y un guion de 1 línea. JSON: {"search": "...", "script": "..."}';
      final response = await _textModel.generateContent([Content.text(prompt)]);
      final data = jsonDecode(_cleanJson(response.text));
      
      return {
        'url': "https://www.youtube.com/results?search_query=${Uri.encodeComponent(data['search'])}",
        'title': "Video sugerido: ${data['search']}",
        'description': data['script']
      };
    } catch (e) {
      return {'url': '', 'title': 'Video sobre $topic'};
    }
  }

  // ===========================================================================
  // 5. ASISTENTE DE BLOQUES (Relleno automático de preguntas)
  // ===========================================================================
  Future<Map<String, dynamic>?> assistBlockContent(BlockType type, String topic) async {
    // Implementación básica para conectar con tus botones mágicos
    String prompt = "Genera contenido JSON para un bloque ${type.name} sobre $topic.";
    if (type == BlockType.multipleChoice) prompt += ' JSON: {"question": "...", "options": ["A","B","C"], "correctIndex": 0}';
    
    try {
      final res = await _textModel.generateContent([Content.text(prompt)]);
      return jsonDecode(_cleanJson(res.text));
    } catch (e) {
      return null;
    }
  }

  // --- NUEVO: Generador de Exámenes para el Editor ---
  Future<Map<String, dynamic>?> generateQuizFromContext(String contextText, {int numQuestions = 5}) async {
      try {
        final prompt = '''
          Basado en el siguiente texto: "$contextText", crea un examen de $numQuestions preguntas.
          
          FORMATO JSON OBLIGATORIO (QuestionSet):
          {
            "questions": [
              {
                "question": "¿Pregunta 1?",
                "options": ["Respuesta Correcta", "Incorrecta 1", "Incorrecta 2"],
                "correctIndex": 0
              }
            ]
          }
        ''';
        
        final response = await _textModel.generateContent([Content.text(prompt)]);
        if (response.text != null) {
           return jsonDecode(_cleanJson(response.text!));
        }
      } catch (e) {
        print("Error Quiz: $e");
      }
      return null;
  }

  // ===========================================================================
  // UTILIDADES Y FALLBACKS (TU CÓDIGO ORIGINAL ADAPTADO)
  // ===========================================================================
  
  String _cleanJson(String? text) {
    if (text == null) return "{}";
    return text.replaceAll('```json', '').replaceAll('```', '').trim();
  }

  CourseModel _mapJsonToCourse(Map<String, dynamic> json) {
    List<ModuleModel> modules = [];
    int i = 0;
    if (json['modules'] != null) {
      for (var m in json['modules']) {
         List<InteractiveBlock> blocks = [];
         if (m['blocks'] != null) {
           for (var b in m['blocks']) {
             // Convertir string type a Enum
             BlockType type = BlockType.values.firstWhere(
                (e) => e.name == b['type'], 
                orElse: () => BlockType.textPlain
             );
             blocks.add(InteractiveBlock.create(type: type, content: b['content'] ?? {}));
           }
         }
         modules.add(ModuleModel(id: _uuid.v4(), title: m['title'] ?? 'Módulo', order: i++, blocks: blocks));
      }
    }
    return CourseModel(
      id: _uuid.v4(),
      userId: 'ia_gen',
      title: json['title'] ?? 'Curso Generado',
      description: json['description'] ?? '',
      createdAt: DateTime.now(),
      modules: modules
    );
  }

  // PLAN B: Tu generador visual manual (Mantenido por seguridad)
  CourseModel _generateVisualFallback(String text) {
    // Versión simplificada de tu fallback para emergencias
    return CourseModel(
      id: _uuid.v4(),
      title: "Curso: $text",
      description: "Generado offline",
      createdAt: DateTime.now(),
      modules: [
        ModuleModel(
          id: _uuid.v4(), 
          title: "Introducción", 
          order: 0, 
          blocks: [
            InteractiveBlock(id: _uuid.v4(), type: BlockType.textPlain, content: {'text': "Introducción a $text"}),
            // Aquí usamos un placeholder seguro
            InteractiveBlock(id: _uuid.v4(), type: BlockType.imageHotspot, content: {'url': "https://placehold.co/600x400?text=$text", 'caption': "Imagen conceptual"}),
          ]
        )
      ]
    );
  }
}