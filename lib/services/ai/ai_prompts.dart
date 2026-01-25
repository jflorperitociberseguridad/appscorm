import '../../models/interactive_block.dart';

class AiPrompts {
  // --- PROTOCOLO DE CUÁDRUPLE OPCIÓN (Original de Cibermedia) ---
  static String quadrupleOptionTransform(String originalText) => '''
    Actúa como el "Arquitecto de Contenidos" de Cibermedia. 
    Transforma este texto en 4 variantes pedagógicas para el Constructor de Bloques:

    [OPCIÓN A: MICRO-LEARNING]
    (Sintético, directo, usa bullets. Enfocado a +5 Velocidad de lectura).

    [OPCIÓN B: NARRATIVA/STORYTELLING]
    (Añade ejemplos, analogías o un escenario real. Enfocado a +15 Comprensión).

    [OPCIÓN C: SOCRÁTICA]
    (Transforma la información en una pregunta o reto de reflexión. Enfocado a +20 Engagement).

    [OPCIÓN D: COMPROMISO/MISIÓN]
    (ETIQUETA MÁGICA: "MISIÓN_VITRINA". 
    ESTADO: COLUMNA 3 COMPROMETIDA. 
    Transforma el texto en un Hito Gamificado.
    Define una misión clara, el valor en puntos y la medalla para el Dashboard de la Columna 3).

    TEXTO ORIGINAL:
    "$originalText"

    IMPORTANTE: Devuelve únicamente las 4 opciones con sus etiquetas. Sin comentarios extra.
  ''';

  // --- ANALIZADOR DE DOCUMENTOS (Modo NotebookLM) ---
  static String analyzeDocument(String rawText) => '''
    Actúa como el motor de análisis de "Aula Cibermedida". 
    Tengo este documento/manual:
    "$rawText"

    Tu tarea es procesarlo y devolver una estructura optimizada para crear un curso SCORM.
    Responde con:
    1. RESUMEN EJECUTIVO (Máximo 3 líneas).
    2. 5 CONCEPTOS CLAVE.
    3. ESTRUCTURA DE TEMARIO SUGERIDA.
  ''';

  // --- GENERADOR MAESTRO DE CURSOS (DINÁMICO Y CONFIGURABLE) ---
  // Este método integra la configuración de CreateCourseScreen
  static String generateCourse(String topic, {Map<String, dynamic>? config}) {
    // Variables dinámicas desde la UI
    final String title = config?['title'] ?? 'Curso SCORM';
    final int modules = config?['moduleCount'] ?? 3;
    final String density = config?['introDensity'] ?? 'Estándar';
    final String depth = config?['moduleDepth'] ?? 'Intermedia';
    final int faqs = config?['faqCount'] ?? 5;
    final int evals = config?['evalQuestionCount'] ?? 10;
    final String evalType = config?['evalType'] ?? 'Opción Múltiple';
    final String systemTags = config?['systemTags'] ?? '';
    final String contentBankNotes = config?['contentBankNotes'] ?? '';
    final String contentBankFiles = _formatContentBankFiles(config?['contentBankFiles']);
    
    // Instrucciones específicas de las secciones configurables
    final String introInstruct = config?['intro'] ?? 'Generar introducción motivacional';
    final String objGoal = config?['objectives'] ?? 'Definir objetivos claros';
    final String mapGoal = config?['conceptualMap'] ?? 'Estructura de nodos lógicos';

    return '''
    ${systemTags.isNotEmpty ? 'SYSTEM PROMPT: $systemTags\n' : ''}
    Actúa como un Diseñador Instruccional Senior experto en SCORM 1.2.
    Transforma el contenido fuente multimodal en un curso estructurado profesional.

    CONTENIDO FUENTE (PRIORIDAD MÁXIMA):
    "$topic"

    BANCO MULTIMODAL:
    ${contentBankFiles.isNotEmpty ? contentBankFiles : 'Sin archivos listados.'}
    ${contentBankNotes.isNotEmpty ? 'Notas del banco: $contentBankNotes' : ''}

    INSTRUCCIÓN CLAVE:
    - Usa el Banco Multimodal como fuente de verdad principal para construir todas las secciones del curso.
    - Si hay conflicto con otras notas, prioriza el banco.

    PARÁMETROS DE CONFIGURACIÓN (OBLIGATORIOS):
    1. TÍTULO DEL PROYECTO: $title.
    2. GUÍA DIDÁCTICA:
       - Introducción: Densidad $density. Enfoque: $introInstruct.
       - Objetivos: $objGoal.
       - Mapa Conceptual: $mapGoal.
    3. TEMARIO:
       - Genera EXACTAMENTE $modules módulos.
       - Profundidad técnica: $depth.
       - Usa bloques: 'textPlain', 'video', 'accordion', 'multipleChoice', 'trueFalse', 'imageHotspot'.
    4. CIERRE Y EVALUACIÓN:
       - Glosario y Recursos: ${config?['glossary'] ?? 'Términos clave'} y ${config?['resources'] ?? 'Material adicional'}.
       - FAQ: Exactamente $faqs preguntas frecuentes.
       - EXAMEN FINAL: $evals preguntas de tipo $evalType.

    REGLAS TÉCNICAS:
    - Para 'video', usa un 'searchTerm' preciso para YouTube.
    - Para 'imageHotspot', describe la imagen en el campo 'url' (Prompt: [descripción]).
    - Responde EXCLUSIVAMENTE con el JSON compatible con CourseModel.
    - El JSON debe incluir campos raíz: intro (string), objectives (list),
      glossary (list of maps) y faqs (list of maps) además de modules.

    JSON ESTRUCTURA:
    {
      "title": "$title",
      "description": "Descripción pedagógica",
      "intro": "Introducción del curso",
      "objectives": ["Objetivo 1", "Objetivo 2"],
      "glossary": [
        { "term": "Término", "definition": "Definición breve" }
      ],
      "modules": [
        { "title": "...", "blocks": [ { "type": "...", "content": {...} } ] }
      ],
      "faqs": [
        { "question": "Pregunta frecuente", "answer": "Respuesta breve" }
      ],
      "evaluation": { "blocks": [...] }
    }
    ''';
  }

  static String _formatContentBankFiles(dynamic rawFiles) {
    if (rawFiles is! List) return '';
    final buffer = StringBuffer();
    for (final item in rawFiles) {
      if (item is Map) {
        final name = item['name']?.toString() ?? 'archivo';
        final type = item['type']?.toString().toUpperCase() ?? 'DESCONOCIDO';
        final extension = item['extension']?.toString() ?? '';
        buffer.writeln('- $name ($type${extension.isNotEmpty ? ', .$extension' : ''})');
      }
    }
    return buffer.toString().trim();
  }
  // --- EL EDITOR (Mejorador de texto) ---
  // Mantiene todos los modos originales incluyendo el protocolo de misión para C3
  static String improveText(String originalText, String mode) {
    String instruction = "Mejora este texto para un curso educativo.";
    switch (mode) {
      case 'summarize': 
        instruction = "Resume este texto de forma muy concisa en un solo párrafo.";
        break;
      case 'expand': 
        instruction = "Expande este texto añadiendo detalles explicativos, ejemplos prácticos y profundidad educativa.";
        break;
      case 'fix': 
        instruction = "Corrige gramática, ortografía y mejora la fluidez sin cambiar el sentido original.";
        break;
      case 'simplify': 
        instruction = "Reescribe el contenido usando un lenguaje sencillo para que lo entienda un niño de 12 años.";
        break;
      case 'professional': 
        instruction = "Reescribe el texto con un tono profesional, ejecutivo y formal.";
        break;
      case 'tone_academic': 
        instruction = "Reescribe con un tono académico riguroso y formal.";
        break;
      case 'tone_casual': 
        instruction = "Reescribe con un tono cercano, amable y conversacional.";
        break;
      case 'mission_protocol': 
        return quadrupleOptionTransform(originalText);
    }
    
    return '$instruction\n\nIMPORTANTE: Devuelve ÚNICAMENTE el texto transformado. Sin comentarios.\n\nTexto original:\n"$originalText"';
  }

  // --- EL PRODUCTOR (YouTube Suggestion) ---
  static String suggestVideo(String topic) => 
    'Para un curso sobre "$topic", dame 1 término de búsqueda exacto y optimizado para YouTube, y un guion de introducción de 1 línea. '
    'RESPONDE SOLO JSON: {"search": "término exacto", "script": "breve intro"}';

  // --- ASISTENTE DE BLOQUES (Las 22 funcionalidades) ---
  // Este es el motor que genera contenido para el Constructor Universal
  static String assistBlock(BlockType type, String topic, String? extraContext) {
    String instruction = "Genera un objeto JSON VÁLIDO para un bloque de tipo '${type.name}' sobre el tema '$topic'.";
    if (extraContext != null && extraContext.isNotEmpty) {
      instruction += " Contexto adicional: $extraContext.";
    }

    switch (type) {
      case BlockType.textPlain:
        instruction += ' JSON: {"text": "Contenido educativo detallado y bien estructurado..."}';
        break;
      case BlockType.multipleChoice:
      case BlockType.singleChoice:
      case BlockType.questionSet:
        instruction += ' JSON: {"question": "Pregunta...", "options": ["Opción A", "Opción B", "Opción C"], "correctIndex": 0}';
        break;
      case BlockType.trueFalse:
        instruction += ' JSON: {"question": "Afirmación para validar...", "options": ["Verdadero", "Falso"], "correctIndex": 0}';
        break;
      case BlockType.fillBlanks:
        instruction += ' JSON: {"text": "La capital de España es *Madrid*."}';
        break;
      case BlockType.imageHotspot:
      case BlockType.findHotspot:
        instruction += ' JSON: {"url": "Prompt detallado para generar imagen con IA", "caption": "Descripción del hotspot"}';
        break;
      case BlockType.video:
        instruction += ' JSON: {"title": "Título del vídeo", "description": "Introducción al contenido", "search": "Término de búsqueda optimizado"}';
        break;
      case BlockType.essay:
        instruction += ' JSON: {"question": "Escribe una reflexión sobre...", "options": []}';
        break;
      case BlockType.accordion:
        instruction += ' JSON: {"items": [{"title": "Subtema", "content": "Explicación detallada del punto"}]}';
        break;
      case BlockType.carousel:
        instruction += ' JSON: {"items": [{"url": "Prompt imagen slide", "caption": "Texto descriptivo"}]}';
        break;
      default:
        instruction += ' Genera contenido educativo coherente en formato JSON.';
    }
    return '$instruction RESPONDE SOLO CON EL JSON LIMPIO, SIN MARKDOWN.';
  }

  // --- EL EXAMINADOR ---
  static String generateQuiz(String contextText, int numQuestions) => '''
    Actúa como un profesor experto y crea un examen basado EXACTAMENTE en este contenido:
    "$contextText"

    REGLAS:
    1. Genera $numQuestions preguntas de selección múltiple.
    2. Cada pregunta debe tener 3 opciones y solo 1 correcta.
    3. El formato de salida debe ser ESTRICTAMENTE JSON limpio.
    
    ESTRUCTURA:
    {
      "question": "Evaluación de conocimientos",
      "questions": [
         {
           "question": "¿Pregunta específica?",
           "options": ["Opción 1", "Opción 2", "Opción 3"],
           "correctIndex": 0
         }
      ]
    }
  ''';

  // --- GENERADOR POR SECCIÓN (Con plantillas de respuesta) ---
  static String generateSectionContent({
    required int sectionIndex,
    required String sectionName,
    required String context,
    required String audience,
    required String tone,
    required String methodology,
  }) {
    final template = _responseTemplateForSection(sectionIndex);
    return '''
    Actúa como un diseñador instruccional senior y genera contenido para la sección:
    "$sectionName" (Sección $sectionIndex).

    CONFIGURACIÓN DEL PANEL INICIAL:
    - Público: $audience
    - Tono: $tone
    - Metodología: $methodology

    CONTEXTO BASE DEL CURSO:
    "$context"

    PLANTILLA DE RESPUESTA (OBLIGATORIA):
    $template
    ''';
  }

  static String _responseTemplateForSection(int sectionIndex) {
    if (sectionIndex == 10) {
      return '''
      Devuelve EXCLUSIVAMENTE JSON válido con esta estructura:
      {
        "title": "Evaluación Final",
        "instructions": "Instrucciones breves",
        "questions": [
          {
            "question": "Pregunta...",
            "options": ["Opción A", "Opción B", "Opción C"],
            "correctIndex": 0
          }
        ]
      }
      ''';
    }

    if (sectionIndex == 2) {
      return '''
      Devuelve texto enriquecido en Markdown:
      - Usa títulos con "##" y "###"
      - Incluye bullets cuando sea útil
      - No uses JSON ni bloques de código
      ''';
    }

    return '''
    Devuelve texto claro y directo, con subtítulos y bullets cuando aplique.
    No uses JSON ni bloques de código.
    ''';
  }
}
