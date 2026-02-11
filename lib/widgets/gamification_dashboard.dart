import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_model.dart';
import '../models/interactive_block.dart';
import '../providers/course_provider.dart';
import 'gamification/calendar_panel.dart';
import 'gamification/chat_panel.dart';
import 'gamification/milestones_panel.dart';
import 'gamification/models.dart';
import 'gamification/progress_panel.dart';
import 'gamification/support_panel.dart';

/// GamificationDashboard
/// - Panel operativo con progreso, calendario, mensajes y soporte.
class GamificationDashboard extends ConsumerStatefulWidget {
  final double progress; // 0.0 - 1.0
  final List<Map<String, dynamic>> badges;
  final List<Map<String, dynamic>> events; // se puede usar para hitos
  final VoidCallback? onClose;

  const GamificationDashboard({
    super.key,
    this.progress = 0.45,
    this.badges = const [],
    this.events = const [],
    this.onClose,
  });

  @override
  ConsumerState<GamificationDashboard> createState() => _GamificationDashboardState();
}

class _GamificationDashboardState extends ConsumerState<GamificationDashboard> with WidgetsBindingObserver {
  Duration _studyTotal = Duration.zero;
  Timer? _studyTimer;
  DateTime? _studyTick;
  String? _activeCourseId;
  List<GamificationMilestone> _milestones = [];
  final GlobalKey<GamificationChatPanelState> _chatPanelKey = GlobalKey<GamificationChatPanelState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _milestones = _buildMilestones(widget.events);
    ref.listen<CourseModel?>(courseProvider, (prev, next) {
      if (next != null && next.id != _activeCourseId) {
        _loadStudyData(next);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final course = ref.read(courseProvider);
      if (course != null) {
        _loadStudyData(course);
      }
      _startStudyTimer();
    });
  }

  @override
  void didUpdateWidget(covariant GamificationDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events != oldWidget.events) {
      _scheduleSetState(() {
        _milestones = _buildMilestones(widget.events);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _studyTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseStudyTimer();
    } else if (state == AppLifecycleState.resumed) {
      _startStudyTimer();
    }
  }

  void _scheduleSetState(VoidCallback fn) {
    Future.microtask(() {
      if (!mounted) return;
      setState(fn);
    });
  }

  Future<void> _loadStudyData(CourseModel course) async {
    _activeCourseId = course.id;
    final prefs = await SharedPreferences.getInstance();
    final totalSeconds = prefs.getInt(_studyKey(course.id)) ?? 0;
    _studyTotal = Duration(seconds: totalSeconds);
    if (mounted) {
      _scheduleSetState(() {});
    }
  }

  Future<void> _persistStudyTime() async {
    if (_activeCourseId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_studyKey(_activeCourseId!), _studyTotal.inSeconds);
  }

  void _startStudyTimer() {
    if (_studyTimer != null) return;
    _studyTick = DateTime.now();
    _studyTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (_studyTick != null) {
        _studyTotal += now.difference(_studyTick!);
        _studyTick = now;
      }
      _persistStudyTime();
      if (mounted) {
        _scheduleSetState(() {});
      }
    });
  }

  void _pauseStudyTimer() {
    _studyTimer?.cancel();
    _studyTimer = null;
    _studyTick = null;
  }

  String _studyKey(String courseId) => 'study_time_$courseId';

  List<GamificationMilestone> _buildMilestones(List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      final now = DateTime.now();
      return [
        GamificationMilestone(title: 'Entrega 1: Actividad', date: now.add(const Duration(days: 3)), icon: gamificationIcon('flag')),
        GamificationMilestone(title: 'Examen Parcial', date: now.add(const Duration(days: 10)), icon: gamificationIcon('rocket')),
        GamificationMilestone(title: 'Proyecto Final - Inicio', date: now.add(const Duration(days: 20)), icon: gamificationIcon('rocket')),
      ];
    }
    return events.map((e) {
      final dateValue = e['date'];
      final date = dateValue is DateTime ? dateValue : (DateTime.tryParse(dateValue?.toString() ?? '') ?? DateTime.now());
      final iconName = e['icon']?.toString() ?? 'flag';
      return GamificationMilestone(title: e['title']?.toString() ?? 'Hito', date: date, icon: gamificationIcon(iconName));
    }).toList();
  }

  double _calculateProgressFromCourse(CourseModel? course) {
    if (course == null) return widget.progress;
    final modules = course.modules;
    final totalModules = modules.isEmpty ? 1 : modules.length;
    final completedModules = modules.where((m) => m.isCompleted).length;
    final moduleRatio = completedModules / totalModules;

    final quizBlocks = course.evaluation.blocks.where((block) {
      return block.type == BlockType.singleChoice ||
          block.type == BlockType.multipleChoice ||
          block.type == BlockType.trueFalse ||
          block.type == BlockType.questionSet;
    }).toList();
    final totalQuizzes = quizBlocks.isEmpty ? 1 : quizBlocks.length;
    final completedQuizzes = quizBlocks.where((block) {
      return (block.content['isCompleted'] == true) || (block.content['completed'] == true);
    }).length;
    final quizRatio = completedQuizzes / totalQuizzes;

    final examDone = course.evaluation.finalExamId.trim().isNotEmpty;
    final examRatio = examDone ? 1.0 : 0.0;

    final combined = (moduleRatio + quizRatio + examRatio) / 3;
    return combined.clamp(0.0, 1.0);
  }

  int _calculateXpFromCourse(CourseModel? course) {
    if (course == null) return 0;
    final blocks = <InteractiveBlock>[];
    for (final module in course.modules) {
      blocks.addAll(module.blocks);
    }
    blocks.addAll(course.evaluation.blocks);
    blocks.addAll(course.contentBank.blocks);

    int total = 0;
    for (final block in blocks) {
      final earned = block.content['xpEarned'] == true;
      if (!earned) continue;
      final earnedRaw = block.content['earnedXp'];
      final raw = earnedRaw ?? block.content['xp'];
      if (raw is int) {
        total += raw;
      } else if (raw is double) {
        total += raw.toInt();
      } else if (raw is String) {
        total += int.tryParse(raw) ?? 0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final course = ref.watch(courseProvider);
    final progress = _calculateProgressFromCourse(course);
    final xpTotal = _calculateXpFromCourse(course);

    const width = 340.0;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(-5, 0)),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('PANEL DEL ALUMNO', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mark_email_read_outlined, size: 20, color: Colors.grey),
                    onPressed: () => _chatPanelKey.currentState?.openMessageCenter(),
                    splashRadius: 20,
                    tooltip: 'Bandeja de mensajes',
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                      onPressed: widget.onClose,
                      splashRadius: 20,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GamificationProgressPanel(
                      progress: progress,
                      studyDuration: _studyTotal,
                      xpTotal: xpTotal,
                    ),
                    const SizedBox(height: 18),
                    GamificationCalendarPanel(course: course),
                    const SizedBox(height: 18),
                    GamificationChatPanel(key: _chatPanelKey),
                    const SizedBox(height: 18),
                    GamificationMilestonesPanel(milestones: _milestones),
                    const SizedBox(height: 18),
                    GamificationSupportPanel(course: course),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
