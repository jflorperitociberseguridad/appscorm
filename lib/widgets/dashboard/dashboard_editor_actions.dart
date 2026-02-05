part of '../dashboard_editor.dart';

extension _DashboardEditorActions on _DashboardEditorState {
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
      final aiService = await AiService.create();
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
}
