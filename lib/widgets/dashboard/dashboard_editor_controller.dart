part of '../dashboard_editor.dart';

const Set<String> _exportSectionIds = {
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

extension _DashboardEditorController on _DashboardEditorState {
  Future<void> ensureStateSynced() async {
    await _flushEditorState();
    if (!mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    final notifier = container.read(courseProvider.notifier);
    final snapshot = CourseModel.fromMap(widget.course.toMap());
    for (var i = 0; i < snapshot.modules.length; i++) {
      snapshot.modules[i].order = i;
    }
    notifier.updateFullCourse(snapshot);
    _localCourseState = snapshot;
  }

  Future<void> _exportScorm() async {
    await ensureStateSynced();
    if (!mounted) return;
    await StorageService().saveCourse(widget.course.toMap());
    if (!mounted) return;

    final container = ProviderScope.containerOf(context, listen: false);
    final notifier = container.read(courseProvider.notifier);
    final localState = _localCourseState ?? widget.course;
    if (localState.modules.isEmpty) {
      return;
    }
    await notifier.saveCourse();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await Future<void>.sync(() => notifier.updateFullCourse(localState));
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final liveCourse = container.read(courseProvider) ?? localState;
    final exportCourse = _buildExportCourseFromLive(liveCourse);
    final selectedModuleIds = liveCourse.modules
        .where((module) => widget.selectionController.isModuleSelected(module))
        .map((module) => module.id)
        .toSet();
    exportCourse.modules.removeWhere((module) => !selectedModuleIds.contains(module.id));

    final enabledStaticSections = _enabledStaticSectionIds();
    await ScormExportService().exportCourse(
      exportCourse,
      enabledStaticSections: enabledStaticSections,
    );
    if (!mounted) return;
  }

  Set<String> _enabledStaticSectionIds() {
    return _exportSectionIds.where(widget.selectionController.isSectionSelected).toSet();
  }

  CourseModel _buildExportCourseFromLive(CourseModel course) {
    return CourseModel(
      id: course.id,
      userId: course.userId,
      title: course.title,
      description: course.description,
      createdAt: course.createdAt,
      scormVersion: course.scormVersion,
      config: course.config,
      modules: List<ModuleModel>.from(course.modules),
      introText: course.introText,
      objectives: List<String>.from(course.objectives),
      glossaryItems: List<GlossaryItem>.from(course.glossaryItems),
      faqItems: List<FaqItem>.from(course.faqItems),
      general: course.general,
      intro: course.intro,
      conceptMap: course.conceptMap,
      resources: course.resources,
      glossary: course.glossary,
      faq: course.faq,
      evaluation: course.evaluation,
      stats: course.stats,
      contentBank: course.contentBank,
    );
  }

  Widget _buildUniversalBlockList(List<InteractiveBlock> blocks, {required String sectionId}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BlockToolbar(
          sectionId: sectionId,
          onBlockSelected: (type, initialContent) => _addBlockToSection(
            sectionId,
            type,
            initialContent: initialContent,
          ),
        ),
        const SizedBox(height: 18),
        InteractiveBlockEditor(
          blocks: blocks,
          onChanged: _notifyCourseUpdated,
          emptyLabel: 'Sin contenido.',
          showAddButton: false,
        ),
      ],
    );
  }

  void _addBlockToSection(
    String sectionId,
    BlockType type, {
    Map<String, dynamic>? initialContent,
  }) {
    final targetList = _resolveTargetBlocks(sectionId);
    if (targetList == null) return;
    _scheduleSetState(() => targetList.add(InteractiveBlock.create(type: type, content: initialContent ?? {})));
    _notifyCourseUpdated();
  }

}

class _BlockToolbar extends StatefulWidget {
  final String sectionId;
  final void Function(BlockType type, Map<String, dynamic>? initialContent) onBlockSelected;

  const _BlockToolbar({
    required this.sectionId,
    required this.onBlockSelected,
  });

  @override
  State<_BlockToolbar> createState() => _BlockToolbarState();
}

class _BlockToolbarState extends State<_BlockToolbar> {
  int _selectedFamily = 0;

  void _selectFamily(int index) {
    setState(() {
      _selectedFamily = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final family = _blockFamilies[_selectedFamily];
    return Material(
      elevation: 18,
      borderRadius: BorderRadius.circular(26),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 26, offset: const Offset(0, 16)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _blockFamilies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isActive = index == _selectedFamily;
                  final familyData = _blockFamilies[index];
                  return InkWell(
                    onTap: () => _selectFamily(index),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isActive
                            ? familyData.color
                            : familyData.color.withValues(alpha: 0.12),
                        border: Border.all(color: isActive ? familyData.color : Colors.transparent),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: familyData.color.withValues(alpha: 0.25),
                                  blurRadius: 18,
                                  offset: const Offset(0, 9),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        familyData.label,
                        style: TextStyle(
                          color: isActive ? Colors.white : familyData.color.withValues(alpha: 0.9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              family.description,
              style: TextStyle(color: Colors.grey.shade600, height: 1.3),
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: LayoutBuilder(
                key: ValueKey(family.id),
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width;
                  final columns = (availableWidth ~/ 200).clamp(1, family.blocks.length);
                  final tileWidth = (availableWidth - (columns - 1) * 12) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: family.blocks.map((block) {
                      return SizedBox(
                        width: tileWidth,
                        child: _BlockPaletteCard(
                          entry: block,
                          accentColor: family.color,
                          onTap: () => widget.onBlockSelected(block.type, block.initialContent),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockPaletteCard extends StatefulWidget {
  final _BlockToolEntry entry;
  final Color accentColor;
  final VoidCallback onTap;

  const _BlockPaletteCard({
    required this.entry,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_BlockPaletteCard> createState() => _BlockPaletteCardState();
}

class _BlockPaletteCardState extends State<_BlockPaletteCard> {
  bool _hovering = false;

  void _setHovering(bool value) {
    setState(() {
      _hovering = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovering(true),
      onExit: (_) => _setHovering(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovering ? widget.accentColor : Colors.grey.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: widget.accentColor.withValues(alpha: _hovering ? 0.3 : 0.15),
              blurRadius: _hovering ? 24 : 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.indigo.withValues(alpha: 0.12),
                    child: Icon(widget.entry.icon, size: 26, color: Colors.indigo),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.entry.label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.entry.description,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.2),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockFamily {
  final String id;
  final String label;
  final String description;
  final Color color;
  final List<_BlockToolEntry> blocks;

  const _BlockFamily({
    required this.id,
    required this.label,
    required this.description,
    required this.color,
    required this.blocks,
  });
}

class _BlockToolEntry {
  final BlockType type;
  final String label;
  final String description;
  final IconData icon;
  final Map<String, dynamic>? initialContent;

  const _BlockToolEntry({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    this.initialContent,
  });
}

const List<_BlockFamily> _blockFamilies = [
  _BlockFamily(
    id: 'fundamentos',
    label: 'Fundamentos',
    description: 'Transmitir la teoría y los conceptos clave de forma clara.',
    color: Colors.indigo,
    blocks: [
      _BlockToolEntry(
        type: BlockType.textRich,
        label: 'Encabezado',
        description: 'Divide secciones con títulos jerárquicos.',
        icon: Icons.title,
        initialContent: {'text': '<h2>Encabezado</h2>'},
      ),
      _BlockToolEntry(
        type: BlockType.textPlain,
        label: 'Texto plano',
        description: 'Explicaciones directas sin adornos.',
        icon: Icons.text_fields,
        initialContent: {'text': 'Escribe el concepto clave aquí.'},
      ),
      _BlockToolEntry(
        type: BlockType.textRich,
        label: 'Texto enriquecido',
        description: 'Combina estilos, listas y enlaces.',
        icon: Icons.format_paint,
        initialContent: {'text': '<p>Texto enriquecido con <strong>énfasis</strong>.</p>'},
      ),
      _BlockToolEntry(
        type: BlockType.quote,
        label: 'Cita destacada',
        description: 'Resalta frases inspiradoras o métricas clave.',
        icon: Icons.format_quote,
        initialContent: {'text': '“Inspira acción con una idea poderosa.”'},
      ),
      _BlockToolEntry(
        type: BlockType.textRich,
        label: 'Alerta visual',
        description: 'Señala advertencias o pasos críticos.',
        icon: Icons.warning_amber_outlined,
        initialContent: {'text': '<div class="alert"><strong>Atención:</strong> Acción requerida.</div>'},
      ),
    ],
  ),
  _BlockFamily(
    id: 'organizacion',
    label: 'Organización',
    description: 'Fragmentar información compleja para evitar la fatiga cognitiva.',
    color: Colors.teal,
    blocks: [
      _BlockToolEntry(
        type: BlockType.textRich,
        label: 'Lista inteligente',
        description: 'Agrupa pasos o elementos relacionados.',
        icon: Icons.list_alt,
        initialContent: {'text': '<ul><li>Paso 1</li><li>Paso 2</li><li>Paso 3</li></ul>'},
      ),
      _BlockToolEntry(
        type: BlockType.accordion,
        label: 'Acordeón',
        description: 'Permite desplegar contenido bajo demanda.',
        icon: Icons.expand_circle_down,
      ),
      _BlockToolEntry(
        type: BlockType.tabs,
        label: 'Pestañas',
        description: 'Separa variantes o escenarios en pestañas.',
        icon: Icons.tab,
      ),
      _BlockToolEntry(
        type: BlockType.timeline,
        label: 'Línea de tiempo',
        description: 'Secuencia cronológica de eventos o fases.',
        icon: Icons.timeline,
      ),
      _BlockToolEntry(
        type: BlockType.process,
        label: 'Procesos',
        description: 'Visualiza flujos o procedimientos clave.',
        icon: Icons.auto_awesome_motion,
      ),
    ],
  ),
  _BlockFamily(
    id: 'multimedia',
    label: 'Multimedia',
    description: 'Aportar contexto visual y auditivo de alto impacto.',
    color: Colors.orange,
    blocks: [
      _BlockToolEntry(
        type: BlockType.image,
        label: 'Imagen contextual',
        description: 'Ilustra ideas con fotografías o gráficos.',
        icon: Icons.image_outlined,
      ),
      _BlockToolEntry(
        type: BlockType.video,
        label: 'Video inmersivo',
        description: 'Explain con narrativa audiovisual.',
        icon: Icons.play_circle_outline,
      ),
      _BlockToolEntry(
        type: BlockType.audio,
        label: 'Audio guía',
        description: 'Narraciones rápidas o podcasts.',
        icon: Icons.volume_up_outlined,
      ),
      _BlockToolEntry(
        type: BlockType.carousel,
        label: 'Carrusel visual',
        description: 'Recorre ejemplos o etapas.',
        icon: Icons.view_carousel_outlined,
      ),
      _BlockToolEntry(
        type: BlockType.imageHotspot,
        label: 'Imagen interactiva',
        description: 'Puntos clicables sobre imágenes.',
        icon: Icons.touch_app_outlined,
      ),
    ],
  ),
  _BlockFamily(
    id: 'interactividad',
    label: 'Interactividad',
    description: 'Fomentar el compromiso mediante dinámicas de gamificación.',
    color: Colors.green,
    blocks: [
      _BlockToolEntry(
        type: BlockType.flashcards,
        label: 'Tarjetas de memoria',
        description: 'Refuerza conceptos con pares activo/respuesta.',
        icon: Icons.credit_card,
      ),
      _BlockToolEntry(
        type: BlockType.comparison,
        label: 'Comparación guiada',
        description: 'Contrasta dos ideas o alternativas.',
        icon: Icons.compare_arrows,
      ),
      _BlockToolEntry(
        type: BlockType.scenario,
        label: 'Escenario de decisión',
        description: 'Simula situaciones reales con decisiones.',
        icon: Icons.sports_esports,
      ),
    ],
  ),
  _BlockFamily(
    id: 'comprobacion',
    label: 'Comprobación',
    description: 'Retos cortos para validar que el alumno sigue el hilo del curso.',
    color: Colors.red,
    blocks: [
      _BlockToolEntry(
        type: BlockType.singleChoice,
        label: 'Opción única',
        description: 'Pregunta directa con una sola respuesta correcta.',
        icon: Icons.radio_button_checked,
      ),
      _BlockToolEntry(
        type: BlockType.multipleChoice,
        label: 'Selección múltiple',
        description: 'Retos con múltiples respuestas validadas.',
        icon: Icons.checklist,
      ),
      _BlockToolEntry(
        type: BlockType.trueFalse,
        label: 'Verdadero / Falso',
        description: 'Verifica comprensión rápida con dos opciones.',
        icon: Icons.toggle_on,
      ),
    ],
  ),
  _BlockFamily(
    id: 'retos',
    label: 'Retos',
    description: 'Evaluación de desempeño y retos de aplicación activa.',
    color: Colors.purple,
    blocks: [
      _BlockToolEntry(
        type: BlockType.fillBlanks,
        label: 'Texto para completar',
        description: 'Completa breves espacios con conceptos clave.',
        icon: Icons.keyboard_double_arrow_right,
      ),
      _BlockToolEntry(
        type: BlockType.matching,
        label: 'Emparejamientos',
        description: 'Relaciona términos con significados o pasos.',
        icon: Icons.link,
      ),
      _BlockToolEntry(
        type: BlockType.sorting,
        label: 'Ordenamiento lógico',
        description: 'Organiza pasos, categorías o procesos.',
        icon: Icons.swap_vert,
      ),
    ],
  ),
];
