import 'dart:convert';
import 'dart:js_interop';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;

import '../models/course_model.dart';
import '../models/interactive_block.dart';
import '../providers/course_provider.dart';
import '../services/ai_service.dart';
import '../services/scorm/scorm_export_service.dart';
import '../services/storage_service.dart';
import '../widgets/interactive_block_renderer.dart';
import '../widgets/wysiwyg_editor.dart';
import 'dashboard_sidebar.dart';

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

  static const Set<String> _exportSectionIds = {
    'general',
    'intro',
    'objectives',
    'map',
    'resources',
    'glossary',
    'faq',
    'eval',
    'stats',
  };

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _mainScrollController = widget.scrollController ?? ScrollController();
    _titleController = TextEditingController(text: widget.course.title);
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
      case 'intro':
        return widget.course.introText;
      case 'objectives':
        return widget.course.objectives.join(', ');
      case 'map':
        return widget.course.conceptMap.blocks.map((b) => b.content.toString()).join(' ');
      case 'index':
      case 'modules_root':
        return widget.course.modules.map((m) => m.title).join(', ');
      case 'resources':
        return widget.course.resources.blocks.map((b) => b.content.toString()).join(' ');
      case 'glossary':
        return widget.course.glossaryItems.map((g) => g.term).join(', ');
      case 'faq':
        return widget.course.faqItems.map((f) => f.question).join(' ');
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
      _scheduleSetState(() {
        _generatedSectionContent[selectedSection] = result.content;
        _generatedSectionFormat[selectedSection] = result.format;
        if (selectedSection == 'intro' && result.format == 'rich_text' && result.content.isNotEmpty) {
          widget.course.introText = result.content;
          _notifyCourseUpdated();
        }
      });
    } finally {
      if (mounted) {
        _scheduleSetState(() => _isGeneratingSection = false);
      }
    }
  }

  void _openBlockSelector(List<InteractiveBlock> targetList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBlockPickerSheet(targetList),
    );
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
                color: Colors.indigo.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.withOpacity(0.1)),
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
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Curso guardado correctamente en 'Mis Cursos'"),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.indigo,
                    width: 400,
                  ),
                );
              }
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

  CourseModel _buildExportCourse() {
    final exportCourse = CourseModel.fromMap(widget.course.toMap());
    final selectedModuleIds = widget.course.modules
        .where((module) => widget.selectionController.isModuleSelected(module))
        .map((module) => module.id)
        .toSet();
    exportCourse.modules.removeWhere((module) => !selectedModuleIds.contains(module.id));
    return exportCourse;
  }

  Set<String> _enabledStaticSectionIds() {
    return _exportSectionIds.where(widget.selectionController.isSectionSelected).toSet();
  }

  void _exportScorm() {
    final exportCourse = _buildExportCourse();
    final enabledStaticSections = _enabledStaticSectionIds();
    ScormExportService().exportCourse(
      exportCourse,
      enabledStaticSections: enabledStaticSections,
    );
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
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.dashboard_customize, color: Colors.indigo),
                onPressed: () => context.go('/'),
              ),
              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.deepOrange),
                tooltip: 'Stress Test Golden Course',
                onPressed: _confirmGoldenMockLoad,
              ),
              Expanded(
                child: TextFormField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: "Título del curso..."),
                  onChanged: (v) {
                    widget.course.title = v;
                    _notifyCourseUpdated();
                  },
                ),
              ),
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
          ),
        ),
      ),
    );
  }

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getSectionTitle(selectedSection).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo, letterSpacing: 1.1),
                ),
                Row(
                  children: [
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
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(35),
              child: _buildSectionEditor(selectedSection),
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
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.indigo.withOpacity(0.1),
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
          _buildGeneratedContentCard('general', "Salida IA · General"),
          const SizedBox(height: 10),
          _buildUniversalBlockList(widget.course.general.blocks),
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
          _buildGeneratedContentCard('map', "Salida IA · Mapa Conceptual"),
          const SizedBox(height: 10),
          _buildUniversalBlockList(widget.course.conceptMap.blocks),
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
          _buildGeneratedContentCard(widget.selectionController.sectionIdForModule(module), "Salida IA · ${module.title}"),
          const SizedBox(height: 10),
          _buildUniversalBlockList(module.blocks),
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
          _buildGeneratedContentCard('resources', "Salida IA · Recursos"),
          const SizedBox(height: 10),
          _buildUniversalBlockList(widget.course.resources.blocks),
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
          _buildGeneratedContentCard('eval', "Salida IA · Evaluación Final (JSON)"),
          const SizedBox(height: 10),
          _buildUniversalBlockList(widget.course.evaluation.blocks),
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
          _buildGeneratedContentCard('stats', "Salida IA · Estadísticas"),
          const SizedBox(height: 10),
          _buildUniversalBlockList(widget.course.stats.blocks),
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
          TextFormField(
            key: const ValueKey('stats_avg_score'),
            initialValue: widget.course.stats.averageScore.toStringAsFixed(1),
            decoration: const InputDecoration(
              labelText: "Nota promedio (%)",
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              _scheduleSetState(() {
                widget.course.stats.averageScore = double.tryParse(value) ?? 0.0;
              });
              _notifyCourseUpdated();
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('stats_avg_time'),
            initialValue: widget.course.stats.averageTimeMinutes.toString(),
            decoration: const InputDecoration(
              labelText: "Tiempo promedio (min)",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _scheduleSetState(() {
                widget.course.stats.averageTimeMinutes = int.tryParse(value) ?? 0;
              });
              _notifyCourseUpdated();
            },
          ),
        ],
      ),
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
        border: Border.all(color: Colors.indigo.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12)],
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
        border: Border.all(color: Colors.indigo.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
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
    return Row(
      children: [
        Icon(icon, color: hasFile ? Colors.green : Colors.grey, size: 24),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(hasFile ? value : "Pendiente de cargar...", style: TextStyle(color: hasFile ? Colors.black54 : Colors.red.shade300, fontSize: 11)),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: onPick,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, elevation: 0, foregroundColor: Colors.indigo),
          child: Text(hasFile ? "CAMBIAR" : "CARGAR"),
        ),
      ],
    );
  }

  Widget _buildUniversalBlockList(List<InteractiveBlock> blocks) {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: blocks.length,
          itemBuilder: (context, index) => _buildBlockWrapper(blocks, index),
        ),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.indigo.withOpacity(0.2), style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(15),
          ),
          child: InkWell(
            onTap: () => _openBlockSelector(blocks),
            borderRadius: BorderRadius.circular(15),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle, color: Colors.indigo),
                SizedBox(width: 15),
                Text("INCORPORAR NUEVA SECCIÓN DEBAJO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, letterSpacing: 1.1)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockWrapper(List<InteractiveBlock> list, int index) {
    final block = list[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(_getIconForBlock(block.type), size: 14, color: Colors.indigo),
                    const SizedBox(width: 10),
                    Text(block.type.name.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.keyboard_arrow_up, size: 16), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.keyboard_arrow_down, size: 16), onPressed: () {}),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.red),
                      onPressed: () {
                        _scheduleSetState(() => list.removeAt(index));
                        _notifyCourseUpdated();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: InteractiveBlockRenderer(block: block),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockPickerSheet(List<InteractiveBlock> targetList) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      padding: const EdgeInsets.all(35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CATÁLOGO DE FUNCIONALIDADES H5P", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const Text("Selecciona el componente interactivo que deseas añadir a la sección actual.", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 35),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
              ),
              itemCount: BlockType.values.length - 1,
              itemBuilder: (context, index) {
                final type = BlockType.values[index];
                return InkWell(
                  onTap: () {
                    _scheduleSetState(() => targetList.add(InteractiveBlock.create(type: type, content: {})));
                    _notifyCourseUpdated();
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: _buildBlockCategoryIcon(type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockCategoryIcon(BlockType type) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.indigo.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIconForBlock(type), color: Colors.indigo, size: 30),
          const SizedBox(height: 10),
          Text(type.name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
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

  IconData _getIconForBlock(BlockType type) {
    switch (type) {
      case BlockType.textPlain:
        return Icons.format_align_left;
      case BlockType.video:
        return Icons.play_circle_outline;
      case BlockType.interactiveBook:
        return Icons.auto_stories_outlined;
      case BlockType.accordion:
        return Icons.list_alt_outlined;
      case BlockType.singleChoice:
        return Icons.check_circle_outline;
      case BlockType.dragAndDrop:
        return Icons.back_hand_outlined;
      case BlockType.imageHotspot:
        return Icons.ads_click_outlined;
      case BlockType.carousel:
        return Icons.view_carousel_outlined;
      default:
        return Icons.widgets_outlined;
    }
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
