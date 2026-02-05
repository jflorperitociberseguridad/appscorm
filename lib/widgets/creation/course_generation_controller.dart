import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../models/course_model.dart';
import '../../models/interactive_block.dart';
import '../../models/module_model.dart';
import '../../providers/course_provider.dart';

class CourseGenerationController {
  Map<String, dynamic> buildGenerationConfig({
    required String title,
    required String baseContent,
    required List<Map<String, String>> contentBankFiles,
    required String contentBankNotes,
    required String introApproach,
    required String introDensity,
    required String objectives,
    required String conceptMapFormat,
    required String projectType,
    required double aiAssistanceLevel,
    required int moduleCount,
    required String moduleDepth,
    required int paragraphsPerBlock,
    required String moduleStructure,
    required String objectiveCategory,
    required String pedagogicalModel,
    required String toneStyle,
    required String abstractionLevel,
    required String voiceStyle,
    required String readingPace,
    required String challengeFrequency,
    required String imageStyle,
    required List<String> interactionTypes,
    required int interactionDensity,
    required String multimediaStrategy,
    required String extractionLogic,
    required String faqAutomation,
    required String glossary,
    required String resources,
    required int faqCount,
    required int evalQuestionCount,
    required String evalType,
    required String finalExamLevel,
    required int finalExamQuestions,
    required int finalExamComplexRatio,
    required int finalExamPassScore,
    required String finalExamTimeLimit,
    required bool finalExamShowTimer,
    required bool finalExamShuffleQuestions,
    required bool finalExamShuffleAnswers,
    required bool finalExamAllowBack,
    required bool finalExamShowFeedback,
    required bool finalExamGenerateDiploma,
    required bool moduleTestsEnabled,
    required int moduleTestQuestions,
    required String moduleTestType,
    required bool moduleTestImmediateFeedback,
    required String moduleTestStyle,
    required String styleNotes,
    required String scormNotes,
    required String scormVersion,
    required String scormIdentifier,
    required List<String> scormMetadataTags,
    required String scormNavigationMode,
    required bool scormShowLmsButtons,
    required bool scormCustomNav,
    required bool scormBookmarking,
    required int scormMasteryScore,
    required String scormCompletionStatus,
    required bool scormReportTime,
    required int scormCommitIntervalSeconds,
    required bool scormDebugMode,
    required String scormExitBehavior,
    required String ecosystemNotes,
    required String targetLms,
    required List<String> compatibilityPatches,
    required bool passwordProtectionEnabled,
    required String passwordProtectionValue,
    required bool domainRestrictionEnabled,
    required String allowedDomain,
    required String expirationDate,
    required bool offlineModeEnabled,
    required String wcagLevel,
    required bool gdprCompliance,
    required bool anonymizeLearnerData,
    required bool xApiEnabled,
    required String lrsUrl,
    required String lrsKey,
    required String lrsSecret,
    required int xApiDataDensity,
    required String supportEmail,
    required String supportPhone,
    required String documentationUrl,
    required String versionTag,
    required String changeLog,
  }) {
    return {
      'title': title,
      'baseContent': baseContent,
      'contentBankFiles': contentBankFiles,
      'contentBankNotes': contentBankNotes,
      'intro': introApproach,
      'introDensity': introDensity,
      'objectives': objectives,
      'conceptualMap': conceptMapFormat,
      'projectType': projectType,
      'aiAssistanceLevel': aiAssistanceLevel,
      'moduleCount': moduleCount,
      'moduleDepth': moduleDepth,
      'paragraphsPerBlock': paragraphsPerBlock,
      'moduleStructure': moduleStructure,
      'objectiveCategory': objectiveCategory,
      'pedagogicalModel': pedagogicalModel,
      'toneStyle': toneStyle,
      'abstractionLevel': abstractionLevel,
      'voiceStyle': voiceStyle,
      'readingPace': readingPace,
      'challengeFrequency': challengeFrequency,
      'imageStyle': imageStyle,
      'interactionTypes': interactionTypes,
      'interactionDensity': interactionDensity,
      'multimediaStrategy': multimediaStrategy,
      'extractionLogic': extractionLogic,
      'faqAutomation': faqAutomation,
      'glossary': glossary,
      'resources': resources,
      'faqCount': faqCount,
      'evalQuestionCount': evalQuestionCount,
      'evalType': evalType,
      'finalExamLevel': finalExamLevel,
      'finalExamQuestions': finalExamQuestions,
      'finalExamComplexRatio': finalExamComplexRatio,
      'finalExamPassScore': finalExamPassScore,
      'finalExamTimeLimit': finalExamTimeLimit,
      'finalExamShowTimer': finalExamShowTimer,
      'finalExamShuffleQuestions': finalExamShuffleQuestions,
      'finalExamShuffleAnswers': finalExamShuffleAnswers,
      'finalExamAllowBack': finalExamAllowBack,
      'finalExamShowFeedback': finalExamShowFeedback,
      'finalExamGenerateDiploma': finalExamGenerateDiploma,
      'moduleTestsEnabled': moduleTestsEnabled,
      'moduleTestQuestions': moduleTestQuestions,
      'moduleTestType': moduleTestType,
      'moduleTestImmediateFeedback': moduleTestImmediateFeedback,
      'moduleTestStyle': moduleTestStyle,
      'styleNotes': styleNotes,
      'scormNotes': scormNotes,
      'scormVersion': scormVersion,
      'scormIdentifier': scormIdentifier,
      'scormMetadataTags': scormMetadataTags,
      'scormNavigationMode': scormNavigationMode,
      'scormShowLmsButtons': scormShowLmsButtons,
      'scormCustomNav': scormCustomNav,
      'scormBookmarking': scormBookmarking,
      'scormMasteryScore': scormMasteryScore,
      'scormCompletionStatus': scormCompletionStatus,
      'scormReportTime': scormReportTime,
      'scormCommitIntervalSeconds': scormCommitIntervalSeconds,
      'scormDebugMode': scormDebugMode,
      'scormExitBehavior': scormExitBehavior,
      'ecosystemNotes': ecosystemNotes,
      'targetLms': targetLms,
      'compatibilityPatches': compatibilityPatches,
      'passwordProtectionEnabled': passwordProtectionEnabled,
      'passwordProtectionValue': passwordProtectionValue,
      'domainRestrictionEnabled': domainRestrictionEnabled,
      'allowedDomain': allowedDomain,
      'expirationDate': expirationDate,
      'offlineModeEnabled': offlineModeEnabled,
      'wcagLevel': wcagLevel,
      'gdprCompliance': gdprCompliance,
      'anonymizeLearnerData': anonymizeLearnerData,
      'xApiEnabled': xApiEnabled,
      'lrsUrl': lrsUrl,
      'lrsKey': lrsKey,
      'lrsSecret': lrsSecret,
      'xApiDataDensity': xApiDataDensity,
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'documentationUrl': documentationUrl,
      'versionTag': versionTag,
      'changeLog': changeLog,
    };
  }

  CourseConfig buildCourseConfig({
    required String targetLms,
    required List<String> compatibilityPatches,
    required bool passwordProtectionEnabled,
    required String password,
    required bool domainRestrictionEnabled,
    required String allowedDomain,
    required String expirationDate,
    required bool offlineModeEnabled,
    required String wcagLevel,
    required bool gdprCompliance,
    required bool anonymizeLearnerData,
    required bool xApiEnabled,
    required String lrsUrl,
    required String lrsKey,
    required String lrsSecret,
    required int xApiDataDensity,
    required String supportEmail,
    required String supportPhone,
    required String documentationUrl,
    required String versionTag,
    required String changeLog,
    required String ecosystemNotes,
  }) {
    return CourseConfig(
      targetLms: targetLms,
      compatibilityPatches: List<String>.from(compatibilityPatches),
      passwordProtectionEnabled: passwordProtectionEnabled,
      password: password,
      domainRestrictionEnabled: domainRestrictionEnabled,
      allowedDomain: allowedDomain,
      expirationDate: expirationDate,
      offlineModeEnabled: offlineModeEnabled,
      wcagLevel: wcagLevel,
      gdprCompliance: gdprCompliance,
      anonymizeLearnerData: anonymizeLearnerData,
      xApiEnabled: xApiEnabled,
      lrsUrl: lrsUrl,
      lrsKey: lrsKey,
      lrsSecret: lrsSecret,
      xApiDataDensity: xApiDataDensity,
      supportEmail: supportEmail,
      supportPhone: supportPhone,
      documentationUrl: documentationUrl,
      versionTag: versionTag,
      changeLog: changeLog,
      ecosystemNotes: ecosystemNotes,
    );
  }

  Future<void> generateCourseFromManuscript({
    required BuildContext context,
    required String manuscript,
    required Map<String, dynamic> config,
    required List<Map<String, String>> contentBankFiles,
    required CourseConfig courseConfig,
    required void Function(String message) onLoadingMessage,
    required void Function(bool value) onLoadingChanged,
    required bool mounted,
  }) async {
    if (manuscript.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ El manuscrito está vacío.")),
      );
      return;
    }

    onLoadingMessage('Construyendo el curso desde el manuscrito...');
    onLoadingChanged(true);

    try {
      final title = (config['title'] ?? 'Curso SCORM').toString().trim();
      final scormVersion = (config['scormVersion'] ?? '1.2').toString();
      final modulesFromJson = _tryParseModulesFromJson(manuscript, config);
      final modules = modulesFromJson.isNotEmpty
          ? modulesFromJson
          : _buildModulesFromMarkdown(
              manuscript,
              config,
              fallbackTitle: title.isEmpty ? 'Módulo 1' : 'Módulo 1 · $title',
            );
      final moduleInstances = <ModuleModel>[];
      for (var i = 0; i < modules.length; i++) {
        final module = modules[i];
        moduleInstances.add(ModuleModel(
          id: const Uuid().v4(),
          title: module.title,
          order: i,
          blocks: List<InteractiveBlock>.from(module.blocks),
          type: module.type,
          content: module.content,
        ));
      }
      final referenceModule = _buildReferenceModule(manuscript);

      final container = ProviderScope.containerOf(context, listen: false);
      final existingCourse = container.read(courseProvider);
      final course = _buildCourseFromTemplate(
        existingCourse: existingCourse,
        title: title.isEmpty ? 'Nuevo Curso Formativo' : title,
        courseConfig: courseConfig,
        scormVersion: scormVersion,
        modules: moduleInstances,
        referenceModule: referenceModule,
      );
      course.contentBank.files =
          List<Map<String, String>>.from(contentBankFiles);
      _populateGuideSectionsFromModule(course);
      container
          .read(courseProvider.notifier)
          .updateCourse(course.copyWith(modules: moduleInstances));

      if (!context.mounted) return;
      container.read(courseProvider.notifier).updateFullCourse(course);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('🚀 Arquitectura instruccional desplegada con éxito')),
      );
      _scrollEditorToTop(context);
      final payload = course.toJson();
      payload['_scrollToTop'] = true;
      context.push('/course-dashboard', extra: payload);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) onLoadingChanged(false);
    }
  }

  void _populateGuideSectionsFromModule(CourseModel course) {
    if (course.modules.isEmpty) return;
    String? currentBucket;

    bool hasMeaningfulBlocks(List<InteractiveBlock> blocks) {
      for (final block in blocks) {
        if (block.content.isEmpty) continue;
        for (final value in block.content.values) {
          if (value == null) continue;
          if (value is String && value.trim().isEmpty) continue;
          if (value is List && value.isEmpty) continue;
          if (value is Map && value.isEmpty) continue;
          return true;
        }
      }
      return false;
    }

    String? detectBucket(String text) {
      final upper = text.toUpperCase();
      if (upper.contains('INTRODUCCIÓN') || upper.contains('INTRODUCCION')) {
        return 'intro';
      }
      if (upper.contains('OBJETIVOS')) {
        return 'objectives';
      }
      if (upper.contains('MAPA CONCEPTUAL')) {
        return 'map';
      }
      if (upper.contains('RECURSOS') || upper.contains('BIBLIOGRAF')) {
        return 'resources';
      }
      if (upper.contains('GLOSARIO')) {
        return 'glossary';
      }
      if (upper.contains('FAQ') || upper.contains('PREGUNTAS FRECUENTES')) {
        return 'faq';
      }
      if (upper.contains('EVALUACIÓN') ||
          upper.contains('EVALUACION') ||
          upper.contains('EXAMEN')) {
        return 'eval';
      }
      return null;
    }

    bool isModuleHeading(String text) {
      final upper = text.toUpperCase();
      return upper.contains('MÓDULO') ||
          upper.contains('MODULO') ||
          upper.startsWith('TEMA ');
    }

    List<InteractiveBlock> targetBlocks(String bucket) {
      switch (bucket) {
        case 'intro':
          return course.intro.introBlocks;
        case 'objectives':
          return course.intro.objectiveBlocks;
        case 'map':
          return course.conceptMap.blocks;
        case 'resources':
          return course.resources.blocks;
        case 'glossary':
          return course.glossary.blocks;
        case 'faq':
          return course.faq.blocks;
        case 'eval':
          return course.evaluation.blocks;
        default:
          return <InteractiveBlock>[];
      }
    }

    void addToBucket(String bucket, InteractiveBlock block) {
      final target = targetBlocks(bucket);
      if (!hasMeaningfulBlocks(target)) {
        target
          ..clear()
          ..add(block);
      } else {
        target.add(block);
      }
    }

    for (final module in course.modules) {
      final remaining = <InteractiveBlock>[];
      currentBucket = null;
      for (final block in module.blocks) {
        if (block.type == BlockType.textPlain ||
            block.type == BlockType.textRich ||
            block.type == BlockType.essay) {
          final text = (block.content['text'] ?? '').toString();
          if (isModuleHeading(text)) {
            currentBucket = null;
            remaining.add(block);
            continue;
          }
          final detected = detectBucket(text);
          if (detected != null) {
            currentBucket = detected;
            addToBucket(detected, block);
            continue;
          }
        }

        if (currentBucket != null) {
          final bucket = currentBucket;
          addToBucket(bucket, block);
          continue;
        }

        remaining.add(block);
      }

      module.blocks
        ..clear()
        ..addAll(remaining);
    }
  }

  CourseModel _buildCourseFromTemplate({
    required CourseModel? existingCourse,
    required String title,
    required CourseConfig courseConfig,
    required String scormVersion,
    required List<ModuleModel> modules,
    ModuleModel? referenceModule,
  }) {
    final base = existingCourse;
    return CourseModel(
      id: base?.id ?? const Uuid().v4(),
      userId: base?.userId ?? 'local_user',
      title: title,
      description: base?.description ?? '',
      createdAt: base?.createdAt ?? DateTime.now(),
      scormVersion: base?.scormVersion ?? scormVersion,
      config: courseConfig,
      modules: modules,
      introText: base?.introText ?? '',
      objectives: base?.objectives,
      glossaryItems: base?.glossaryItems,
      faqItems: base?.faqItems,
      general: base?.general,
      intro: base?.intro,
      conceptMap: base?.conceptMap,
      resources: base?.resources,
      glossary: base?.glossary,
      faq: base?.faq,
      evaluation: base?.evaluation,
      stats: base?.stats,
      contentBank: base?.contentBank,
      referenceModule: referenceModule ?? base?.referenceModule,
    );
  }

  List<ModuleModel> _buildModulesFromMarkdown(
    String manuscript,
    Map<String, dynamic> config, {
    required String fallbackTitle,
  }) {
    final rawBlocks = _parseManuscriptBlocks(manuscript, config);
    final regexModules =
        _splitBlocksIntoModulesByRegex(rawBlocks, fallbackTitle: fallbackTitle);
    if (regexModules.length > 1) {
      return regexModules;
    }

    final moduleDrafts =
        _splitManuscriptIntoModules(manuscript, fallbackTitle: fallbackTitle);
    final modules = <ModuleModel>[];
    for (var i = 0; i < moduleDrafts.length; i++) {
      final draft = moduleDrafts[i];
      final blocks = _parseManuscriptBlocks(draft.content, config);
      final moduleTitle = draft.title.trim().isNotEmpty
          ? draft.title.trim()
          : 'Módulo ${i + 1}';
      modules.add(ModuleModel(
        id: const Uuid().v4(),
        title: moduleTitle,
        order: i,
        blocks: blocks,
        type: ModuleType.text,
        content: '',
      ));
    }
    return modules;
  }

  ModuleModel _buildReferenceModule(String manuscript) {
    final sanitized = manuscript.trim();
    final displayText =
        sanitized.isEmpty ? 'Manuscrito sin contenido disponible.' : sanitized;

    return ModuleModel(
      id: const Uuid().v4(),
      title: 'Material de Referencia',
      order: 0,
      blocks: [
        InteractiveBlock.create(
          type: BlockType.textPlain,
          content: {'text': displayText},
        ),
      ],
      content: sanitized,
      type: ModuleType.text,
      isSource: true,
    );
  }

  List<ModuleModel> _tryParseModulesFromJson(
      String manuscript, Map<String, dynamic> config) {
    try {
      final decoded = jsonDecode(manuscript);
      if (decoded is! Map<String, dynamic>) return <ModuleModel>[];
      final rawModules = decoded['modules'];
      if (rawModules is! List) return <ModuleModel>[];
      final modules = <ModuleModel>[];
      for (var i = 0; i < rawModules.length; i++) {
        final raw = rawModules[i];
        if (raw is! Map) continue;
        final map = raw.cast<String, dynamic>();
        final title = (map['title'] ?? 'Módulo ${i + 1}').toString();
        final blocks = <InteractiveBlock>[];
        final rawBlocks = map['blocks'];
        if (rawBlocks is List) {
          for (final b in rawBlocks) {
            if (b is! Map) continue;
            final bMap = b.cast<String, dynamic>();
            final typeName = (bMap['type'] ?? 'textPlain').toString();
            final type = BlockType.values.firstWhere(
              (e) => e.name == typeName,
              orElse: () => BlockType.textPlain,
            );
            final rawContent = bMap['content'];
            Map<String, dynamic> content;
            if (rawContent is Map<String, dynamic>) {
              content = Map<String, dynamic>.from(rawContent);
            } else if (rawContent is String) {
              content = {'text': rawContent};
            } else {
              content = {'text': rawContent?.toString() ?? ' '};
            }
            if (!content.containsKey('text') ||
                content['text'] == null ||
                content['text'].toString().isEmpty) {
              content['text'] = ' ';
            }
            blocks.add(InteractiveBlock.create(type: type, content: content));
          }
        }
        if (blocks.isEmpty) {
          blocks.add(InteractiveBlock.create(
              type: BlockType.textPlain, content: {'text': ' '}));
        }
        modules.add(ModuleModel(
          id: const Uuid().v4(),
          title: title,
          order: i,
          blocks: blocks,
          type: ModuleType.text,
          content: '',
        ));
      }
      return modules;
    } catch (_) {
      return <ModuleModel>[];
    }
  }

  List<ModuleModel> _splitBlocksIntoModulesByRegex(
    List<InteractiveBlock> blocks, {
    required String fallbackTitle,
  }) {
    final modules = <ModuleModel>[];
    var currentTitle = fallbackTitle;
    var currentBlocks = <InteractiveBlock>[];
    final moduleRegex = RegExp(
      r'(?:Módulo|Modulo|Tema|Sección)\\s*(\\d+)[:.\\-]?',
      caseSensitive: false,
    );
    var moduleIndex = 1;

    String extractText(InteractiveBlock block) {
      final value = block.content['text'];
      if (value == null) return '';
      return value.toString();
    }

    String stripHtml(String input) {
      return input
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\\s+'), ' ')
          .trim();
    }

    void flush() {
      if (currentBlocks.isEmpty) return;
      modules.add(ModuleModel(
        id: const Uuid().v4(),
        title: currentTitle,
        order: modules.length,
        blocks: currentBlocks,
        type: ModuleType.text,
        content: '',
      ));
      currentBlocks = <InteractiveBlock>[];
    }

    for (final block in blocks) {
      final text = stripHtml(extractText(block));
      final match = moduleRegex.firstMatch(text);
      if (match != null) {
        flush();
        final number = int.tryParse(match.group(1) ?? '') ?? 0;
        final resolvedNumber = number > 0 ? number : moduleIndex;
        currentTitle = text.isNotEmpty ? text : 'Módulo $resolvedNumber';
        moduleIndex = resolvedNumber + 1;
        continue;
      }
      currentBlocks.add(block);
    }

    flush();

    return modules.isEmpty
        ? [
            ModuleModel(
              id: const Uuid().v4(),
              title: fallbackTitle,
              order: 0,
              blocks: blocks,
              type: ModuleType.text,
              content: '',
            )
          ]
        : modules;
  }

  List<InteractiveBlock> _parseManuscriptBlocks(
      String manuscript, Map<String, dynamic> config) {
    final blocks = <InteractiveBlock>[];
    final lines = manuscript.split('\n');
    final paragraphBuffer = <String>[];
    final listBuffer = <String>[];
    String currentSectionTitle = '';

    void flushParagraph() {
      if (paragraphBuffer.isEmpty) return;
      final text = paragraphBuffer.join(' ').trim();
      paragraphBuffer.clear();
      if (text.isEmpty) return;
      blocks.add(_textBlock(text, config));
    }

    void flushList() {
      if (listBuffer.isEmpty) return;
      final items = List<String>.from(listBuffer);
      listBuffer.clear();
      final lowered = currentSectionTitle.toLowerCase();
      if (lowered.contains('proceso') || lowered.contains('paso')) {
        blocks.add(_processBlock(items, config));
      } else if (lowered.contains('línea de tiempo') ||
          lowered.contains('linea de tiempo') ||
          lowered.contains('timeline')) {
        blocks.add(_timelineBlock(items, config));
      } else {
        blocks.add(_listBlock(items, config));
      }
    }

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        flushParagraph();
        flushList();
        continue;
      }

      if (trimmed.startsWith('>')) {
        flushParagraph();
        flushList();
        final quoteText = trimmed.substring(1).trim();
        blocks.add(_quoteBlock(quoteText, config));
        continue;
      }

      if (trimmed.startsWith('#')) {
        flushParagraph();
        flushList();
        final match = RegExp(r'^(#+)\\s*(.*)$').firstMatch(trimmed);
        final level = match?.group(1)?.length ?? 1;
        final title = match?.group(2)?.trim() ??
            trimmed.replaceFirst(RegExp(r'^#+'), '').trim();
        if (title.isNotEmpty) {
          blocks.add(_headerBlock(title, level, config));
          currentSectionTitle = title;
        }
        continue;
      }

      if (_isListLine(trimmed)) {
        flushParagraph();
        listBuffer.add(trimmed.replaceFirst(RegExp(r'^[-*•]\\s*'), '').trim());
        continue;
      }

      if (_containsImageMarker(trimmed)) {
        flushParagraph();
        flushList();
        blocks.add(_imageBlock(trimmed, config));
        continue;
      }

      if (_isChallengeLine(trimmed)) {
        flushParagraph();
        flushList();
        blocks.add(_challengeBlock(trimmed, config));
        continue;
      }

      if (_isQuestionLine(trimmed)) {
        flushParagraph();
        flushList();
        blocks.add(_questionBlock(trimmed, config));
        continue;
      }

      if (listBuffer.isNotEmpty) {
        flushList();
      }
      paragraphBuffer.add(trimmed);
    }

    flushParagraph();
    flushList();

    _appendDemoBlocksIfMissing(blocks, manuscript, config);

    if (blocks.isEmpty) {
      blocks.add(_textBlock('Manuscrito sin contenido procesable.', config));
    }

    _applyNavigationAndGamificationRules(blocks, config);
    return blocks;
  }

  bool _isListLine(String line) {
    return line.startsWith('- ') ||
        line.startsWith('* ') ||
        line.startsWith('• ');
  }

  bool _containsImageMarker(String line) {
    return line.contains('[IMAGEN]') ||
        line.contains('[IMAGE]') ||
        line.contains('![');
  }

  bool _isQuestionLine(String line) {
    final lower = line.toLowerCase();
    return lower.startsWith('pregunta:') ||
        line.contains('¿') ||
        line.contains('?');
  }

  bool _isChallengeLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('[reto]') || lower.startsWith('reto:');
  }

  InteractiveBlock _headerBlock(
      String text, int level, Map<String, dynamic> config) {
    final safeLevel = level.clamp(1, 3);
    final html = '<h$safeLevel>${_escapeHtml(text)}</h$safeLevel>';
    return _textBlock(html, config, rich: true);
  }

  InteractiveBlock _textBlock(String text, Map<String, dynamic> config,
      {bool rich = false}) {
    final content = <String, dynamic>{
      'text': text.trim().isEmpty ? ' ' : text.trim(),
    };
    _applyBlockDefaults(content, config);
    return InteractiveBlock.create(
        type: rich ? BlockType.textRich : BlockType.textPlain,
        content: content);
  }

  InteractiveBlock _listBlock(List<String> items, Map<String, dynamic> config) {
    final buffer = StringBuffer('<ul>');
    for (final item in items) {
      if (item.trim().isEmpty) continue;
      buffer.write('<li>${_escapeHtml(item.trim())}</li>');
    }
    buffer.write('</ul>');
    return _textBlock(buffer.toString(), config, rich: true);
  }

  InteractiveBlock _processBlock(
      List<String> items, Map<String, dynamic> config) {
    final steps = <Map<String, dynamic>>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i].trim();
      if (item.isEmpty) continue;
      final parts = item.split(':');
      final title =
          parts.first.trim().isEmpty ? 'Paso ${i + 1}' : parts.first.trim();
      final desc = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';
      steps.add({
        'title': title,
        'desc': desc,
        'icon': Icons.check_circle_outline.codePoint,
      });
    }
    final content = <String, dynamic>{'steps': steps};
    _applyBlockDefaults(content, config);
    return InteractiveBlock.create(type: BlockType.process, content: content);
  }

  InteractiveBlock _timelineBlock(
      List<String> items, Map<String, dynamic> config) {
    final events = <Map<String, dynamic>>[];
    for (final item in items) {
      final raw = item.trim();
      if (raw.isEmpty) continue;
      String date = '';
      String title = raw;
      String desc = '';
      final colonSplit = raw.split(':');
      if (colonSplit.length > 1) {
        date = colonSplit.first.trim();
        title = colonSplit.sublist(1).join(':').trim();
      }
      final dashSplit = title.split(' - ');
      if (dashSplit.length > 1) {
        title = dashSplit.first.trim();
        desc = dashSplit.sublist(1).join(' - ').trim();
      }
      events.add({
        'date': date.isEmpty ? ' ' : date,
        'title': title.isEmpty ? 'Evento' : title,
        'desc': desc,
        'icon': Icons.flag_outlined.codePoint,
      });
    }
    final content = <String, dynamic>{'events': events};
    _applyBlockDefaults(content, config);
    return InteractiveBlock.create(type: BlockType.timeline, content: content);
  }

  InteractiveBlock _quoteBlock(String text, Map<String, dynamic> config) {
    final content = <String, dynamic>{
      'text': text.trim().isEmpty ? 'Cita pendiente' : text.trim(),
      'author': '',
    };
    _applyBlockDefaults(content, config);
    return InteractiveBlock.create(type: BlockType.quote, content: content);
  }

  InteractiveBlock _questionBlock(String text, Map<String, dynamic> config) {
    final question =
        text.replaceAll('[RETO]', '').replaceAll('[reto]', '').trim();
    final safeQuestion = question.isEmpty ? 'Pregunta pendiente' : question;
    final content = <String, dynamic>{
      'question': safeQuestion,
      'options': ['Opción A', 'Opción B', 'Opción C'],
      'correctIndex': 0,
      'feedbackPositive': 'Correcto. Has respondido bien: $safeQuestion',
      'feedbackNegative':
          'Respuesta incorrecta. Revisa el contenido y vuelve a intentar: $safeQuestion',
    };
    _applyBlockDefaults(content, config);
    return InteractiveBlock.create(
        type: BlockType.singleChoice, content: content);
  }

  InteractiveBlock _flashcardsBlock(
      String frontText, String backText, Map<String, dynamic> config) {
    final content = <String, dynamic>{
      'cards': [
        {
          'frontText': frontText,
          'backText': backText,
          'frontImage': '',
          'isFlipped': false,
          'question': frontText,
          'answer': backText,
        },
      ],
    };
    _applyBlockDefaults(content, config);
    return InteractiveBlock.create(
        type: BlockType.flashcards, content: content);
  }

  InteractiveBlock _videoBlock(String url, Map<String, dynamic> config) {
    final content = <String, dynamic>{
      'url': url,
      'isLocal': false,
    };
    _applyBlockDefaults(content, config);
    return InteractiveBlock.create(type: BlockType.video, content: content);
  }

  void _appendDemoBlocksIfMissing(
    List<InteractiveBlock> blocks,
    String manuscript,
    Map<String, dynamic> config,
  ) {
    if (blocks.any((block) => _isInteractiveBlock(block.type))) {
      return;
    }

    final lower = manuscript.toLowerCase();
    final topic = lower.contains('seguridad')
        ? 'seguridad'
        : lower.contains('ventas')
            ? 'ventas'
            : lower.contains('calidad')
                ? 'calidad'
                : 'el tema central';

    blocks.add(_flashcardsBlock(
        'Concepto clave de $topic', 'Definicion resumida de $topic.', config));
    blocks.add(_questionBlock(
        'Pregunta: ¿Que idea principal recuerdas sobre $topic?', config));
    blocks
        .add(_videoBlock('https://www.youtube.com/embed/jNQXAC9IVRw', config));
  }

  InteractiveBlock _challengeBlock(String text, Map<String, dynamic> config) {
    final clean = text
        .replaceAll('[RETO]', '')
        .replaceAll('[reto]', '')
        .replaceFirst(RegExp(r'^reto:', caseSensitive: false), '')
        .trim();
    final content = <String, dynamic>{
      'introText': clean.isEmpty ? 'Reto pendiente' : clean,
      'imagePath': '',
      'options': [
        {
          'text': 'Aplicar la recomendacion principal',
          'feedback': 'Buena decision. Refuerza la seguridad y el aprendizaje.',
          'isCorrect': true,
          'bonusXP': 20,
        },
        {
          'text': 'Ignorar la recomendacion',
          'feedback': 'Riesgo detectado. Revisa el contexto antes de avanzar.',
          'isCorrect': false,
          'bonusXP': 0,
        },
      ],
    };
    _applyBlockDefaults(content, config);
    return InteractiveBlock.create(type: BlockType.scenario, content: content);
  }

  InteractiveBlock _imageBlock(String text, Map<String, dynamic> config) {
    final style = (config['imageStyle'] ?? 'Fotorealista').toString();
    final cleaned =
        text.replaceAll('[IMAGEN]', '').replaceAll('[IMAGE]', '').trim();
    final caption = cleaned.isEmpty ? 'Imagen sugerida' : cleaned;
    final content = <String, dynamic>{
      'url': 'https://placehold.co/1200x800',
      'caption': '$caption · Estilo: $style',
      'prompt': 'Estilo $style',
    };
    _applyBlockDefaults(content, config);
    return InteractiveBlock.create(type: BlockType.image, content: content);
  }

  void _applyBlockDefaults(
      Map<String, dynamic> content, Map<String, dynamic> config) {
    content['scormNavigationMode'] = config['scormNavigationMode'];
    content['scormCompletionStatus'] = config['scormCompletionStatus'];
    content['scormMasteryScore'] = config['scormMasteryScore'];
    content['scormExitBehavior'] = config['scormExitBehavior'];
    content['gamificationLevel'] = config['challengeFrequency'];
    content['interactionDensity'] = config['interactionDensity'];
  }

  void _applyNavigationAndGamificationRules(
      List<InteractiveBlock> blocks, Map<String, dynamic> config) {
    final navMode =
        (config['scormNavigationMode'] ?? '').toString().toLowerCase();
    final isLinear = navMode.contains('lineal');
    final challengeFrequency =
        (config['challengeFrequency'] ?? '').toString().toLowerCase();
    final gamificationActive = challengeFrequency.contains('preguntas') ||
        challengeFrequency.contains('gamificacion') ||
        challengeFrequency.contains('gamificación');

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      block.content['isLocked'] = isLinear && i > 0;
      if (gamificationActive && _isInteractiveBlock(block.type)) {
        block.content['xp'] = 50;
      }
    }
  }

  bool _isInteractiveBlock(BlockType type) {
    switch (type) {
      case BlockType.singleChoice:
      case BlockType.multipleChoice:
      case BlockType.trueFalse:
      case BlockType.fillBlanks:
      case BlockType.sorting:
      case BlockType.flashcards:
      case BlockType.matching:
      case BlockType.questionSet:
      case BlockType.scenario:
        return true;
      default:
        return false;
    }
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  void _scrollEditorToTop(BuildContext context) {
    if (!context.mounted) return;
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller == null || !controller.hasClients) return;
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  List<_ModuleDraft> _splitManuscriptIntoModules(String manuscript,
      {required String fallbackTitle}) {
    final lines = manuscript.split('\n');
    final modules = <_ModuleDraft>[];
    String? currentTitle;
    final buffer = <String>[];

    void flush() {
      if (currentTitle == null && buffer.isEmpty) return;
      final title = (currentTitle ?? fallbackTitle).trim();
      final content = buffer.join('\n').trim();
      modules.add(_ModuleDraft(title: title, content: content));
      buffer.clear();
    }

    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      final match = RegExp(r'^##\\s+(.*)$').firstMatch(trimmed);
      if (match != null) {
        flush();
        currentTitle = match.group(1)?.trim() ?? fallbackTitle;
        continue;
      }
      buffer.add(rawLine);
    }

    flush();

    if (modules.isEmpty) {
      return [_ModuleDraft(title: fallbackTitle, content: manuscript)];
    }

    final nonEmpty = modules.where((m) => m.content.trim().isNotEmpty).toList();
    return nonEmpty.isEmpty
        ? [_ModuleDraft(title: fallbackTitle, content: manuscript)]
        : nonEmpty;
  }
}

class _ModuleDraft {
  final String title;
  final String content;

  const _ModuleDraft({required this.title, required this.content});
}
