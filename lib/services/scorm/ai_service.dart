import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../models/course_model.dart';
import '../../models/module_model.dart';
import '../../models/interactive_block.dart';

class AiService {
  // ===========================================================================
  // 🔑 ZONA DE CLAVES API
  // ===========================================================================
  static const String _geminiKey = 'AIzaSyDYs4JG30bVoup9eGSgP_hSmyd_Bn7oQnw';
  static const String _huggingFaceToken = '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'; 
  // ===========================================================================

  final Uuid _uuid = const Uuid();
  late final GenerativeModel _textModel;

  AiService() {
    // Intentamos con el modelo configurado
    _textModel = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _geminiKey);
  }

  Future<CourseModel> generateMockCourse() async {
    return _generateVisualFallback("Curso de Prueba (Mock)");
  }

  // ===========================================================================
  // 5. MODO NOTEBOOKLM (Analista de Documentos)
  // ===========================================================================
  Future<String> analyzeDocument(String rawText) async {
    try {
      final prompt = '''
        Actúa como el motor de análisis de "NotebookLM".
        Tengo este documento extenso/manual:
        "$rawText"

        Tu tarea es procesarlo y devolver una estructura optimizada para crear un curso SCORM.
        Formato de respuesta (Texto plano formateado):
        
        1. RESUMEN EJECUTIVO (3 líneas)
        2. 5 CONCEPTOS CLAVE (Bullet points)
        3. ESTRUCTURA PROPUESTA PARA EL CURSO (Título sugerido y lista de módulos/lecciones)
        
        Mantén un tono educativo y profesional.
      ''';

      final response = await _textModel.generateContent([Content.text(prompt)]);
      return response.text?.replaceAll('*', '').trim() ?? "No se pudo analizar.";
    } catch (e) {
      return "Error analizando documento: $e";
    }
  }

  // ===========================================================================
  // 1. EL ARQUITECTO: GENERAR CURSO COMPLETO (gemini-1.5-flash)
  // ===========================================================================
  Future<CourseModel> generateCourseFromText(String topic) async {
    try {
      final prompt = '''
        Actúa como un experto Diseñador Instruccional (SCORM).
        Crea un curso estructurado en JSON sobre: "$topic".
        
        REGLAS:
        1. Crea 3 módulos lógicos.
        2. Usa variedad de bloques: 'textPlain', 'imageHotspot', 'multipleChoice', 'trueFalse', 'video'.
        3. Para los bloques de imagen 'imageHotspot', usa una URL temporal como "Prompt: Descripción de la imagen".
        4. Para los bloques de video 'video', incluye un término de búsqueda en 'searchTerm' dentro del contenido.
        5. IMPORTANTE: Responde SOLO con el JSON limpio, sin markdown.
        
        ESTRUCTURA JSON ESPERADA:
        {
          "title": "Título del Curso",
          "description": "Descripción pedagógica",
          "modules": [
            {
              "title": "Nombre Módulo",
              "blocks": [
                { "type": "textPlain", "content": { "text": "..." } },
                { "type": "imageHotspot", "content": { "url": "Prompt: Un paisaje futurista...", "caption": "Descripción..." } },
                { "type": "multipleChoice", "content": { "question": "...", "options": ["A","B"], "correctIndex": 0 } }
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
      print("⚠️ Error gemini-1.5-flash Architect: $e");
    }
    
    // Fallback en caso de error
    return _generateVisualFallback(topic);
  }

  // ===========================================================================
  // 2. EL PINTOR PRO: GENERADOR DE IMÁGENES (HUGGING FACE - SDXL)
  // ===========================================================================
  Future<String> generateImage(String prompt) async {
    const modelUrl = "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0";
    
    try {
      final response = await http.post(
        Uri.parse(modelUrl),
        headers: {
          "Authorization": "Bearer $_huggingFaceToken",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "inputs": "educational illustration, clear, high quality, 4k, $prompt", 
          "parameters": {"negative_prompt": "blurry, text, watermark, bad quality, distorted"} 
        }),
      );

      if (response.statusCode == 200) {
        // Hugging Face devuelve la imagen binaria (JFIF/PNG). La convertimos a Base64.
        final base64Image = base64Encode(response.bodyBytes);
        return "data:image/jpeg;base64,$base64Image";
      } else {
        print("Error HF: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error Generando Imagen: $e");
    }
    // Fallback visual si falla
    return "https://placehold.co/1024x1024/png?text=${Uri.encodeComponent(prompt)}";
  }

  // ===========================================================================
  // 3. EL EDITOR: MEJORADOR DE TEXTO MULTI-MODO
  // ===========================================================================
  Future<String> improveText(String originalText, String mode) async {
    String instruction = "Mejora este texto para un curso educativo.";
    
    switch (mode) {
      case 'summarize': instruction = "Resume este texto en un párrafo conciso."; break;
      case 'expand': instruction = "Expande este texto con detalles explicativos y ejemplos."; break;
      case 'fix': instruction = "Corrige la gramática, ortografía y mejora el estilo profesional."; break;
      case 'simplify': instruction = "Reescribe esto para que lo entienda un niño de 12 años."; break;
      case 'tone_academic': instruction = "Reescribe con un tono académico y formal."; break;
      case 'tone_casual': instruction = "Reescribe con un tono casual y cercano."; break;
    }

    try {
      final response = await _textModel.generateContent([
        Content.text('$instruction\n\nTexto original:\n"$originalText"')
      ]);
      return response.text?.replaceAll('*', '').trim() ?? originalText;
    } catch (e) {
      return originalText; // Retorna el original si falla
    }
  }

  // ===========================================================================
  // 4. EL PRODUCTOR: SUGERENCIA DE VÍDEO (YOUTUBE SMART LINK)
  // ===========================================================================
  Future<Map<String, String>> suggestVideoContent(String topic) async {
    try {
      final prompt = 'Para un curso sobre "$topic", dame 1 término de búsqueda exacto y optimizado para YouTube, y un guion de introducción de 1 línea. JSON esperado: {"search": "término exacto", "script": "breve intro"}';
      
      final response = await _textModel.generateContent([Content.text(prompt)]);
      
      if (response.text != null) {
        final data = jsonDecode(_cleanJson(response.text!));
        final searchTerm = data['search'] ?? topic;
        
        return {
          'url': "https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchTerm)}",
          'title': "Video sugerido: $searchTerm",
          'description': data['script'] ?? "Video recomendado sobre $topic"
        };
      }
    } catch (e) {
      print("Error Sugiriendo Video: $e");
    }
    return {'url': '', 'title': 'Video sobre $topic', 'description': ''};
  }

  // ===========================================================================
  // 5. ASISTENTE DE BLOQUES INTERACTIVOS (MULTI-FUNCIONALIDAD)
  // ===========================================================================
  /// Genera contenido JSON específico para CADA tipo de bloque
  Future<Map<String, dynamic>?> assistBlockContent(BlockType type, String topic, {String? extraContext}) async {
    String instruction = "Genera un objeto JSON VÁLIDO para un bloque de tipo '${type.name}' sobre el tema '$topic'.";
    
    if (extraContext != null && extraContext.isNotEmpty) {
      instruction += " Contexto adicional: $extraContext.";
    }

    // Reglas específicas por tipo de bloque
    switch (type) {
      case BlockType.textPlain:
        instruction += ' JSON: {"text": "Párrafo explicativo educativo bien estructurado..."}';
        break;
        
      case BlockType.multipleChoice:
      case BlockType.singleChoice:
      case BlockType.questionSet:
        instruction += ' JSON: {"question": "Pregunta desafiante...", "options": ["Opción A", "Opción B", "Opción C"], "correctIndex": 0}';
        break;
        
      case BlockType.trueFalse:
        instruction += ' JSON: {"question": "Una afirmación sobre el tema...", "options": ["Verdadero", "Falso"], "correctIndex": 0} (Usa 0 para Verdadero, 1 para Falso)';
        break;
        
      case BlockType.fillBlanks:
        instruction += ' JSON: {"text": "El *concepto* clave es fundamental." (Usa asteriscos para la palabra a ocultar)}';
        break;
        
      case BlockType.imageHotspot:
      case BlockType.findHotspot:
        instruction += ' JSON: {"url": "Prompt detallado para generar la imagen (ej: landscape...)", "caption": "Descripción corta de la imagen"}';
        break;
        
      case BlockType.video:
        instruction += ' JSON: {"title": "Título sugerido", "description": "Breve descripción", "search": "Término búsqueda YouTube"}';
        break;
        
      case BlockType.essay:
        instruction += ' JSON: {"question": "Pregunta abierta para ensayo...", "options": []}'; 
        // Nota: Essay suele usar 'question' o un campo similar dependiendo de la implementación, 
        // pero usaremos una estructura genérica compatible.
        break;

      default:
        instruction += ' Genera contenido genérico educativo en JSON para este bloque.';
    }

    instruction += ' RESPONDE SOLO CON EL JSON LIMPIO.';

    try {
      final res = await _textModel.generateContent([Content.text(instruction)]);
      if (res.text != null) {
        return jsonDecode(_cleanJson(res.text!));
      }
    } catch (e) {
      print("Error Asistente Bloque ($type): $e");
    }
    return null;
  }

  // ===========================================================================
  // 6. EL EXAMINADOR: GENERACIÓN DE EXÁMENES DESDE CONTEXTO
  // ===========================================================================
  Future<Map<String, dynamic>?> generateQuizFromContext(String contextText, {int numQuestions = 5}) async {
    try {
      final prompt = '''
        Actúa como un profesor experto y crea un examen tipo 'questionSet' basado EXACTAMENTE en el siguiente contenido:
        "$contextText"

        REGLAS:
        1. Genera $numQuestions preguntas de selección múltiple.
        2. Cada pregunta debe tener 3 opciones y solo 1 correcta.
        3. El formato de salida debe ser ESTRICTAMENTE JSON compatible con mi estructura.
        
        ESTRUCTURA DE RESPUESTA REQUERIDA (JSON):
        {
          "question": "Examen del Módulo",
          "options": [],
          "questions": [
             {
               "question": "¿Pregunta 1?",
               "options": ["A", "B", "C"],
               "correctIndex": 0
             },
             ...
          ]
        }
        NOTA: Si el formato del bloque 'questionSet' requiere una lista de preguntas dentro, asegúrate de cumplirlo.
        Si la estructura de tu bloque 'questionSet' es una lista de preguntas, adáptalo.
        Para este caso, vamos a asumir que el bloque 'questionSet' contiene una lista de preguntas en su campo 'questions'.
      ''';

      // Ajuste para el modelo de datos:
      // Tu modelo 'InteractiveBlock' para 'questionSet' parece usar la misma estructura que 'multipleChoice' (una sola pregunta).
      // Si quieres un "Conjunto" real, deberíamos adaptar el modelo, pero para MVP, vamos a generar 
      // un bloque especial o simplemente múltiples bloques. 
      // PERO, para cumplir tu petición de "UN examen", generaremos un bloque 'questionSet' 
      // y asumiremos que tu renderer lo soporta o que lo adaptaremos.
      //
      // REVISIÓN RÁPIDA DE TU MODELO:
      // Tu 'BlockType.questionSet' se trata como 'MultipleChoiceWidget' en el renderer. 
      // Probablemente solo soporte 1 pregunta por bloque ahora mismo.
      // 
      // ESTRATEGIA SEGURA: Generar UNA pregunta muy completa O, si quieres múltiples, 
      // tendríamos que devolver una LISTA de bloques.
      // 
      // PARA NO ROMPER NADA: Vamos a generar UN bloque tipo "questionSet" que contenga 
      // internamente la lógica de varias preguntas si tu widget lo soporta. 
      // SI NO, generaremos UNA sola pregunta representativa o el JSON para que tú lo manejes.
      
      // CAMBIO DE ESTRATEGIA SOBRE LA MARCHA PARA MÁXIMA COMPATIBILIDAD:
      // Voy a generar un JSON que contenga UNA pregunta "Master" o un set si tienes el widget.
      // Viendo tu código, 'InteractiveBlockRenderer' usa 'MultipleChoiceWidget' para 'questionSet'.
      // Asumiré que quieres un bloque por pregunta SI no tienes un widget de Quiz completo.
      // 
      // PERO, tu instrucción dice "un examen de 5 preguntas".
      // Vamos a intentar devolver una estructura que pueda ser interpretada como un "Question Set" real 
      // si actualizas el widget, o una pregunta simple por ahora.
      
      // DADO EL CÓDIGO ACTUAL:
      // El widget 'MultipleChoiceWidget' renderiza una sola pregunta.
      // OPCIÓN MEJORADA: Generar 5 bloques separados es muy intrusivo.
      // OPCIÓN ELEGIDA: Generar un bloque especial con todas las preguntas en el contenido,
      // esperando que en el futuro tu widget 'questionSet' itere sobre ellas.
      // Por ahora, generaremos un JSON con la lista en 'questions'.
      
      final response = await _textModel.generateContent([Content.text(prompt)]);
      if (response.text != null) {
        return jsonDecode(_cleanJson(response.text!));
      }
    } catch (e) {
      print("Error Generando Examen: $e");
    }
    return null;
  }

  // ===========================================================================
  // UTILIDADES INTERNAS
  // ===========================================================================
  
  String _cleanJson(String text) {
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
             BlockType type = BlockType.values.firstWhere(
                (e) => e.name == b['type'], 
                orElse: () => BlockType.textPlain
             );
             
             // Si es video y trae search term, podrías procesarlo aquí, 
             // pero por ahora guardamos el contenido crudo.
             blocks.add(InteractiveBlock.create(type: type, content: b['content'] ?? {}));
           }
         }
         modules.add(ModuleModel(id: _uuid.v4(), title: m['title'] ?? 'Módulo', order: i++, blocks: blocks));
      }
    }
    return CourseModel(
      id: _uuid.v4(),
      userId: 'ia_gen',
      title: json['title'] ?? 'Curso Generado por IA',
      description: json['description'] ?? '',
      createdAt: DateTime.now(),
      modules: modules
    );
  }

  CourseModel _generateVisualFallback(String text) {
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
            InteractiveBlock(id: _uuid.v4(), type: BlockType.textPlain, content: {'text': "Bienvenido al curso sobre $text."}),
          ]
        )
      ]
    );
  }
}
