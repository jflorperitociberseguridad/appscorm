part of 'create_course_screen.dart';

mixin _CreateCourseStateFields on State<CreateCourseScreen> {
  // --- CONTROLADORES DE TEXTO ---
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _baseContentController = TextEditingController();
  final TextEditingController _objectivesController = TextEditingController();
  final TextEditingController _glossaryController = TextEditingController();
  final TextEditingController _resourcesController = TextEditingController();
  final TextEditingController _styleNotesController = TextEditingController();
  final TextEditingController _scormNotesController = TextEditingController();
  final TextEditingController _scormIdentifierController = TextEditingController();
  final TextEditingController _ecosystemNotesController = TextEditingController();
  final TextEditingController _contentBankNotesController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _lrsUrlController = TextEditingController();
  final TextEditingController _lrsKeyController = TextEditingController();
  final TextEditingController _lrsSecretController = TextEditingController();
  final TextEditingController _supportEmailController = TextEditingController();
  final TextEditingController _supportPhoneController = TextEditingController();
  final TextEditingController _documentationUrlController = TextEditingController();
  final TextEditingController _versionTagController = TextEditingController();
  final TextEditingController _changeLogController = TextEditingController();

  // --- VARIABLES DE CONFIGURACIÓN ---
  bool _isGenerating = false;
  String _loadingMessage = 'Diseñando la arquitectura pedagógica del curso...';
  final ManuscriptLogicHandler _manuscriptLogicHandler = ManuscriptLogicHandler();
  final CourseGenerationController _courseGenerationController = CourseGenerationController();
  int _selectedZoneIndex = 0;
  String _introApproach = 'Motivacional';
  String _introDensity = "Estándar";
  String _conceptMapFormat = 'Jerárquico';
  String _projectType = 'Curso Estándar';
  double _aiAssistanceLevel = 25;
  double _numModules = 3;
  String _moduleDepth = "Intermedia";
  double _paragraphsPerBlock = 10;
  String _moduleStructure = 'Teoría + Ejemplo';
  String _objectiveCategory = 'Técnico';
  String _pedagogicalModel = 'Micro-Learning';
  String _toneStyle = 'Institucional';
  String _abstractionLevel = 'Desde Cero';
  String _voiceStyle = 'Tutor Senior';
  String _readingPace = 'Dinámico';
  String _challengeFrequency = 'Baja (solo lectura)';
  String _imageStyle = 'Fotorealista';
  final List<String> _interactionTypes = [];
  double _interactionDensity = 3;
  String _multimediaStrategy = 'Solo Texto';
  String _extractionLogic = 'Resumir PDF';
  String _faqAutomation = 'Preguntas Directas';
  String _scormVersion = 'SCORM 1.2';
  String _scormIdentifier = '';
  final List<String> _scormMetadataTags = ['Incluir palabras clave'];
  String _scormNavigationMode = 'Libre';
  bool _scormShowLmsButtons = true;
  bool _scormCustomNav = false;
  bool _scormBookmarking = true;
  double _scormMasteryScore = 80;
  String _scormCompletionStatus = 'Passed/Incomplete';
  bool _scormReportTime = true;
  double _scormCommitIntervalSeconds = 60;
  bool _scormDebugMode = false;
  String _scormExitBehavior = 'Auto-Commit';
  double _numFaqs = 5;
  final double _numEvalQuestions = 10;
  final String _evalType = "Opción Múltiple";
  String _finalExamLevel = 'Intermedio';
  double _finalExamQuestions = 20;
  double _finalExamComplexRatio = 50;
  double _finalExamPassScore = 70;
  String _finalExamTimeLimit = 'Sin límite';
  bool _finalExamShowTimer = true;
  bool _finalExamShuffleQuestions = true;
  bool _finalExamShuffleAnswers = true;
  bool _finalExamAllowBack = true;
  bool _finalExamShowFeedback = true;
  bool _finalExamGenerateDiploma = true;
  bool _moduleTestsEnabled = true;
  double _moduleTestQuestions = 5;
  String _moduleTestType = 'Autoevaluación';
  bool _moduleTestImmediateFeedback = true;
  String _moduleTestStyle = 'Solo Test';
  final List<Map<String, String>> _contentBankFiles = [];
  String _targetLms = 'Genérico';
  final List<String> _compatibilityPatches = [];
  bool _passwordProtectionEnabled = false;
  bool _domainRestrictionEnabled = false;
  DateTime? _contentExpirationDate;
  bool _offlineModeEnabled = false;
  String _wcagLevel = 'Sin requisitos';
  bool _gdprCompliance = false;
  bool _anonymizeLearnerData = false;
  bool _xApiEnabled = false;
  double _xApiDataDensity = 25;

  Future<void> _pickContentBankFiles({
    required String type,
    required FileType fileType,
    List<String>? allowedExtensions,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: allowedExtensions,
      allowMultiple: true,
    );
    if (result == null) return;

    _scheduleSetState(() {
      for (final file in result.files) {
        _contentBankFiles.add({
          'name': file.name,
          'path': file.path ?? '',
          'type': type,
          'extension': file.extension ?? '',
          'size': file.size.toString(),
        });
      }
    });
  }

  Future<void> _selectExpirationDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _contentExpirationDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    _scheduleSetState(() => _contentExpirationDate = picked);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return "${date.year}-$month-$day";
  }

  void _scheduleSetState(VoidCallback fn) {
    Future.microtask(() {
      if (!mounted) return;
      setState(fn);
    });
  }

  void _suggestObjectivesWithAi() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sugerencias de objetivos con IA próximamente.")),
    );
  }
}
