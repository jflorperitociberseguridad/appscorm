import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../models/course_model.dart';
import '../models/interactive_block.dart';

class ManuscriptService {
  static const String _geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _geminiReferer = 'http://localhost:8080';

  late final GenerativeModel? _textModel;
  late final http.Client _geminiHttpClient;

  ManuscriptService() {
    _geminiHttpClient = _RefererHttpClient(http.Client(), _geminiReferer);
    _textModel = _geminiKey.isNotEmpty
        ? GenerativeModel(
            model: 'gemini-2.5-flash',
            apiKey: _geminiKey,
            httpClient: _geminiHttpClient,
          )
        : null;
  }

  Future<ManuscriptResult> generate({
    required CourseConfig courseConfig,
    required String contentBankText,
    required Map<String, dynamic> generationConfig,
  }) async {
    if (!_hasGeminiKey()) {
      return ManuscriptResult(
        markdown: _fallbackManuscript('GEMINI_API_KEY no configurada.'),
        success: false,
        reason: 'GEMINI_API_KEY no configurada.',
      );
    }
    try {
      final prompt = _buildPrompt(
        courseConfig: courseConfig,
        contentBankText: contentBankText,
        generationConfig: generationConfig,
      );
      final response = await _textModel!.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        return ManuscriptResult(
          markdown: _fallbackManuscript('Sin respuesta de Gemini.'),
          success: false,
          reason: 'Sin respuesta de Gemini.',
        );
      }
      return ManuscriptResult(markdown: text, success: true);
    } catch (e) {
      return ManuscriptResult(
        markdown: _fallbackManuscript('Error generando manuscrito: $e'),
        success: false,
        reason: e.toString(),
      );
    }
  }

  Future<String> generateMasterManuscript({
    required CourseConfig courseConfig,
    required String contentBankText,
    required Map<String, dynamic> generationConfig,
  }) async {
    final result = await generate(
      courseConfig: courseConfig,
      contentBankText: contentBankText,
      generationConfig: generationConfig,
    );
    return result.markdown;
  }

  bool _hasGeminiKey() {
    if (_geminiKey.isEmpty || _textModel == null) {
      return false;
    }
    return true;
  }

  String _buildPrompt({
    required CourseConfig courseConfig,
    required String contentBankText,
    required Map<String, dynamic> generationConfig,
  }) {
    final blockTypes = BlockType.values
        .where((type) => type != BlockType.unknown)
        .map((type) => type.name)
        .join(', ');

    final title = generationConfig['title'] ?? 'Curso SCORM';
    final tone = generationConfig['toneStyle'] ?? generationConfig['tone'] ?? 'Profesional';
    final methodology = generationConfig['pedagogicalModel'] ?? 'Expositiva';
    final audience = generationConfig['audience'] ?? 'General';

    return '''
Actúa como Diseñador Instruccional Senior especializado en SCORM.
Tu salida DEBE ser un "Manuscrito Maestro de Diseño" en Markdown. Sin texto fuera del Markdown.

OBJETIVO:
- Producir un manuscrito que sirva como orden de trabajo para generar los bloques del curso.
- Respetar estrictamente la Lógica SCORM y las Reglas de Evaluación configuradas.

CONTENIDO FUENTE (prioridad máxima):
${contentBankText.isNotEmpty ? contentBankText : 'Sin contenido base disponible.'}

PARÁMETROS PEDAGÓGICOS:
- Título del curso: $title
- Público: $audience
- Tono/estilo: $tone
- Metodología: $methodology

CONFIGURACIÓN LMS Y CUMPLIMIENTO:
${_formatCourseConfig(courseConfig)}

REGLAS SCORM (OBLIGATORIAS):
${_formatScormRules(generationConfig)}

REGLAS DE EVALUACIÓN (OBLIGATORIAS):
${_formatEvaluationRules(generationConfig)}

TIPOS DE BLOQUES DISPONIBLES:
$blockTypes

FORMATO DE SALIDA (Markdown, con estos encabezados exactos):
# Manuscrito Maestro de Diseño
## Resumen Ejecutivo
- Explica cómo se aplicará el tono/estilo elegidos.
## Estructura de Módulos
- Índice detallado basado en las fuentes.
## Estrategia de Evaluación
- Distribución de retos por módulo y examen final según reglas.
## Mapa de Bloques
- Tabla o lista por sección indicando los tipos de bloques sugeridos.

REGLAS DE RESPUESTA:
- No inventes parámetros que contradigan la configuración.
- Si falta información, declara el supuesto en una nota breve dentro de la sección correspondiente.
- No incluyas JSON ni código, solo Markdown.
''';
  }

  String _formatCourseConfig(CourseConfig config) {
    final patches = config.compatibilityPatches.isEmpty
        ? 'Ninguno'
        : config.compatibilityPatches.join(', ');
    return '''
- LMS destino: ${config.targetLms}
- Parches de compatibilidad: $patches
- Protección con contraseña: ${config.passwordProtectionEnabled ? 'Sí' : 'No'}
- Dominio permitido: ${config.allowedDomain.isNotEmpty ? config.allowedDomain : 'Sin restricción'}
- Expiración: ${config.expirationDate.isNotEmpty ? config.expirationDate : 'Sin expiración'}
- Modo offline: ${config.offlineModeEnabled ? 'Sí' : 'No'}
- WCAG: ${config.wcagLevel}
- GDPR: ${config.gdprCompliance ? 'Sí' : 'No'}
- Anonimización: ${config.anonymizeLearnerData ? 'Sí' : 'No'}
- xAPI: ${config.xApiEnabled ? 'Sí' : 'No'}
- LRS URL: ${config.lrsUrl.isNotEmpty ? config.lrsUrl : 'No configurado'}
- Soporte: ${config.supportEmail.isNotEmpty ? config.supportEmail : 'No definido'}
- Ecosistema: ${config.ecosystemNotes.isNotEmpty ? config.ecosystemNotes : 'Sin notas'}
''';
  }

  String _formatScormRules(Map<String, dynamic> config) {
    return '''
- Versión: ${config['scormVersion'] ?? '1.2'}
- Identificador: ${config['scormIdentifier'] ?? 'No definido'}
- Etiquetas metadata: ${(config['scormMetadataTags'] as List?)?.join(', ') ?? 'Sin etiquetas'}
- Modo navegación: ${config['scormNavigationMode'] ?? 'Secuencial'}
- Botones LMS: ${config['scormShowLmsButtons'] == true ? 'Visibles' : 'Ocultos'}
- Navegación personalizada: ${config['scormCustomNav'] == true ? 'Sí' : 'No'}
- Bookmarking: ${config['scormBookmarking'] == true ? 'Sí' : 'No'}
- Mastery score: ${config['scormMasteryScore'] ?? 'No definido'}
- Completion status: ${config['scormCompletionStatus'] ?? 'No definido'}
- Reporte de tiempo: ${config['scormReportTime'] ?? 'No definido'}
- Intervalo commit: ${config['scormCommitIntervalSeconds'] ?? 'No definido'}s
- Debug: ${config['scormDebugMode'] == true ? 'Sí' : 'No'}
- Exit behavior: ${config['scormExitBehavior'] ?? 'No definido'}
- Notas SCORM: ${config['scormNotes'] ?? 'Sin notas'}
''';
  }

  String _formatEvaluationRules(Map<String, dynamic> config) {
    return '''
- Examen final: ${config['finalExamLevel'] ?? 'Estándar'}
- Preguntas examen final: ${config['finalExamQuestions'] ?? config['evalQuestionCount'] ?? 'No definido'}
- Ratio complejidad: ${config['finalExamComplexRatio'] ?? 'No definido'}
- Puntaje de aprobación: ${config['finalExamPassScore'] ?? 'No definido'}
- Límite de tiempo: ${config['finalExamTimeLimit'] ?? 'No definido'} min
- Mostrar temporizador: ${config['finalExamShowTimer'] == true ? 'Sí' : 'No'}
- Barajar preguntas: ${config['finalExamShuffleQuestions'] == true ? 'Sí' : 'No'}
- Barajar respuestas: ${config['finalExamShuffleAnswers'] == true ? 'Sí' : 'No'}
- Permitir regresar: ${config['finalExamAllowBack'] == true ? 'Sí' : 'No'}
- Feedback inmediato: ${config['finalExamShowFeedback'] == true ? 'Sí' : 'No'}
- Diploma automático: ${config['finalExamGenerateDiploma'] == true ? 'Sí' : 'No'}
- Retos por módulo: ${config['moduleTestsEnabled'] == true ? 'Sí' : 'No'}
- Preguntas por reto: ${config['moduleTestQuestions'] ?? 'No definido'}
- Tipo de reto: ${config['moduleTestType'] ?? 'No definido'}
- Feedback en retos: ${config['moduleTestImmediateFeedback'] == true ? 'Sí' : 'No'}
- Estilo de reto: ${config['moduleTestStyle'] ?? 'No definido'}
''';
  }

  String _fallbackManuscript(String reason) {
    return '''
# Manuscrito Maestro de Diseño
## Resumen Ejecutivo
- No fue posible generar el manuscrito automáticamente.
- Motivo: $reason
## Estructura de Módulos
- Pendiente de generación.
## Estrategia de Evaluación
- Pendiente de generación.
## Mapa de Bloques
- Pendiente de generación.
''';
  }
}

class ManuscriptResult {
  final String markdown;
  final bool success;
  final String? reason;

  const ManuscriptResult({
    required this.markdown,
    required this.success,
    this.reason,
  });
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
