part of 'create_course_screen.dart';

class _CreateCourseScreenState extends State<CreateCourseScreen> with _CreateCourseStateFields {
  @override
  void initState() {
    super.initState();
    _scormIdentifierController.text = _scormIdentifier;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _baseContentController.dispose();
    _objectivesController.dispose();
    _glossaryController.dispose();
    _resourcesController.dispose();
    _styleNotesController.dispose();
    _scormNotesController.dispose();
    _scormIdentifierController.dispose();
    _ecosystemNotesController.dispose();
    _contentBankNotesController.dispose();
    _passwordController.dispose();
    _domainController.dispose();
    _lrsUrlController.dispose();
    _lrsKeyController.dispose();
    _lrsSecretController.dispose();
    _supportEmailController.dispose();
    _supportPhoneController.dispose();
    _documentationUrlController.dispose();
    _versionTagController.dispose();
    _changeLogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Consola de Autoría Profesional"),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Row(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          selectedIndex: _selectedZoneIndex,
                          onDestinationSelected: (index) => _scheduleSetState(() => _selectedZoneIndex = index),
                          backgroundColor: const Color(0xFF0F172A),
                          minWidth: 84,
                          extended: false,
                          selectedIconTheme: const IconThemeData(color: Colors.white),
                          unselectedIconTheme: const IconThemeData(color: Colors.white54),
                          labelType: NavigationRailLabelType.all,
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.badge_outlined),
                              selectedIcon: Icon(Icons.badge),
                              label: Text('Identidad'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.alt_route_outlined),
                              selectedIcon: Icon(Icons.alt_route),
                              label: Text('Estrategia'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.account_tree_outlined),
                              selectedIcon: Icon(Icons.account_tree),
                              label: Text('Arquitectura'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.palette_outlined),
                              selectedIcon: Icon(Icons.palette),
                              label: Text('Estilo'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.support_agent_outlined),
                              selectedIcon: Icon(Icons.support_agent),
                              label: Text('Soporte'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.sports_esports_outlined),
                              selectedIcon: Icon(Icons.sports_esports),
                              label: Text('Interactividad'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.movie_outlined),
                              selectedIcon: Icon(Icons.movie),
                              label: Text('Multimedia'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.verified_outlined),
                              selectedIcon: Icon(Icons.verified),
                              label: Text('Evaluación'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.rule_outlined),
                              selectedIcon: Icon(Icons.rule),
                              label: Text('SCORM'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.hub_outlined),
                              selectedIcon: Icon(Icons.hub),
                              label: Text('Ecosistema'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.cloud_upload_outlined),
                              selectedIcon: Icon(Icons.cloud_upload),
                              label: Text('Banco'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _buildZoneBody()),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _startManuscriptFlow,
                          icon: const Icon(Icons.bolt, color: Colors.white, size: 28),
                          label: const Text(
                            "GENERAR CURSO COMPLETO",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6200EE),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isGenerating) LoadingOverlay(message: _loadingMessage),
        ],
      ),
    ); 
  }

  Future<void> _startManuscriptFlow() async {
    final config = _courseGenerationController.buildGenerationConfig(
      title: _titleController.text,
      baseContent: _baseContentController.text.trim(),
      contentBankFiles: _contentBankFiles,
      contentBankNotes: _contentBankNotesController.text.trim(),
      introApproach: _introApproach,
      introDensity: _introDensity,
      objectives: _objectivesController.text,
      conceptMapFormat: _conceptMapFormat,
      projectType: _projectType,
      aiAssistanceLevel: _aiAssistanceLevel,
      moduleCount: _numModules.toInt(),
      moduleDepth: _moduleDepth,
      paragraphsPerBlock: _paragraphsPerBlock.toInt(),
      moduleStructure: _moduleStructure,
      objectiveCategory: _objectiveCategory,
      pedagogicalModel: _pedagogicalModel,
      toneStyle: _toneStyle,
      abstractionLevel: _abstractionLevel,
      voiceStyle: _voiceStyle,
      readingPace: _readingPace,
      challengeFrequency: _challengeFrequency,
      imageStyle: _imageStyle,
      interactionTypes: _interactionTypes,
      interactionDensity: _interactionDensity.toInt(),
      multimediaStrategy: _multimediaStrategy,
      extractionLogic: _extractionLogic,
      faqAutomation: _faqAutomation,
      glossary: _glossaryController.text,
      resources: _resourcesController.text,
      faqCount: _numFaqs.toInt(),
      evalQuestionCount: _numEvalQuestions.toInt(),
      evalType: _evalType,
      finalExamLevel: _finalExamLevel,
      finalExamQuestions: _finalExamQuestions.toInt(),
      finalExamComplexRatio: _finalExamComplexRatio.toInt(),
      finalExamPassScore: _finalExamPassScore.toInt(),
      finalExamTimeLimit: _finalExamTimeLimit,
      finalExamShowTimer: _finalExamShowTimer,
      finalExamShuffleQuestions: _finalExamShuffleQuestions,
      finalExamShuffleAnswers: _finalExamShuffleAnswers,
      finalExamAllowBack: _finalExamAllowBack,
      finalExamShowFeedback: _finalExamShowFeedback,
      finalExamGenerateDiploma: _finalExamGenerateDiploma,
      moduleTestsEnabled: _moduleTestsEnabled,
      moduleTestQuestions: _moduleTestQuestions.toInt(),
      moduleTestType: _moduleTestType,
      moduleTestImmediateFeedback: _moduleTestImmediateFeedback,
      moduleTestStyle: _moduleTestStyle,
      styleNotes: _styleNotesController.text,
      scormNotes: _scormNotesController.text,
      scormVersion: _scormVersion,
      scormIdentifier: _scormIdentifier,
      scormMetadataTags: _scormMetadataTags,
      scormNavigationMode: _scormNavigationMode,
      scormShowLmsButtons: _scormShowLmsButtons,
      scormCustomNav: _scormCustomNav,
      scormBookmarking: _scormBookmarking,
      scormMasteryScore: _scormMasteryScore.toInt(),
      scormCompletionStatus: _scormCompletionStatus,
      scormReportTime: _scormReportTime,
      scormCommitIntervalSeconds: _scormCommitIntervalSeconds.toInt(),
      scormDebugMode: _scormDebugMode,
      scormExitBehavior: _scormExitBehavior,
      ecosystemNotes: _ecosystemNotesController.text,
      targetLms: _targetLms,
      compatibilityPatches: _compatibilityPatches,
      passwordProtectionEnabled: _passwordProtectionEnabled,
      passwordProtectionValue: _passwordController.text.trim(),
      domainRestrictionEnabled: _domainRestrictionEnabled,
      allowedDomain: _domainController.text.trim(),
      expirationDate: _contentExpirationDate?.toIso8601String() ?? '',
      offlineModeEnabled: _offlineModeEnabled,
      wcagLevel: _wcagLevel,
      gdprCompliance: _gdprCompliance,
      anonymizeLearnerData: _anonymizeLearnerData,
      xApiEnabled: _xApiEnabled,
      lrsUrl: _lrsUrlController.text.trim(),
      lrsKey: _lrsKeyController.text.trim(),
      lrsSecret: _lrsSecretController.text.trim(),
      xApiDataDensity: _xApiDataDensity.toInt(),
      supportEmail: _supportEmailController.text.trim(),
      supportPhone: _supportPhoneController.text.trim(),
      documentationUrl: _documentationUrlController.text.trim(),
      versionTag: _versionTagController.text.trim(),
      changeLog: _changeLogController.text.trim(),
    );

    final courseConfig = _courseGenerationController.buildCourseConfig(
      targetLms: _targetLms,
      compatibilityPatches: _compatibilityPatches,
      passwordProtectionEnabled: _passwordProtectionEnabled,
      password: _passwordController.text.trim(),
      domainRestrictionEnabled: _domainRestrictionEnabled,
      allowedDomain: _domainController.text.trim(),
      expirationDate: _contentExpirationDate?.toIso8601String() ?? '',
      offlineModeEnabled: _offlineModeEnabled,
      wcagLevel: _wcagLevel,
      gdprCompliance: _gdprCompliance,
      anonymizeLearnerData: _anonymizeLearnerData,
      xApiEnabled: _xApiEnabled,
      lrsUrl: _lrsUrlController.text.trim(),
      lrsKey: _lrsKeyController.text.trim(),
      lrsSecret: _lrsSecretController.text.trim(),
      xApiDataDensity: _xApiDataDensity.toInt(),
      supportEmail: _supportEmailController.text.trim(),
      supportPhone: _supportPhoneController.text.trim(),
      documentationUrl: _documentationUrlController.text.trim(),
      versionTag: _versionTagController.text.trim(),
      changeLog: _changeLogController.text.trim(),
      ecosystemNotes: _ecosystemNotesController.text.trim(),
    );

    await _manuscriptLogicHandler.startManuscriptFlow(
      context: context,
      mounted: mounted,
      title: _titleController.text,
      baseContent: _baseContentController.text.trim(),
      contentBankFiles: _contentBankFiles,
      contentBankNotes: _contentBankNotesController.text.trim(),
      generationConfig: config,
      courseConfig: courseConfig,
      onLoadingMessage: (message) => _scheduleSetState(() => _loadingMessage = message),
      onLoadingChanged: (value) => _scheduleSetState(() => _isGenerating = value),
    );
  }
}
