part of 'create_course_screen.dart';

extension _CreateCourseScreenZoneBody on _CreateCourseScreenState {
  Widget _buildZoneBody() {
    switch (_selectedZoneIndex) {
      case 0:
        return IdentitySectionView(
          aiAssistanceLevel: _aiAssistanceLevel,
          onAiAssistanceChanged: (v) => _scheduleSetState(() => _aiAssistanceLevel = v),
          projectTypeOptions: CreationOptionSets.projectTypeOptions,
          projectType: _projectType,
          onProjectTypeChanged: (v) => _scheduleSetState(() => _projectType = v),
          titleController: _titleController,
          baseContentController: _baseContentController,
          inputStyle: inputStyle,
        );
      case 1:
        return StrategySectionView(
          inputStyle: inputStyle,
          onSuggestObjectives: _suggestObjectivesWithAi,
          objectivesController: _objectivesController,
          introApproachOptions: CreationOptionSets.introApproachOptions,
          introApproach: _introApproach,
          onIntroApproachChanged: (v) => _scheduleSetState(() => _introApproach = v),
          introDensity: _introDensity,
          onIntroDensityChanged: (v) => _scheduleSetState(() => _introDensity = v),
          objectiveCategoryOptions: CreationOptionSets.objectiveCategoryOptions,
          objectiveCategory: _objectiveCategory,
          onObjectiveCategoryChanged: (v) => _scheduleSetState(() => _objectiveCategory = v),
          conceptMapOptions: CreationOptionSets.conceptMapOptions,
          conceptMapFormat: _conceptMapFormat,
          onConceptMapFormatChanged: (v) => _scheduleSetState(() => _conceptMapFormat = v),
        );
      case 2:
        return ArchitectureSectionView(
          pedagogicalModelOptions: CreationOptionSets.pedagogicalModelOptions,
          pedagogicalModel: _pedagogicalModel,
          onPedagogicalModelChanged: (v) => _scheduleSetState(() => _pedagogicalModel = v),
          numModules: _numModules,
          onNumModulesChanged: (v) => _scheduleSetState(() => _numModules = v),
          moduleDepth: _moduleDepth,
          onModuleDepthChanged: (v) => _scheduleSetState(() => _moduleDepth = v),
          paragraphsPerBlock: _paragraphsPerBlock,
          onParagraphsPerBlockChanged: (v) => _scheduleSetState(() => _paragraphsPerBlock = v),
          moduleStructureOptions: CreationOptionSets.moduleStructureOptions,
          moduleStructure: _moduleStructure,
          onModuleStructureChanged: (v) => _scheduleSetState(() => _moduleStructure = v),
        );
      case 3:
        return StyleSectionView(
          inputStyle: inputStyle,
          styleNotesController: _styleNotesController,
          toneStyleOptions: CreationOptionSets.toneStyleOptions,
          toneStyle: _toneStyle,
          onToneStyleChanged: (v) => _scheduleSetState(() => _toneStyle = v),
          abstractionLevelOptions: CreationOptionSets.abstractionLevelOptions,
          abstractionLevel: _abstractionLevel,
          onAbstractionLevelChanged: (v) => _scheduleSetState(() => _abstractionLevel = v),
          voiceStyleOptions: CreationOptionSets.voiceStyleOptions,
          voiceStyle: _voiceStyle,
          onVoiceStyleChanged: (v) => _scheduleSetState(() => _voiceStyle = v),
          readingPaceOptions: CreationOptionSets.readingPaceOptions,
          readingPace: _readingPace,
          onReadingPaceChanged: (v) => _scheduleSetState(() => _readingPace = v),
        );
      case 4:
        return SupportSectionView(
          inputStyle: inputStyle,
          resourcesController: _resourcesController,
          glossaryController: _glossaryController,
          extractionLogicOptions: CreationOptionSets.extractionLogicOptions,
          extractionLogic: _extractionLogic,
          onExtractionLogicChanged: (v) => _scheduleSetState(() => _extractionLogic = v),
          faqAutomationOptions: CreationOptionSets.faqAutomationOptions,
          faqAutomation: _faqAutomation,
          onFaqAutomationChanged: (v) => _scheduleSetState(() => _faqAutomation = v),
          numFaqs: _numFaqs,
          onNumFaqsChanged: (v) => _scheduleSetState(() => _numFaqs = v),
        );
      case 5:
        return InteractivitySectionView(
          interactionDensity: _interactionDensity,
          onInteractionDensityChanged: (v) => _scheduleSetState(() => _interactionDensity = v),
          challengeFrequencyOptions: CreationOptionSets.challengeFrequencyOptions,
          challengeFrequency: _challengeFrequency,
          onChallengeFrequencyChanged: (v) => _scheduleSetState(() => _challengeFrequency = v),
          interactionTypeOptions: CreationOptionSets.interactionTypeOptions,
          interactionTypes: _interactionTypes,
          onInteractionTypesChanged: (values) => _scheduleSetState(() => _interactionTypes
            ..clear()
            ..addAll(values)),
        );
      case 6:
        return MultimediaSectionView(
          multimediaStrategyOptions: CreationOptionSets.multimediaStrategyOptions,
          multimediaStrategy: _multimediaStrategy,
          onMultimediaStrategyChanged: (v) => _scheduleSetState(() => _multimediaStrategy = v),
          imageStyleOptions: CreationOptionSets.imageStyleOptions,
          imageStyle: _imageStyle,
          onImageStyleChanged: (v) => _scheduleSetState(() => _imageStyle = v),
        );
      case 7:
        return EvaluationSectionView(
          finalExamLevelOptions: CreationOptionSets.finalExamLevelOptions,
          finalExamLevel: _finalExamLevel,
          onFinalExamLevelChanged: (v) => _scheduleSetState(() => _finalExamLevel = v),
          finalExamQuestions: _finalExamQuestions,
          onFinalExamQuestionsChanged: (v) => _scheduleSetState(() => _finalExamQuestions = v),
          finalExamComplexRatio: _finalExamComplexRatio,
          onFinalExamComplexRatioChanged: (v) => _scheduleSetState(() => _finalExamComplexRatio = v),
          finalExamTimeOptions: CreationOptionSets.finalExamTimeOptions,
          finalExamTimeLimit: _finalExamTimeLimit,
          onFinalExamTimeLimitChanged: (v) => _scheduleSetState(() => _finalExamTimeLimit = v),
          finalExamShowTimer: _finalExamShowTimer,
          onFinalExamShowTimerChanged: (v) => _scheduleSetState(() => _finalExamShowTimer = v),
          finalExamShuffleQuestions: _finalExamShuffleQuestions,
          onFinalExamShuffleQuestionsChanged: (v) => _scheduleSetState(() => _finalExamShuffleQuestions = v),
          finalExamShuffleAnswers: _finalExamShuffleAnswers,
          onFinalExamShuffleAnswersChanged: (v) => _scheduleSetState(() => _finalExamShuffleAnswers = v),
          finalExamAllowBack: _finalExamAllowBack,
          onFinalExamAllowBackChanged: (v) => _scheduleSetState(() => _finalExamAllowBack = v),
          finalExamShowFeedback: _finalExamShowFeedback,
          onFinalExamShowFeedbackChanged: (v) => _scheduleSetState(() => _finalExamShowFeedback = v),
          finalExamGenerateDiploma: _finalExamGenerateDiploma,
          onFinalExamGenerateDiplomaChanged: (v) => _scheduleSetState(() => _finalExamGenerateDiploma = v),
          finalExamPassScore: _finalExamPassScore,
          onFinalExamPassScoreChanged: (v) => _scheduleSetState(() => _finalExamPassScore = v),
          moduleTestsEnabled: _moduleTestsEnabled,
          onModuleTestsEnabledChanged: (v) => _scheduleSetState(() => _moduleTestsEnabled = v),
          moduleTestQuestions: _moduleTestQuestions,
          onModuleTestQuestionsChanged: (v) => _scheduleSetState(() => _moduleTestQuestions = v),
          moduleTestTypeOptions: CreationOptionSets.moduleTestTypeOptions,
          moduleTestType: _moduleTestType,
          onModuleTestTypeChanged: (v) => _scheduleSetState(() => _moduleTestType = v),
          moduleTestImmediateFeedback: _moduleTestImmediateFeedback,
          onModuleTestImmediateFeedbackChanged: (v) =>
              _scheduleSetState(() => _moduleTestImmediateFeedback = v),
          moduleTestStyleOptions: CreationOptionSets.moduleTestStyleOptions,
          moduleTestStyle: _moduleTestStyle,
          onModuleTestStyleChanged: (v) => _scheduleSetState(() => _moduleTestStyle = v),
        );
      case 8:
        return ScormSectionView(
          inputStyle: inputStyle,
          scormIdentifierController: _scormIdentifierController,
          scormNotesController: _scormNotesController,
          scormVersionOptions: CreationOptionSets.scormVersionOptions,
          scormVersion: _scormVersion,
          onScormVersionChanged: (v) => _scheduleSetState(() => _scormVersion = v),
          onScormIdentifierChanged: (v) => _scheduleSetState(() => _scormIdentifier = v.trim()),
          scormMetadataOptions: CreationOptionSets.scormMetadataOptions,
          scormMetadataTags: _scormMetadataTags,
          onScormMetadataTagsChanged: (values) => _scheduleSetState(() => _scormMetadataTags
            ..clear()
            ..addAll(values)),
          scormNavigationOptions: CreationOptionSets.scormNavigationOptions,
          scormNavigationMode: _scormNavigationMode,
          onScormNavigationModeChanged: (v) => _scheduleSetState(() => _scormNavigationMode = v),
          scormShowLmsButtons: _scormShowLmsButtons,
          onScormShowLmsButtonsChanged: (v) => _scheduleSetState(() {
            _scormShowLmsButtons = v;
            if (v) _scormCustomNav = false;
          }),
          scormCustomNav: _scormCustomNav,
          onScormCustomNavChanged: (v) => _scheduleSetState(() {
            _scormCustomNav = v;
            if (v) _scormShowLmsButtons = false;
          }),
          scormBookmarking: _scormBookmarking,
          onScormBookmarkingChanged: (v) => _scheduleSetState(() => _scormBookmarking = v),
          scormMasteryScore: _scormMasteryScore,
          onScormMasteryScoreChanged: (v) => _scheduleSetState(() => _scormMasteryScore = v),
          scormCompletionOptions: CreationOptionSets.scormCompletionOptions,
          scormCompletionStatus: _scormCompletionStatus,
          onScormCompletionStatusChanged: (v) => _scheduleSetState(() => _scormCompletionStatus = v),
          scormReportTime: _scormReportTime,
          onScormReportTimeChanged: (v) => _scheduleSetState(() => _scormReportTime = v),
          scormDebugMode: _scormDebugMode,
          onScormDebugModeChanged: (v) => _scheduleSetState(() => _scormDebugMode = v),
          scormExitOptions: CreationOptionSets.scormExitOptions,
          scormExitBehavior: _scormExitBehavior,
          onScormExitBehaviorChanged: (v) => _scheduleSetState(() => _scormExitBehavior = v),
          scormCommitIntervalSeconds: _scormCommitIntervalSeconds,
          onScormCommitIntervalSecondsChanged: (v) =>
              _scheduleSetState(() => _scormCommitIntervalSeconds = v),
        );
      case 9:
        return EcosystemSectionView(
          inputStyle: inputStyle,
          xApiDataDensity: _xApiDataDensity,
          xApiEnabled: _xApiEnabled,
          onXApiDataDensityChanged: (v) => _scheduleSetState(() => _xApiDataDensity = v),
          xApiDataDensityLabel: xApiDensityLabel(_xApiDataDensity),
          onSelectExpirationDate: _selectExpirationDate,
          formatDate: _formatDate,
          targetLmsOptions: CreationOptionSets.targetLmsOptions,
          targetLms: _targetLms,
          onTargetLmsChanged: (v) => _scheduleSetState(() => _targetLms = v),
          compatibilityPatchOptions: CreationOptionSets.compatibilityPatchOptions,
          compatibilityPatches: _compatibilityPatches,
          onCompatibilityPatchesChanged: (values) => _scheduleSetState(() => _compatibilityPatches
            ..clear()
            ..addAll(values)),
          passwordProtectionEnabled: _passwordProtectionEnabled,
          onPasswordProtectionEnabledChanged: (v) => _scheduleSetState(() => _passwordProtectionEnabled = v),
          passwordController: _passwordController,
          domainRestrictionEnabled: _domainRestrictionEnabled,
          onDomainRestrictionEnabledChanged: (v) => _scheduleSetState(() => _domainRestrictionEnabled = v),
          domainController: _domainController,
          contentExpirationDate: _contentExpirationDate,
          offlineModeEnabled: _offlineModeEnabled,
          onOfflineModeEnabledChanged: (v) => _scheduleSetState(() => _offlineModeEnabled = v),
          wcagLevelOptions: CreationOptionSets.wcagLevelOptions,
          wcagLevel: _wcagLevel,
          onWcagLevelChanged: (v) => _scheduleSetState(() => _wcagLevel = v),
          gdprCompliance: _gdprCompliance,
          onGdprComplianceChanged: (v) => _scheduleSetState(() => _gdprCompliance = v),
          anonymizeLearnerData: _anonymizeLearnerData,
          onAnonymizeLearnerDataChanged: (v) => _scheduleSetState(() => _anonymizeLearnerData = v),
          onXApiEnabledChanged: (v) => _scheduleSetState(() => _xApiEnabled = v),
          lrsUrlController: _lrsUrlController,
          lrsKeyController: _lrsKeyController,
          lrsSecretController: _lrsSecretController,
          supportEmailController: _supportEmailController,
          supportPhoneController: _supportPhoneController,
          documentationUrlController: _documentationUrlController,
          versionTagController: _versionTagController,
          changeLogController: _changeLogController,
          ecosystemNotesController: _ecosystemNotesController,
        );
      case 10:
        return ContentBankSectionView(
          inputStyle: inputStyle,
          contentBankNotesController: _contentBankNotesController,
          contentBankFiles: _contentBankFiles,
          onPickAudio: () => _pickContentBankFiles(
            type: 'audio',
            fileType: FileType.audio,
          ),
          onPickVideo: () => _pickContentBankFiles(
            type: 'video',
            fileType: FileType.video,
          ),
          onPickImage: () => _pickContentBankFiles(
            type: 'image',
            fileType: FileType.image,
          ),
          onPickDocument: () => _pickContentBankFiles(
            type: 'document',
            fileType: FileType.custom,
            allowedExtensions: ['pdf', 'docx'],
          ),
          iconForType: iconForContentBankType,
          onRemoveFile: (index) => _scheduleSetState(() => _contentBankFiles.removeAt(index)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
