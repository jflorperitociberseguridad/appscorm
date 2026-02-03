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

part 'dashboard/dashboard_editor_actions.dart';
part 'dashboard/dashboard_editor_sections.dart';
part 'dashboard/dashboard_editor_ui.dart';
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
}
