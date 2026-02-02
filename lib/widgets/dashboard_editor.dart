import 'dart:convert';
import 'dart:js_interop';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;

import '../models/course_model.dart';
import '../models/interactive_block.dart';
import '../models/module_model.dart';
import '../providers/course_provider.dart';
import '../services/ai_service.dart';
import '../services/scorm/scorm_export_service.dart';
import '../services/storage_service.dart';
import '../widgets/wysiwyg_editor.dart';
import 'creation/creation_shared_widgets.dart';
import 'dashboard_sidebar.dart';

part 'dashboard/dashboard_editor_controller.dart';

class DashboardEditor extends StatefulWidget {
  final CourseModel course;
  final DashboardSelectionController selectionController;
  final VoidCallback onCourseUpdated;
  final VoidCallback onAddModule;
  final VoidCallback onToggleRightPanel;
  final bool isRightPanelVisible;
  final ScrollController? scrollController;

  const DashboardEditor({
    super.key,
    required this.course,
    required this.selectionController,
    required this.onCourseUpdated,
    required this.onAddModule,
    required this.onToggleRightPanel,
    required this.isRightPanelVisible,
    this.scrollController,
  });

  @override
  State<DashboardEditor> createState() => _DashboardEditorState();
}

class _DashboardEditorState extends State<DashboardEditor> {
  bool _isGeneratingSection = false;

  String _panelAudience = 'General';
  String _panelTone = 'Profesional';
  String _panelMethodology = 'Expositiva';

  final Map<String, String> _generatedSectionContent = {};
  final Map<String, String> _generatedSectionFormat = {};

  late final ScrollController _mainScrollController;
  late final bool _ownsScrollController;
  late TextEditingController _titleController;
  CourseModel? _localCourseState;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _mainScrollController = widget.scrollController ?? ScrollController();
    _titleController = TextEditingController(text: widget.course.title);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final container = ProviderScope.containerOf(context, listen: false);
      final aiCourse = container.read(courseProvider);
      if (aiCourse != null && aiCourse.modules.isNotEmpty) {
        setState(() {
          _localCourseState = aiCourse;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant DashboardEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course.title != widget.course.title && _titleController.text != widget.course.title) {
      _titleController.text = widget.course.title;
    }
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _mainScrollController.dispose();
    }
    _titleController.dispose();
    super.dispose();
  }

  void _scheduleSetState(VoidCallback fn) {
    Future.microtask(() {
      if (!mounted) return;
      setState(fn);
    });
  }

  void _notifyCourseUpdated() {
    widget.onCourseUpdated();
  }

  Future<void> _confirmGoldenMockLoad() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Iniciar Test de Estrés?'),
        content: const Text('Se borrará el contenido actual del editor.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('INICIAR')),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) return;

    final container = ProviderScope.containerOf(context, listen: false);
    final notifier = container.read(courseProvider.notifier);
    notifier.clearModules();
    notifier.loadGoldenMockCourse();

    final course = container.read(courseProvider);
    if (course != null && course.modules.isNotEmpty) {
      widget.selectionController.selectModule(course.modules.first);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🚀 Golden Course cargado: 22 funcionalidades operativas')),
      );
    }

    Future.microtask(() {
      if (!mounted) return;
      if (_mainScrollController.hasClients) {
        _mainScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_mainScrollController.hasClients) return;
          _mainScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  int _getSelectedSectionIndex(String selectedSection) {
    const sectionOrder = [
      'general',
      'intro',
      'objectives',
      'map',
      'index',
      'modules_root',
      'resources',
      'glossary',
      'faq',
      'eval',
      'stats',
      'bank',
    ];
    if (selectedSection.startsWith('module_')) {
      return 6;
    }
    final index = sectionOrder.indexOf(selectedSection);
    return index == -1 ? 0 : index + 1;
  }

  String _getSelectedSectionName(String selectedSection) {
    switch (selectedSection) {
      case 'general':
        return 'General';
      case 'intro':
        return 'Introducción';
      case 'objectives':
        return 'Objetivos';
      case 'map':
        return 'Mapa Conceptual';
      case 'index':
        return 'Índice del curso';
      case 'modules_root':
        return 'Gestión de Temas';
      case 'resources':
        return 'Recursos';
      case 'glossary':
        return 'Glosario';
      case 'faq':
        return 'Preguntas Frecuentes';
      case 'eval':
        return 'Evaluación Final';
      case 'stats':
        return 'Estadísticas';
      case 'bank':
        return 'Banco de Contenidos';
      default:
        if (selectedSection.startsWith('module_')) {
          return widget.selectionController.getSelectedModule(widget.course)?.title ?? 'Tema';
        }
        return 'Sección';
    }
  }

  String _buildSectionContext(String selectedSection) {
    switch (selectedSection) {
      case 'general':
        return widget.course.general.blocks.map((b) => b.content.toString()).join(' ');
      case 'intro':
        return widget.course.intro.introBlocks.map((b) => b.content.toString()).join(' ');
      case 'objectives':
        return widget.course.intro.objectiveBlocks.map((b) => b.content.toString()).join(' ');
      case 'map':
        return widget.course.conceptMap.blocks.map((b) => b.content.toString()).join(' ');
      case 'index':
      case 'modules_root':
        return widget.course.modules.map((m) => m.title).join(', ');
      case 'resources':
        return widget.course.resources.blocks.map((b) => b.content.toString()).join(' ');
      case 'glossary':
        return widget.course.glossary.blocks.map((b) => b.content.toString()).join(' ');
      case 'faq':
        return widget.course.faq.blocks.map((b) => b.content.toString()).join(' ');
      case 'eval':
        return widget.course.evaluation.blocks.map((b) => b.content.toString()).join(' ');
      case 'stats':
        return 'Nota promedio: ${widget.course.stats.averageScore}. Tiempo promedio: ${widget.course.stats.averageTimeMinutes} min.';
      case 'bank':
        return widget.course.contentBank.externalUrl;
      default:
        if (selectedSection.startsWith('module_')) {
          return widget.selectionController.getSelectedModule(widget.course)?.title ?? widget.course.title;
        }
        return widget.course.title;
    }
  }

  Future<void> generateCurrentSectionContent(String selectedSection) async {
    final sectionIndex = _getSelectedSectionIndex(selectedSection);
    if (sectionIndex == 0) return;

    _scheduleSetState(() => _isGeneratingSection = true);
    try {
      final aiService = AiService();
      final result = await aiService.generateSectionContent(
        sectionIndex: sectionIndex,
        sectionName: _getSelectedSectionName(selectedSection),
        context: _buildSectionContext(selectedSection),
        panelConfig: {
          'audience': _panelAudience,
          'tone': _panelTone,
          'methodology': _panelMethodology,
        },
      );
      if (!mounted) return;
      _scheduleSetState(() {
        _generatedSectionContent[selectedSection] = result.content;
        _generatedSectionFormat[selectedSection] = result.format;
        if (result.content.isNotEmpty) {
          _injectGeneratedContent(selectedSection, result);
          _notifyCourseUpdated();
        }
      });
    } finally {
      if (mounted) {
        _scheduleSetState(() => _isGeneratingSection = false);
      }
    }
  }

  void _injectGeneratedContent(String selectedSection, SectionGenerationResult result) {
    final targets = _resolveTargetBlocks(selectedSection);
    if (targets == null) return;
    _removePlaceholderBlocks(targets);

    if (result.format == 'json' && selectedSection == 'eval') {
      final blocks = _buildEvaluationBlocksFromJson(result.content);
      if (blocks.isNotEmpty) {
        targets.addAll(blocks);
      }
      return;
    }

    final blockType = result.format == 'rich_text' ? BlockType.textRich : BlockType.textPlain;
    targets.add(InteractiveBlock.create(type: blockType, content: {'text': result.content}));
  }

  List<InteractiveBlock>? _resolveTargetBlocks(String selectedSection) {
    switch (selectedSection) {
      case 'general':
        return widget.course.general.blocks;
      case 'intro':
        return widget.course.intro.introBlocks;
      case 'objectives':
        return widget.course.intro.objectiveBlocks;
      case 'map':
        return widget.course.conceptMap.blocks;
      case 'resources':
        return widget.course.resources.blocks;
      case 'glossary':
        return widget.course.glossary.blocks;
      case 'faq':
        return widget.course.faq.blocks;
      case 'eval':
        return widget.course.evaluation.blocks;
      default:
        if (selectedSection.startsWith('module_')) {
          return widget.selectionController.getSelectedModule(widget.course)?.blocks;
        }
        return null;
    }
  }

  void _removePlaceholderBlocks(List<InteractiveBlock> blocks) {
    if (blocks.length != 1) return;
    final block = blocks.first;
    if (block.type != BlockType.textPlain && block.type != BlockType.textRich && block.type != BlockType.essay) {
      return;
    }
    final text = (block.content['text'] ?? '').toString();
    if (text.trim().isEmpty) {
      blocks.clear();
    }
  }

  List<InteractiveBlock> _buildEvaluationBlocksFromJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map<String, dynamic>) return [];
      final blocks = <InteractiveBlock>[];
      final title = (decoded['title'] ?? '').toString().trim();
      final instructions = (decoded['instructions'] ?? '').toString().trim();
      if (title.isNotEmpty) {
        blocks.add(InteractiveBlock.create(type: BlockType.textRich, content: {'text': '<h3>$title</h3>'}));
      }
      if (instructions.isNotEmpty) {
        blocks.add(InteractiveBlock.create(type: BlockType.textPlain, content: {'text': instructions}));
      }
      final questions = decoded['questions'];
      if (questions is List) {
        for (final q in questions) {
          if (q is! Map) continue;
          final map = q.cast<String, dynamic>();
          final question = (map['question'] ?? '').toString().trim();
          final options = (map['options'] is List)
              ? (map['options'] as List).map((e) => e.toString()).toList()
              : <String>[];
          final correctIndex = map['correctIndex'] is int ? map['correctIndex'] as int : 0;
          if (question.isEmpty) continue;
          blocks.add(InteractiveBlock.create(
            type: BlockType.singleChoice,
            content: {
              'question': question,
              'options': options,
              'correctIndex': correctIndex,
            },
          ));
        }
      }
      return blocks;
    } catch (_) {
      if (rawJson.trim().isEmpty) return [];
      return [
        InteractiveBlock.create(type: BlockType.textPlain, content: {'text': rawJson})
      ];
    }
  }

  Future<void> _flushEditorState() async {
    FocusScope.of(context).unfocus();
    final title = _titleController.text.trim();
    if (title.isNotEmpty && widget.course.title != title) {
      widget.course.title = title;
    }
    _notifyCourseUpdated();
  }

  void _exportarJSON() {
    try {
      final String jsonString = jsonEncode(widget.course.toMap());
      final bytes = utf8.encode(jsonString);
      final blob = web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(type: 'application/json'),
      );
      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      final String fileName = "${widget.course.title.replaceAll(' ', '_')}_backup.json";
      anchor.href = url;
      anchor.download = fileName;
      anchor.click();
      web.URL.revokeObjectURL(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Backup '$fileName' descargado"),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Error exportando JSON: $e");
    }
  }

  void _guardarProgreso() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.save_as, color: Colors.indigo),
            SizedBox(width: 10),
            Text("Confirmar Guardado"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("¿Deseas sincronizar los cambios de este curso en tu biblioteca local?"),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.book_outlined, size: 16, color: Colors.indigo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.course.title.isEmpty ? "Sin título" : widget.course.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await StorageService().saveCourse(widget.course.toMap());
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Curso guardado correctamente en 'Mis Cursos'"),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.indigo,
                  width: 400,
                ),
              );
            },
            child: const Text("GUARDAR AHORA", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFileForGeneral(String type) async {
    FileType pickingType = type == 'video' ? FileType.video : FileType.custom;
    List<String>? allowedExt = type == 'video' ? null : ['pdf', 'docx'];

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: pickingType,
      allowedExtensions: allowedExt,
    );
    if (!mounted) return;

    if (result != null) {
      _scheduleSetState(() {
        String fileName = result.files.first.name;
        if (type == 'video') widget.course.general.videoTutorialUrl = fileName;
        if (type == 'manual') widget.course.general.platformManualUrl = fileName;
        if (type == 'guide') widget.course.general.studentGuideUrl = fileName;
      });
      _notifyCourseUpdated();
      StorageService().saveCourse(widget.course.toMap());
    }
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.selectionController,
      builder: (context, _) {
        final selectedSection = widget.selectionController.selectedSection;
        return Column(
          children: [
            _buildTopBar(),
            _buildMainContentArea(selectedSection),
          ],
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 360;
              final titleField = TextFormField(
                controller: _titleController,
                maxLines: 1,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                decoration: const InputDecoration(border: InputBorder.none, hintText: "Título del curso..."),
                onChanged: (v) {
                  widget.course.title = v;
                  _notifyCourseUpdated();
                },
              );
              final actionsRow = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(widget.isRightPanelVisible ? Icons.grid_view_rounded : Icons.grid_view_outlined, color: Colors.grey),
                    onPressed: widget.onToggleRightPanel,
                    tooltip: "Mostrar/Ocultar Panel Alumno",
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_for_offline_outlined, color: Colors.teal),
                    tooltip: "Descargar Copia JSON (Backup)",
                    onPressed: _exportarJSON,
                  ),
                  const VerticalDivider(width: 30, indent: 15, endIndent: 15),
                  TextButton.icon(
                    onPressed: _guardarProgreso,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text("GUARDAR"),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                    child: ElevatedButton.icon(
                      onPressed: _exportScorm,
                      icon: const Icon(Icons.archive_outlined, size: 16),
                      label: const Text("EXPORTAR SCORM"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade900, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.dashboard_customize, color: Colors.indigo),
                        onPressed: () => context.go('/'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bug_report, color: Colors.deepOrange),
                        tooltip: 'Stress Test Golden Course',
                        visualDensity: VisualDensity.compact,
                        onPressed: _confirmGoldenMockLoad,
                      ),
                      SizedBox(width: 200, child: titleField),
                      actionsRow,
                    ],
                  ),
                );
              }

              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.dashboard_customize, color: Colors.indigo),
                    onPressed: () => context.go('/'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bug_report, color: Colors.deepOrange),
                    tooltip: 'Stress Test Golden Course',
                    visualDensity: VisualDensity.compact,
                    onPressed: _confirmGoldenMockLoad,
                  ),
                  Expanded(child: titleField),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: actionsRow,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static const double _toolbarReservedHeight = 340;
  static const double _toolbarTopSpacing = 18;

  Widget _buildMainContentArea(String selectedSection) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getSectionTitle(selectedSection).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo, letterSpacing: 1.1),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (selectedSection != 'index' && selectedSection != 'stats')
                          ElevatedButton.icon(
                            onPressed: _isGeneratingSection ? null : () => generateCurrentSectionContent(selectedSection),
                            icon: _isGeneratingSection
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.auto_awesome, size: 16),
                            label: const Text("GENERAR IA"),
                          ),
                        const SizedBox(width: 12),
                        if (selectedSection == 'modules_root')
                          ElevatedButton.icon(
                            onPressed: widget.onAddModule,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("NUEVO TEMA"),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    padding: const EdgeInsets.all(35),
                    child: Padding(
                      padding: const EdgeInsets.only(top: _toolbarReservedHeight + _toolbarTopSpacing),
                      child: _buildSectionEditor(selectedSection),
                    ),
                  ),
                ),
                Positioned(
                  top: _toolbarTopSpacing,
                  left: 35,
                  right: 35,
                  child: _BlockToolbar(
                    sectionId: selectedSection,
                    onBlockSelected: (type, initialContent) => _addBlockToSection(
                      selectedSection,
                      type,
                      initialContent: initialContent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionEditor(String selectedSection) {
    switch (selectedSection) {
      case 'general':
        return _buildGeneralSection();
      case 'intro':
        return _buildIntroSection();
      case 'objectives':
        return _buildObjectivesSection();
      case 'map':
        return _buildMapSection();
      case 'index':
        return _buildIndexSection();
      case 'modules_root':
        return _buildModulesRootSection();
      case 'resources':
        return _buildResourcesSection();
      case 'glossary':
        return _buildGlossarySection();
      case 'faq':
        return _buildFaqSection();
      case 'eval':
        return _buildEvaluationSection();
      case 'stats':
        return _buildStatsSection();
      case 'bank':
        return _buildContentBankSection();
      default:
        if (selectedSection.startsWith('module_')) {
          return _buildModuleSection();
        }
        return _buildModulesManagerRoot();
    }
  }

  Widget _buildInitialPanelConfigCard() {
    return _buildSimpleCard(
      title: "Panel Inicial · Configuración IA",
      child: Column(
        children: [
          TextFormField(
            initialValue: _panelAudience,
            decoration: const InputDecoration(
              labelText: "Público",
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _panelAudience = value,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _panelTone,
            decoration: const InputDecoration(
              labelText: "Tono",
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _panelTone = value,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _panelMethodology,
            decoration: const InputDecoration(
              labelText: "Metodología",
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _panelMethodology = value,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedContentCard(String sectionId, String title) {
    final content = _generatedSectionContent[sectionId] ?? '';
    if (content.isEmpty) {
      return _buildSimpleCard(
        title: title,
        child: const Text(
          "Aún no hay contenido generado para esta sección.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    final format = _generatedSectionFormat[sectionId] ?? 'text';
    final isJson = format == 'json';
    return _buildSimpleCard(
      title: title,
      child: SelectableText(
        content,
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: Colors.grey.shade800,
          fontFamily: isJson ? 'monospace' : null,
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildSimpleCard(
            title: "Introducción del curso",
            child: WysiwygEditor(
              initialValue: widget.course.introText,
              label: "Introducción",
              onChanged: (value) {
                widget.course.introText = value;
                _notifyCourseUpdated();
              },
            ),
          ),
          _buildUniversalBlockList(widget.course.intro.introBlocks, sectionId: 'intro'),
          _buildGeneratedContentCard('intro', "Salida IA · Introducción"),
        ],
      ),
    );
  }

  Widget _buildObjectivesSection() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildSimpleCard(
            title: "Objetivos de aprendizaje",
            child: Column(
              children: [
                for (int i = 0; i < widget.course.objectives.length; i++)
                  _buildObjectiveRow(i),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      _scheduleSetState(() => widget.course.objectives.add(''));
                      _notifyCourseUpdated();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar objetivo"),
                  ),
                ),
              ],
            ),
          ),
          _buildUniversalBlockList(widget.course.intro.objectiveBlocks, sectionId: 'objectives'),
          _buildGeneratedContentCard('objectives', "Salida IA · Objetivos"),
        ],
      ),
    );
  }

  Widget _buildIndexSection() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildSimpleCard(
            title: "Índice del curso",
            child: Column(
              children: [
                for (int i = 0; i < widget.course.modules.length; i++)
                  ListTile(
                    key: ValueKey('module_index_${widget.course.modules[i].id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                      child: Text(
                        "${i + 1}",
                        style: const TextStyle(fontSize: 11, color: Colors.indigo),
                      ),
                    ),
                    title: Text(
                      widget.course.modules[i].title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    trailing: TextButton(
                      onPressed: () => widget.selectionController.selectModule(widget.course.modules[i]),
                      child: const Text("ABRIR"),
                    ),
                  ),
                if (widget.course.modules.isEmpty)
                  const Text(
                    "Aún no hay temas creados. Añade tu primer módulo desde el panel.",
                    style: TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
          _buildSimpleCard(
            title: "Acciones rápidas",
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: widget.onAddModule,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Nuevo tema"),
                  ),
                ],
              ),
            ),
          ),
          _buildGeneratedContentCard('index', "Salida IA · Índice del curso"),
        ],
      ),
    );
  }

  Widget _buildGeneralSection() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildInitialPanelConfigCard(),
          _buildGeneralHeader(),
          const SizedBox(height: 10),
          _buildUniversalBlockList(widget.course.general.blocks, sectionId: 'general'),
          _buildGeneratedContentCard('general', "Salida IA · General"),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildSimpleCard(
            title: "Mapa conceptual del curso",
            child: const Text("Organiza el mapa conceptual y sus bloques visuales."),
          ),
          const SizedBox(height: 10),
          _buildUniversalBlockList(widget.course.conceptMap.blocks, sectionId: 'map'),
          _buildGeneratedContentCard('map', "Salida IA · Mapa Conceptual"),
        ],
      ),
    );
  }

  Widget _buildModulesRootSection() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildSimpleCard(
            title: "Gestión del temario",
            child: _buildModulesManagerRoot(),
          ),
          Consumer(
            builder: (context, ref, _) {
              final course = ref.watch(courseProvider);
              final modules = course?.modules ?? const <ModuleModel>[];
              if (modules.isEmpty) {
                return _buildSimpleCard(
                  title: "Temas existentes",
                  child: const Text(
                    "Aún no hay temas creados. Añade tu primer módulo desde el panel.",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return _buildSimpleCard(
                title: "Temas existentes",
                child: Column(
                  children: [
                    ...course!.modules.asMap().entries.map((entry) {
                      final index = entry.key;
                      final module = entry.value;
                      return ListTile(
                        key: ValueKey('modules_root_${module.id}'),
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(fontSize: 11, color: Colors.indigo),
                          ),
                        ),
                        title: Text(
                          module.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        trailing: TextButton(
                          onPressed: () => widget.selectionController.selectModule(module),
                          child: const Text("ABRIR"),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          _buildGeneratedContentCard('modules_root', "Salida IA · Temario"),
        ],
      ),
    );
  }

  Widget _buildModuleSection() {
    final module = widget.selectionController.getSelectedModule(widget.course);
    if (module == null) {
      return _buildModulesManagerRoot();
    }
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildSimpleCard(
            title: "Tema seleccionado",
            child: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          _buildUniversalBlockList(
            module.blocks,
            sectionId: widget.selectionController.sectionIdForModule(module),
          ),
          _buildGeneratedContentCard(widget.selectionController.sectionIdForModule(module), "Salida IA · ${module.title}"),
        ],
      ),
    );
  }

  Widget _buildResourcesSection() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildSimpleCard(
            title: "Recursos didácticos",
            child: const Text("Gestiona recursos adicionales y materiales complementarios."),
          ),
          const SizedBox(height: 10),
          _buildUniversalBlockList(widget.course.resources.blocks, sectionId: 'resources'),
          _buildGeneratedContentCard('resources', "Salida IA · Recursos"),
        ],
      ),
    );
  }

  Widget _buildEvaluationSection() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildSimpleCard(
            title: "Evaluación final",
            child: const Text("Configura la evaluación final y sus bloques."),
          ),
          const SizedBox(height: 10),
          _buildUniversalBlockList(widget.course.evaluation.blocks, sectionId: 'eval'),
          _buildGeneratedContentCard('eval', "Salida IA · Evaluación Final (JSON)"),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildStatsHeader(),
        ],
      ),
    );
  }

  Widget _buildContentBankSection() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildContentBankHeader(),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return _buildSimpleCard(
      title: "Indicadores del curso",
      child: Column(
        children: [
          _statRow("Nota promedio (%)", widget.course.stats.averageScore.toStringAsFixed(1)),
          const SizedBox(height: 12),
          _statRow("Tiempo promedio (min)", widget.course.stats.averageTimeMinutes.toString()),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildContentBankHeader() {
    final files = widget.course.contentBank.files;
    return _buildSimpleCard(
      title: "Banco de Contenidos Multimodal",
      child: Column(
        children: [
          if (files.isEmpty)
            const Text(
              "No hay archivos registrados en este curso.",
              style: TextStyle(color: Colors.grey),
            ),
          for (final file in files)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _iconForContentBankType(file['type'] ?? ''),
                color: Colors.indigo,
              ),
              title: Text(file['name'] ?? 'Archivo'),
              subtitle: Text((file['type'] ?? 'desconocido').toUpperCase()),
            ),
        ],
      ),
    );
  }

  Widget _buildObjectiveRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              key: ValueKey('objective_${widget.course.objectives[index].hashCode}'),
              initialValue: widget.course.objectives[index],
              decoration: const InputDecoration(
                labelText: "Objetivo",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                widget.course.objectives[index] = value;
                _notifyCourseUpdated();
              },
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade300,
            onPressed: () {
              _scheduleSetState(() => widget.course.objectives.removeAt(index));
              _notifyCourseUpdated();
            },
            tooltip: "Eliminar",
          ),
        ],
      ),
    );
  }

  Widget _buildGlossarySection() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildSimpleCard(
            title: "Glosario",
            child: Column(
              children: [
                for (int i = 0; i < widget.course.glossaryItems.length; i++)
                  _buildGlossaryRow(i),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      _scheduleSetState(() => widget.course.glossaryItems.add(
                        GlossaryItem(term: '', definition: ''),
                      ));
                      _notifyCourseUpdated();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar término"),
                  ),
                ),
              ],
            ),
          ),
          _buildUniversalBlockList(widget.course.glossary.blocks, sectionId: 'glossary'),
          _buildGeneratedContentCard('glossary', "Salida IA · Glosario"),
        ],
      ),
    );
  }

  Widget _buildGlossaryRow(int index) {
    final item = widget.course.glossaryItems[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('glossary_term_${item.hashCode}'),
                  initialValue: item.term,
                  decoration: const InputDecoration(
                    labelText: "Término",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    item.term = value;
                    _notifyCourseUpdated();
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade300,
                onPressed: () {
                  _scheduleSetState(() => widget.course.glossaryItems.removeAt(index));
                  _notifyCourseUpdated();
                },
                tooltip: "Eliminar",
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('glossary_def_${item.hashCode}'),
            initialValue: item.definition,
            decoration: const InputDecoration(
              labelText: "Definición",
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) {
              item.definition = value;
              _notifyCourseUpdated();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return SingleChildScrollView(
      controller: _mainScrollController,
      child: Column(
        children: [
          _buildSimpleCard(
            title: "Preguntas frecuentes",
            child: Column(
              children: [
                for (int i = 0; i < widget.course.faqItems.length; i++)
                  _buildFaqRow(i),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      _scheduleSetState(() => widget.course.faqItems.add(
                        FaqItem(question: '', answer: ''),
                      ));
                      _notifyCourseUpdated();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Agregar pregunta"),
                  ),
                ),
              ],
            ),
          ),
          _buildUniversalBlockList(widget.course.faq.blocks, sectionId: 'faq'),
          _buildGeneratedContentCard('faq', "Salida IA · Preguntas Frecuentes"),
        ],
      ),
    );
  }

  Widget _buildFaqRow(int index) {
    final item = widget.course.faqItems[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('faq_question_${item.hashCode}'),
                  initialValue: item.question,
                  decoration: const InputDecoration(
                    labelText: "Pregunta",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    item.question = value;
                    _notifyCourseUpdated();
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade300,
                onPressed: () {
                  _scheduleSetState(() => widget.course.faqItems.removeAt(index));
                  _notifyCourseUpdated();
                },
                tooltip: "Eliminar",
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('faq_answer_${item.hashCode}'),
            initialValue: item.answer,
            decoration: const InputDecoration(
              labelText: "Respuesta",
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) {
              item.answer = value;
              _notifyCourseUpdated();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildGeneralHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CONFIGURACIÓN DE RECURSOS OPERATIVOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
          const SizedBox(height: 25),
          _fileRow("Video Tutorial del Curso", widget.course.general.videoTutorialUrl, Icons.play_circle_fill, () => _pickFileForGeneral('video')),
          const Divider(height: 30),
          _fileRow("Manual de la Plataforma", widget.course.general.platformManualUrl, Icons.picture_as_pdf, () => _pickFileForGeneral('manual')),
          const Divider(height: 30),
          _fileRow("Guía Didáctica Alumno", widget.course.general.studentGuideUrl, Icons.description, () => _pickFileForGeneral('guide')),
        ],
      ),
    );
  }

  Widget _fileRow(String label, String value, IconData icon, VoidCallback onPick) {
    bool hasFile = value.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        final infoColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(
              hasFile ? value : "Pendiente de cargar...",
              style: TextStyle(color: hasFile ? Colors.black54 : Colors.red.shade300, fontSize: 11),
            ),
          ],
        );
        final actionButton = ElevatedButton(
          onPressed: onPick,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, elevation: 0, foregroundColor: Colors.indigo),
          child: Text(hasFile ? "CAMBIAR" : "CARGAR"),
        );
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: hasFile ? Colors.green : Colors.grey, size: 24),
                  const SizedBox(width: 16),
                  Expanded(child: infoColumn),
                ],
              ),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: actionButton),
            ],
          );
        }
        return Row(
          children: [
            Icon(icon, color: hasFile ? Colors.green : Colors.grey, size: 24),
            const SizedBox(width: 20),
            Expanded(child: infoColumn),
            actionButton,
          ],
        );
      },
    );
  }


  String _getSectionTitle(String selectedSection) {
    switch (selectedSection) {
      case 'general':
        return "Configuración · General";
      case 'intro':
        return "Configuración · Introducción";
      case 'objectives':
        return "Configuración · Objetivos";
      case 'map':
        return "Configuración · Mapa Conceptual";
      case 'index':
        return "Temario · Índice del curso";
      case 'modules_root':
        return "Temario · Gestión de Temas";
      case 'resources':
        return "Recursos y Cierre · Recursos";
      case 'glossary':
        return "Recursos y Cierre · Glosario";
      case 'faq':
        return "Recursos y Cierre · Preguntas Frecuentes";
      case 'eval':
        return "Recursos y Cierre · Evaluación Final";
      case 'stats':
        return "Recursos y Cierre · Estadísticas";
      case 'bank':
        return "Banco de Contenidos · Multimodal";
      default:
        return "Editor de Contenidos";
    }
  }

  Widget _buildModulesManagerRoot() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_books_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 25),
          const Text("GESTIÓN INTEGRAL DEL TEMARIO", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Crea, ordena y gestiona los temas principales de tu curso SCORM.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: widget.onAddModule,
            icon: const Icon(Icons.add),
            label: const Text("AÑADIR TEMA PRINCIPAL"),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
          ),
        ],
      ),
    );
  }

  IconData _iconForContentBankType(String type) {
    switch (type) {
      case 'audio':
        return Icons.audiotrack;
      case 'video':
        return Icons.videocam;
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}
