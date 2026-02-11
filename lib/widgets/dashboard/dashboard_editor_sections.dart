part of '../dashboard_editor.dart';

extension _DashboardEditorSections on _DashboardEditorState {
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
      case 'manuscript':
        return _buildManuscriptSection();
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

  Widget _buildGeneralSection() {
    return _wrapWithRepaint(
      SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
          children: [
            _buildInitialPanelConfigCard(),
            _buildGeneralHeader(),
            const SizedBox(height: 10),
            _buildUniversalBlockList(widget.course.general.blocks,
                sectionId: 'general'),
            _buildGeneratedContentCard('general', "Salida IA · General"),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return _wrapWithRepaint(
      SingleChildScrollView(
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
            _buildUniversalBlockList(widget.course.intro.introBlocks,
                sectionId: 'intro'),
            _buildGeneratedContentCard('intro', "Salida IA · Introducción"),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectivesSection() {
    return _wrapWithRepaint(
      SingleChildScrollView(
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
                        _scheduleSetState(
                            () => widget.course.objectives.add(''));
                        _notifyCourseUpdated();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar objetivo"),
                    ),
                  ),
                ],
              ),
            ),
            _buildUniversalBlockList(widget.course.intro.objectiveBlocks,
                sectionId: 'objectives'),
            _buildGeneratedContentCard('objectives', "Salida IA · Objetivos"),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return _wrapWithRepaint(
      SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
          children: [
            _buildSimpleCard(
              title: "Mapa conceptual del curso",
              child: const Text(
                  "Organiza el mapa conceptual y sus bloques visuales."),
            ),
            const SizedBox(height: 10),
            _buildUniversalBlockList(widget.course.conceptMap.blocks,
                sectionId: 'map'),
            _buildGeneratedContentCard('map', "Salida IA · Mapa Conceptual"),
          ],
        ),
      ),
    );
  }

  Widget _buildManuscriptSection() {
    final manuscriptMarkdown =
        widget.course.referenceModule?.content.trim() ?? '';
    final hasManuscript = manuscriptMarkdown.isNotEmpty;
    final theme = Theme.of(context);
    return _wrapWithRepaint(
      SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
          children: [
            _buildSimpleCard(
              title: "Manuscrito Maestro",
              child: hasManuscript
                  ? Markdown(
                      data: manuscriptMarkdown,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        h1: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        h2: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        p: theme.textTheme.bodyMedium,
                        listBullet: theme.textTheme.bodyMedium,
                      ),
                    )
                  : const Text(
                      "Aún no se ha generado un manuscrito maestro. Ve al flujo de generación y valida el manuscrito para verlo aquí.",
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndexSection() {
    return _wrapWithRepaint(
      SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
          children: [
            _buildSimpleCard(
              title: "Índice del curso",
              child: Column(
                children: [
                  for (int i = 0; i < widget.course.modules.length; i++)
                    ListTile(
                      key: ValueKey(
                          'module_index_${widget.course.modules[i].id}'),
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                        child: Text(
                          "${i + 1}",
                          style: const TextStyle(
                              fontSize: 11, color: Colors.indigo),
                        ),
                      ),
                      title: Text(
                        widget.course.modules[i].title,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      trailing: TextButton(
                        onPressed: () => widget.selectionController
                            .selectModule(widget.course.modules[i]),
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
      ),
    );
  }

  Widget _buildModulesRootSection() {
    return _wrapWithRepaint(
      SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
          children: [
            _buildSimpleCard(
                title: "Gestión del temario",
                child: _buildModulesManagerRoot()),
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
                            backgroundColor:
                                Colors.indigo.withValues(alpha: 0.1),
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.indigo),
                            ),
                          ),
                          title: Text(
                            module.title,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          trailing: TextButton(
                            onPressed: () =>
                                widget.selectionController.selectModule(module),
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
      ),
    );
  }

  Widget _buildModuleSection() {
    final module = widget.selectionController.getSelectedModule(widget.course);
    if (module == null) {
      return _buildModulesManagerRoot();
    }
    return _wrapWithRepaint(
      SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
          children: [
            _buildSimpleCard(
              title: "Tema seleccionado",
              child: Text(module.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            _buildUniversalBlockList(
              module.blocks,
              sectionId: widget.selectionController.sectionIdForModule(module),
            ),
            _buildGeneratedContentCard(
                widget.selectionController.sectionIdForModule(module),
                "Salida IA · ${module.title}"),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesSection() {
    return _wrapWithRepaint(
      SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
          children: [
            _buildSimpleCard(
              title: "Recursos didácticos",
              child: const Text(
                  "Gestiona recursos adicionales y materiales complementarios."),
            ),
            const SizedBox(height: 10),
            _buildUniversalBlockList(widget.course.resources.blocks,
                sectionId: 'resources'),
            _buildGeneratedContentCard('resources', "Salida IA · Recursos"),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationSection() {
    return _wrapWithRepaint(
      SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
          children: [
            _buildSimpleCard(
              title: "Evaluación final",
              child: const Text("Configura la evaluación final y sus bloques."),
            ),
            const SizedBox(height: 10),
            _buildUniversalBlockList(widget.course.evaluation.blocks,
                sectionId: 'eval'),
            _buildGeneratedContentCard(
                'eval', "Salida IA · Evaluación Final (JSON)"),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return _wrapWithRepaint(
      SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
          children: [
            _buildStatsHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBankSection() {
    return _wrapWithRepaint(
      SingleChildScrollView(
        controller: _mainScrollController,
        child: Column(
          children: [
            _buildContentBankHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlossarySection() {
    return _wrapWithRepaint(
      SingleChildScrollView(
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
            _buildUniversalBlockList(widget.course.glossary.blocks,
                sectionId: 'glossary'),
            _buildGeneratedContentCard('glossary', "Salida IA · Glosario"),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    return _wrapWithRepaint(
      SingleChildScrollView(
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
            _buildUniversalBlockList(widget.course.faq.blocks,
                sectionId: 'faq'),
            _buildGeneratedContentCard(
                'faq', "Salida IA · Preguntas Frecuentes"),
          ],
        ),
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
              key: ValueKey(
                  'objective_${widget.course.objectives[index].hashCode}'),
              initialValue: widget.course.objectives[index],
              decoration: const InputDecoration(
                labelText: "Objetivo",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  _scheduleDebouncedCourseUpdate('objective_$index', () {
                widget.course.objectives[index] = value;
              }),
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
                  onChanged: (value) => _scheduleDebouncedCourseUpdate(
                      'glossary_term_$index', () {
                    item.term = value;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade300,
                onPressed: () {
                  _scheduleSetState(
                      () => widget.course.glossaryItems.removeAt(index));
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
            onChanged: (value) =>
                _scheduleDebouncedCourseUpdate('glossary_def_$index', () {
              item.definition = value;
            }),
          ),
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
                  onChanged: (value) =>
                      _scheduleDebouncedCourseUpdate('faq_question_$index', () {
                    item.question = value;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade300,
                onPressed: () {
                  _scheduleSetState(
                      () => widget.course.faqItems.removeAt(index));
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
            onChanged: (value) =>
                _scheduleDebouncedCourseUpdate('faq_answer_$index', () {
              item.answer = value;
            }),
          ),
        ],
      ),
    );
  }

  Widget _wrapWithRepaint(Widget child) {
    return RepaintBoundary(child: child);
  }

  Widget _buildModulesManagerRoot() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_books_outlined,
              size: 80, color: Colors.grey),
          const SizedBox(height: 25),
          const Text("GESTIÓN INTEGRAL DEL TEMARIO",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text(
              "Crea, ordena y gestiona los temas principales de tu curso SCORM.",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: widget.onAddModule,
            icon: const Icon(Icons.add),
            label: const Text("AÑADIR TEMA PRINCIPAL"),
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
          ),
        ],
      ),
    );
  }
}
