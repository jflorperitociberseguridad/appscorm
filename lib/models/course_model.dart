import 'module_model.dart';
import 'interactive_block.dart';

// =============================================================================
// CLASE PRINCIPAL DEL CURSO (Estructura Totalmente Modular - 11 PUNTOS)
// =============================================================================
class CourseModel {
  final String id;
  final String userId;
  String title;
  String description;
  final DateTime createdAt;
  final String scormVersion;
  CourseConfig config;
  String introText;
  List<String> objectives;
  List<GlossaryItem> glossaryItems;
  List<FaqItem> faqItems;
  
  // --- SECCIONES ESTRUCTURALES (11 PUNTOS) ---
  GeneralSection general;         // 1.1
  IntroSection intro;             // 1.2 y 1.3
  MapSection conceptMap;          // 1.4 (Añadido para completar estructura)
  final List<ModuleModel> modules; // 2. Módulos y Temario
  ResourcesSection resources;     // 6.
  GlossarySection glossary;       // 7.
  FaqSection faq;                 // 8.
  EvaluationSection evaluation;   // 9.
  StatsSection stats;             // 10.
  ContentBankSection contentBank; // 11.

  CourseModel({
    required this.id,
    this.userId = 'local_user',
    required this.title,
    required this.description,
    required this.createdAt,
    this.scormVersion = '1.2',
    CourseConfig? config,
    required this.modules,
    this.introText = '',
    List<String>? objectives,
    List<GlossaryItem>? glossaryItems,
    List<FaqItem>? faqItems,
    GeneralSection? general,
    IntroSection? intro,
    MapSection? conceptMap,
    ResourcesSection? resources,
    GlossarySection? glossary,
    FaqSection? faq,
    EvaluationSection? evaluation,
    StatsSection? stats,
    ContentBankSection? contentBank,
  }) : 
    objectives = objectives ?? <String>[],
    glossaryItems = glossaryItems ?? <GlossaryItem>[],
    faqItems = faqItems ?? <FaqItem>[],
    general = general ?? GeneralSection(),
    intro = intro ?? IntroSection(),
    conceptMap = conceptMap ?? MapSection(),
    resources = resources ?? ResourcesSection(),
    glossary = glossary ?? GlossarySection(),
    faq = faq ?? FaqSection(),
    evaluation = evaluation ?? EvaluationSection(),
    stats = stats ?? StatsSection(),
    contentBank = contentBank ?? ContentBankSection(),
    config = config ?? CourseConfig();

  Map<String, dynamic> toJson() => toMap();
  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'scorm_version': scormVersion,
      'intro': introText,
      'objectives': objectives,
      'glossary': glossaryItems.map((item) => item.toMap()).toList(),
      'faqs': faqItems.map((item) => item.toMap()).toList(),
      'modules': modules.map((x) => x.toMap()).toList(),
      'general': general.toMap(),
      'intro_section': intro.toMap(),
      'conceptMap': conceptMap.toMap(),
      'resources': resources.toMap(),
      'glossary_section': glossary.toMap(),
      'faq': faq.toMap(),
      'evaluation': evaluation.toMap(),
      'stats': stats.toMap(),
      'content_bank': contentBank.toMap(),
      'config': config.toMap(),
    };
  }

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    final dynamic introValue = map['intro'];
    final dynamic glossaryValue = map['glossary'];
    final dynamic objectivesValue = map['objectives'];
    final dynamic faqsValue = map['faqs'];

    return CourseModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? 'local_user',
      title: map['title'] ?? 'Sin Título',
      description: map['description'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      scormVersion: map['scorm_version'] ?? '1.2',
      introText: introValue is String ? introValue : '',
      objectives: objectivesValue is List
          ? objectivesValue.map((item) => item.toString()).toList()
          : const [],
      glossaryItems: glossaryValue is List
          ? glossaryValue.map((item) {
              if (item is Map) {
                return GlossaryItem.fromMap(Map<String, dynamic>.from(item));
              }
              return GlossaryItem(term: item.toString(), definition: '');
            }).toList()
          : <GlossaryItem>[],
      faqItems: faqsValue is List
          ? faqsValue.map((item) {
              if (item is Map) {
                return FaqItem.fromMap(Map<String, dynamic>.from(item));
              }
              return FaqItem(question: item.toString(), answer: '');
            }).toList()
          : <FaqItem>[],
      modules: List<ModuleModel>.from((map['modules'] as List? ?? []).map((x) => ModuleModel.fromMap(x))),
      general: GeneralSection.fromMap(map['general'] ?? {}),
      intro: IntroSection.fromMap(
          map['intro_section'] ?? (introValue is Map ? introValue : {})),
      conceptMap: MapSection.fromMap(map['conceptMap'] ?? {}),
      resources: ResourcesSection.fromMap(map['resources'] ?? {}),
      glossary: GlossarySection.fromMap(
          map['glossary_section'] ?? (glossaryValue is Map ? glossaryValue : {})),
      faq: FaqSection.fromMap(map['faq'] ?? {}),
      evaluation: EvaluationSection.fromMap(map['evaluation'] ?? {}),
      stats: StatsSection.fromMap(map['stats'] ?? {}),
      contentBank: ContentBankSection.fromMap(map['content_bank'] ?? {}),
      config: CourseConfig.fromMap(map['config'] ?? {}),
    );
  }
}

// =============================================================================
// SUB-CLASES (Campos Originales Editables + Bloques Modulares)
// =============================================================================

class CourseConfig {
  String targetLms;
  List<String> compatibilityPatches;
  bool passwordProtectionEnabled;
  String password;
  bool domainRestrictionEnabled;
  String allowedDomain;
  String expirationDate;
  bool offlineModeEnabled;
  String wcagLevel;
  bool gdprCompliance;
  bool anonymizeLearnerData;
  bool xApiEnabled;
  String lrsUrl;
  String lrsKey;
  String lrsSecret;
  int xApiDataDensity;
  String supportEmail;
  String supportPhone;
  String documentationUrl;
  String versionTag;
  String changeLog;
  String ecosystemNotes;

  CourseConfig({
    this.targetLms = 'Genérico',
    List<String>? compatibilityPatches,
    this.passwordProtectionEnabled = false,
    this.password = '',
    this.domainRestrictionEnabled = false,
    this.allowedDomain = '',
    this.expirationDate = '',
    this.offlineModeEnabled = false,
    this.wcagLevel = 'Sin requisitos',
    this.gdprCompliance = false,
    this.anonymizeLearnerData = false,
    this.xApiEnabled = false,
    this.lrsUrl = '',
    this.lrsKey = '',
    this.lrsSecret = '',
    this.xApiDataDensity = 0,
    this.supportEmail = '',
    this.supportPhone = '',
    this.documentationUrl = '',
    this.versionTag = '',
    this.changeLog = '',
    this.ecosystemNotes = '',
  }) : compatibilityPatches = compatibilityPatches ?? <String>[];

  Map<String, dynamic> toMap() => {
    'target_lms': targetLms,
    'compatibility_patches': compatibilityPatches,
    'password_protection_enabled': passwordProtectionEnabled,
    'password': password,
    'domain_restriction_enabled': domainRestrictionEnabled,
    'allowed_domain': allowedDomain,
    'expiration_date': expirationDate,
    'offline_mode_enabled': offlineModeEnabled,
    'wcag_level': wcagLevel,
    'gdpr_compliance': gdprCompliance,
    'anonymize_learner_data': anonymizeLearnerData,
    'xapi_enabled': xApiEnabled,
    'lrs_url': lrsUrl,
    'lrs_key': lrsKey,
    'lrs_secret': lrsSecret,
    'xapi_data_density': xApiDataDensity,
    'support_email': supportEmail,
    'support_phone': supportPhone,
    'documentation_url': documentationUrl,
    'version_tag': versionTag,
    'change_log': changeLog,
    'ecosystem_notes': ecosystemNotes,
  };

  factory CourseConfig.fromMap(Map<String, dynamic> map) => CourseConfig(
    targetLms: map['target_lms'] ?? 'Genérico',
    compatibilityPatches: (map['compatibility_patches'] as List? ?? [])
        .map((item) => item.toString())
        .toList(),
    passwordProtectionEnabled: map['password_protection_enabled'] ?? false,
    password: map['password'] ?? '',
    domainRestrictionEnabled: map['domain_restriction_enabled'] ?? false,
    allowedDomain: map['allowed_domain'] ?? '',
    expirationDate: map['expiration_date'] ?? '',
    offlineModeEnabled: map['offline_mode_enabled'] ?? false,
    wcagLevel: map['wcag_level'] ?? 'Sin requisitos',
    gdprCompliance: map['gdpr_compliance'] ?? false,
    anonymizeLearnerData: map['anonymize_learner_data'] ?? false,
    xApiEnabled: map['xapi_enabled'] ?? false,
    lrsUrl: map['lrs_url'] ?? '',
    lrsKey: map['lrs_key'] ?? '',
    lrsSecret: map['lrs_secret'] ?? '',
    xApiDataDensity: (map['xapi_data_density'] ?? 0).toInt(),
    supportEmail: map['support_email'] ?? '',
    supportPhone: map['support_phone'] ?? '',
    documentationUrl: map['documentation_url'] ?? '',
    versionTag: map['version_tag'] ?? '',
    changeLog: map['change_log'] ?? '',
    ecosystemNotes: map['ecosystem_notes'] ?? '',
  );
}

class GlossaryItem {
  String term;
  String definition;

  GlossaryItem({required this.term, required this.definition});

  Map<String, dynamic> toMap() => {
    'term': term,
    'definition': definition,
  };

  factory GlossaryItem.fromMap(Map<String, dynamic> map) => GlossaryItem(
    term: map['term'] ?? '',
    definition: map['definition'] ?? '',
  );
}

class FaqItem {
  String question;
  String answer;

  FaqItem({required this.question, required this.answer});

  Map<String, dynamic> toMap() => {
    'question': question,
    'answer': answer,
  };

  factory FaqItem.fromMap(Map<String, dynamic> map) => FaqItem(
    question: map['question'] ?? '',
    answer: map['answer'] ?? '',
  );
}

class GeneralSection {
  String videoTutorialUrl; // Quitamos final para permitir edición real
  String platformManualUrl;
  String studentGuideUrl;
  final List<InteractiveBlock> blocks;

  GeneralSection({
    this.videoTutorialUrl = '', 
    this.platformManualUrl = '', 
    this.studentGuideUrl = '',
    List<InteractiveBlock>? blocks,
  }) : blocks = blocks ?? [InteractiveBlock.create(type: BlockType.textPlain, content: {'text': ''})];

  Map<String, dynamic> toMap() => {
    'video_tutorial': videoTutorialUrl, 
    'platform_manual': platformManualUrl, 
    'student_guide': studentGuideUrl,
    'blocks': blocks.map((x) => x.toMap()).toList(),
  };

  factory GeneralSection.fromMap(Map<String, dynamic> map) => GeneralSection(
    videoTutorialUrl: map['video_tutorial'] ?? '',
    platformManualUrl: map['platform_manual'] ?? '',
    studentGuideUrl: map['student_guide'] ?? '',
    blocks: (map['blocks'] as List?)?.map((x) => InteractiveBlock.fromMap(x)).toList(),
  );
}

class IntroSection {
  final List<InteractiveBlock> introBlocks;     // 1.2
  final List<InteractiveBlock> objectiveBlocks; // 1.3
  String presentationVideoUrl;
  String conceptMapUrl; 

  IntroSection({
    List<InteractiveBlock>? introBlocks,
    List<InteractiveBlock>? objectiveBlocks,
    this.presentationVideoUrl = '', 
    this.conceptMapUrl = ''
  }) : 
    introBlocks = introBlocks ?? [InteractiveBlock.create(type: BlockType.textPlain, content: {'text': ''})],
    objectiveBlocks = objectiveBlocks ?? [InteractiveBlock.create(type: BlockType.textPlain, content: {'text': ''})];

  Map<String, dynamic> toMap() => {
    'intro_blocks': introBlocks.map((x) => x.toMap()).toList(),
    'objective_blocks': objectiveBlocks.map((x) => x.toMap()).toList(),
    'presentation_video': presentationVideoUrl,
    'concept_map': conceptMapUrl,
  };

  factory IntroSection.fromMap(Map<String, dynamic> map) => IntroSection(
    introBlocks: (map['intro_blocks'] as List?)?.map((x) => InteractiveBlock.fromMap(x)).toList(),
    objectiveBlocks: (map['objective_blocks'] as List?)?.map((x) => InteractiveBlock.fromMap(x)).toList(),
    presentationVideoUrl: map['presentation_video'] ?? '',
    conceptMapUrl: map['concept_map'] ?? '',
  );
}

// 1.4 Mapa Conceptual (Nueva Clase para operatividad total)
class MapSection {
  final List<InteractiveBlock> blocks;
  MapSection({List<InteractiveBlock>? blocks}) 
    : blocks = blocks ?? [InteractiveBlock.create(type: BlockType.textPlain, content: {'text': ''})];
  Map<String, dynamic> toMap() => {'blocks': blocks.map((x) => x.toMap()).toList()};
  factory MapSection.fromMap(Map<String, dynamic> map) => MapSection(
    blocks: (map['blocks'] as List?)?.map((x) => InteractiveBlock.fromMap(x)).toList(),
  );
}

class ResourcesSection {
  String bibliography;
  final List<InteractiveBlock> blocks;

  ResourcesSection({this.bibliography = '', List<InteractiveBlock>? blocks}) 
    : blocks = blocks ?? [InteractiveBlock.create(type: BlockType.textPlain, content: {'text': ''})];

  Map<String, dynamic> toMap() => {
    'bibliography': bibliography,
    'blocks': blocks.map((x) => x.toMap()).toList(),
  };

  factory ResourcesSection.fromMap(Map<String, dynamic> map) => ResourcesSection(
    bibliography: map['bibliography'] ?? '',
    blocks: (map['blocks'] as List?)?.map((x) => InteractiveBlock.fromMap(x)).toList(),
  );
}

class GlossarySection {
  final List<InteractiveBlock> blocks;
  GlossarySection({List<InteractiveBlock>? blocks}) 
    : blocks = blocks ?? [InteractiveBlock.create(type: BlockType.textPlain, content: {'text': ''})];

  Map<String, dynamic> toMap() => {'blocks': blocks.map((x) => x.toMap()).toList()};
  factory GlossarySection.fromMap(Map<String, dynamic> map) => GlossarySection(
    blocks: (map['blocks'] as List?)?.map((x) => InteractiveBlock.fromMap(x)).toList(),
  );
}

class FaqSection {
  final List<InteractiveBlock> blocks;
  FaqSection({List<InteractiveBlock>? blocks}) 
    : blocks = blocks ?? [InteractiveBlock.create(type: BlockType.textPlain, content: {'text': ''})];

  Map<String, dynamic> toMap() => {'blocks': blocks.map((x) => x.toMap()).toList()};
  factory FaqSection.fromMap(Map<String, dynamic> map) => FaqSection(
    blocks: (map['blocks'] as List?)?.map((x) => InteractiveBlock.fromMap(x)).toList(),
  );
}

class EvaluationSection {
  String finalExamId;
  String participationCriteria;
  final List<InteractiveBlock> blocks;

  EvaluationSection({this.finalExamId = '', this.participationCriteria = '', List<InteractiveBlock>? blocks}) 
    : blocks = blocks ?? [InteractiveBlock.create(type: BlockType.textPlain, content: {'text': ''})];

  Map<String, dynamic> toMap() => {
    'final_exam_id': finalExamId,
    'participation_criteria': participationCriteria,
    'blocks': blocks.map((x) => x.toMap()).toList(),
  };

  factory EvaluationSection.fromMap(Map<String, dynamic> map) => EvaluationSection(
    finalExamId: map['final_exam_id'] ?? '',
    participationCriteria: map['participation_criteria'] ?? '',
    blocks: (map['blocks'] as List?)?.map((x) => InteractiveBlock.fromMap(x)).toList(),
  );
}

class StatsSection {
  String completionStatus;
  double averageScore;
  int averageTimeMinutes;
  final List<InteractiveBlock> blocks;

  StatsSection({
    this.completionStatus = 'N/A',
    this.averageScore = 0.0,
    this.averageTimeMinutes = 0,
    List<InteractiveBlock>? blocks,
  }) 
    : blocks = blocks ?? [InteractiveBlock.create(type: BlockType.textPlain, content: {'text': ''})];

  Map<String, dynamic> toMap() => {
    'status': completionStatus,
    'avg_score': averageScore,
    'avg_time_minutes': averageTimeMinutes,
    'blocks': blocks.map((x) => x.toMap()).toList(),
  };

  factory StatsSection.fromMap(Map<String, dynamic> map) => StatsSection(
    completionStatus: map['status'] ?? 'N/A',
    averageScore: (map['avg_score'] ?? 0.0).toDouble(),
    averageTimeMinutes: (map['avg_time_minutes'] ?? 0).toInt(),
    blocks: (map['blocks'] as List?)?.map((x) => InteractiveBlock.fromMap(x)).toList(),
  );
}

class ContentBankSection {
  List<Map<String, String>> files;
  String externalUrl;
  final List<InteractiveBlock> blocks;

  ContentBankSection({this.files = const [], this.externalUrl = '', List<InteractiveBlock>? blocks}) 
    : blocks = blocks ?? [InteractiveBlock.create(type: BlockType.textPlain, content: {'text': ''})];

  Map<String, dynamic> toMap() => {
    'files': files,
    'external_url': externalUrl,
    'blocks': blocks.map((x) => x.toMap()).toList(),
  };

  factory ContentBankSection.fromMap(Map<String, dynamic> map) => ContentBankSection(
    files: List<Map<String, String>>.from((map['files'] as List? ?? []).map((item) => Map<String, String>.from(item))),
    externalUrl: map['external_url'] ?? '',
    blocks: (map['blocks'] as List?)?.map((x) => InteractiveBlock.fromMap(x)).toList(),
  );
}
