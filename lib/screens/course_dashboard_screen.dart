import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/course_model.dart';
import '../models/interactive_block.dart';
import '../models/module_model.dart';
import '../providers/course_provider.dart';
import '../widgets/dashboard_editor.dart';
import '../widgets/dashboard_sidebar.dart';
import '../widgets/gamification_dashboard.dart';

class CourseDashboardScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? courseData;

  const CourseDashboardScreen({super.key, this.courseData});

  @override
  ConsumerState<CourseDashboardScreen> createState() => _CourseDashboardScreenState();
}

class _CourseDashboardScreenState extends ConsumerState<CourseDashboardScreen> {
  late CourseModel _course;
  bool _isLoading = true;
  bool _isRightPanelVisible = true;
  late final DashboardSelectionController _selectionController;
  late final ScrollController _editorScrollController;
  late final bool _scrollToTopOnStart;

  void _scheduleSetState(VoidCallback fn) {
    Future.microtask(() {
      if (!mounted) return;
      setState(fn);
    });
  }

  @override
  void initState() {
    super.initState();
    _selectionController = DashboardSelectionController();
    _editorScrollController = ScrollController();
    _scrollToTopOnStart = widget.courseData?['_scrollToTop'] == true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCourse();
    });
  }

  void _initCourse() {
    if (widget.courseData != null) {
      try {
        _course = CourseModel.fromMap(widget.courseData!);
      } catch (e) {
        debugPrint("Error al parsear el curso: $e");
        _crearNuevoCurso();
      }
    } else {
      _crearNuevoCurso();
    }

    if (_course.modules.isEmpty) {
      _addNewModule(initial: true);
    }

    _selectionController.initialize(_course);
    _selectionController.selectSection('intro');
    Future.microtask(() {
      ref.read(courseProvider.notifier).setCourse(_course);
      if (mounted) {
        _scheduleSetState(() => _isLoading = false);
      }
    });
    if (_scrollToTopOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_editorScrollController.hasClients) return;
        _editorScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _crearNuevoCurso() {
    _course = CourseModel(
      id: const Uuid().v4(),
      title: "Nuevo Curso Formativo",
      description: "",
      createdAt: DateTime.now(),
      modules: [],
    );
  }

  void _addNewModule({bool initial = false}) {
    final newMod = ModuleModel(
      id: const Uuid().v4(),
      title: "Nuevo Tema ${_course.modules.length + 1}",
      order: _course.modules.length,
      blocks: [InteractiveBlock.create(type: BlockType.textPlain, content: {'text': ''})],
      content: '',
      type: ModuleType.text,
    );

    _course.modules.add(newMod);
    _selectionController.onModuleAdded(newMod, select: !initial);
    if (!initial) {
      _notifyCourseUpdated();
    }
  }

  void _notifyCourseUpdated() {
    Future.microtask(() {
      ref.read(courseProvider.notifier).setCourse(_course);
      if (mounted) {
        _scheduleSetState(() {});
      }
    });
  }

  void _toggleRightPanel() {
    _scheduleSetState(() => _isRightPanelVisible = !_isRightPanelVisible);
  }

  double _calculateProgress() => 0.55;

  @override
  void dispose() {
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final course = ref.watch(courseProvider) ?? _course;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          DashboardSidebar(
            course: course,
            selectionController: _selectionController,
            onCourseUpdated: _notifyCourseUpdated,
            onAddModule: _addNewModule,
          ),
          Expanded(
            child: DashboardEditor(
              course: course,
              selectionController: _selectionController,
              onCourseUpdated: _notifyCourseUpdated,
              onAddModule: _addNewModule,
              onToggleRightPanel: _toggleRightPanel,
              isRightPanelVisible: _isRightPanelVisible,
              scrollController: _editorScrollController,
            ),
          ),
          if (_isRightPanelVisible)
            GamificationDashboard(
              progress: _calculateProgress(),
              onClose: _toggleRightPanel,
            ),
        ],
      ),
    );
  }
}
