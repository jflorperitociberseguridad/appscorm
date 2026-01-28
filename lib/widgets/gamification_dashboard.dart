import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';
import '../models/interactive_block.dart';
import '../providers/course_provider.dart';
import '../services/ai_service.dart';

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
  // Calendario
  DateTime _visibleMonth = DateTime.now();
  DateTime? _selectedDate;

  // Chat
  final List<_ChatMessage> _messages = [];
  final List<_ChatMessage> _systemMessages = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();

  // Ejemplo de hitos (si widget.events está vacío)
  late List<Map<String, dynamic>> _milestones;

  // Eventos del calendario
  final Map<String, List<_CalendarEntry>> _calendarEntries = {};

  // Tiempo de estudio
  Timer? _studyTimer;
  DateTime? _studyTick;
  Duration _studyTotal = Duration.zero;
  String? _activeCourseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDate = DateTime.now();

    // Inicializar mensajes de ejemplo
    _messages.addAll([
      _ChatMessage(sender: 'system', text: 'Bienvenido al canal del curso', time: DateTime.now().subtract(const Duration(minutes: 30))),
      _ChatMessage(sender: 'tutor', text: 'Recuerda completar el módulo 2', time: DateTime.now().subtract(const Duration(minutes: 20))),
    ]);
    _systemMessages.addAll([
      _ChatMessage(sender: 'system', text: 'Actualización: nuevos recursos disponibles en el curso.', time: DateTime.now().subtract(const Duration(hours: 3))),
      _ChatMessage(sender: 'system', text: 'Recordatorio: examen final programado para esta semana.', time: DateTime.now().subtract(const Duration(days: 1))),
    ]);

    // Inicializar hitos desde widget.events o usando ejemplos
    _milestones = widget.events.isNotEmpty
        ? widget.events.map((e) => {
            'title': e['title'] ?? 'Hito',
            'date': e['date'] ?? DateTime.now().add(const Duration(days: 7)),
            'icon': e['icon'] ?? 'flag'
          }).toList()
        : [
            {'title': 'Entrega 1: Actividad', 'date': DateTime.now().add(const Duration(days: 3)), 'icon': 'flag'},
            {'title': 'Examen Parcial', 'date': DateTime.now().add(const Duration(days: 10)), 'icon': 'rocket'},
            {'title': 'Proyecto Final - Inicio', 'date': DateTime.now().add(const Duration(days: 20)), 'icon': 'rocket'},
          ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final course = ref.read(courseProvider);
      if (course != null) {
        _loadCourseData(course);
      }
      _startStudyTimer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _studyTimer?.cancel();
    _chatController.dispose();
    _chatScroll.dispose();
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

  // -----------------------
  // Helpers calendario
  // -----------------------
  DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  int _daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;
  int _startWeekday(DateTime d) => _firstOfMonth(d).weekday % 7; // 0 = Sunday, 6 = Saturday

  void _prevMonth() {
    _scheduleSetState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    _scheduleSetState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  void _selectDate(DateTime d) {
    _scheduleSetState(() {
      _selectedDate = d;
    });
  }

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _loadCourseData(CourseModel course) async {
    _activeCourseId = course.id;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_calendarKey(course.id));
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _calendarEntries
        ..clear()
        ..addAll(decoded.map((key, value) {
          final list = (value as List).map((e) => _CalendarEntry.fromMap(Map<String, dynamic>.from(e))).toList();
          return MapEntry(key, list);
        }));
    }
    final totalSeconds = prefs.getInt(_studyKey(course.id)) ?? 0;
    _studyTotal = Duration(seconds: totalSeconds);
    if (mounted) {
      _scheduleSetState(() {});
    }
  }

  Future<void> _persistCalendar() async {
    if (_activeCourseId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{};
    _calendarEntries.forEach((key, value) {
      payload[key] = value.map((e) => e.toMap()).toList();
    });
    await prefs.setString(_calendarKey(_activeCourseId!), jsonEncode(payload));
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

  // -----------------------
  // Chat
  // -----------------------
  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    final msg = _ChatMessage(sender: 'me', text: text, time: DateTime.now());
    _scheduleSetState(() {
      _messages.add(msg);
      _chatController.clear();
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(_chatScroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _openMessageCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _MessageCenterSheet(
        internalMessages: _messages,
        systemMessages: _systemMessages,
        onSend: (text) {
          final msg = _ChatMessage(sender: 'me', text: text, time: DateTime.now());
          _scheduleSetState(() {
            _messages.add(msg);
          });
        },
      ),
    );
  }

  Future<void> _openDayDialog(DateTime date) async {
    final key = _dateKey(date);
    final entries = _calendarEntries[key] ?? [];
    final titleController = TextEditingController();
    _CalendarEntryType selectedType = _CalendarEntryType.event;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Agenda · ${DateFormat('dd MMM yyyy').format(date)}"),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text("No hay eventos registrados.", style: TextStyle(color: Colors.grey)),
                ),
              if (entries.isNotEmpty)
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(entry.type == _CalendarEntryType.event ? Icons.event : Icons.alarm),
                        title: Text(entry.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            _scheduleSetState(() {
                              entries.removeAt(index);
                              _calendarEntries[key] = entries;
                            });
                            _persistCalendar();
                          },
                        ),
                      );
                    },
                  ),
                ),
              const Divider(),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Nueva tarea o alarma",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<_CalendarEntryType>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: "Tipo",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: _CalendarEntryType.event, child: Text("Evento")),
                  DropdownMenuItem(value: _CalendarEntryType.alarm, child: Text("Alarma")),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cerrar")),
          ElevatedButton(
            onPressed: () {
              final text = titleController.text.trim();
              if (text.isNotEmpty) {
                _scheduleSetState(() {
                  final updated = [...entries, _CalendarEntry(title: text, type: selectedType)];
                  _calendarEntries[key] = updated;
                });
                _persistCalendar();
              }
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
    titleController.dispose();
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

  String _formatProgressLabel(double p) {
    if (p >= 1.0) return 'Completado';
    if (p >= 0.75) return 'Casi alli';
    if (p >= 0.5) return 'Avanzado';
    if (p >= 0.25) return 'En progreso';
    return 'Inicio';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _calendarKey(String courseId) => 'calendar_entries_$courseId';
  String _studyKey(String courseId) => 'study_time_$courseId';

  void _scheduleSetState(VoidCallback fn) {
    Future.microtask(() {
      if (!mounted) return;
      setState(fn);
    });
  }

  // -----------------------
  // Build
  // -----------------------
  @override
  Widget build(BuildContext context) {
    final course = ref.watch(courseProvider);
    final progress = _calculateProgressFromCourse(course);

    ref.listen<CourseModel?>(courseProvider, (prev, next) {
      if (next != null && next.id != _activeCourseId) {
        _loadCourseData(next);
      }
    });

    // Tamaño típico panel lateral
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
            // Header con título y botón cerrar
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
                    onPressed: _openMessageCenter,
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

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1) Area de Progreso (TOP)
                    _buildProgressArea(progress),

                    const SizedBox(height: 18),

                    // 2) Calendario (visual)
                    _buildCalendarCard(),

                    const SizedBox(height: 18),

                    // 3) Canal de Mensajes (Chat simulado)
                    _buildChatCard(),

                    const SizedBox(height: 18),

                    // 4) Proximos Hitos
                    _buildMilestonesCard(),

                    const SizedBox(height: 18),

                    // 5) Canal de Soporte (AL FINAL)
                    _buildSupportCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------
  // Widgets individuales
  // -----------------------
  Widget _buildProgressArea(double progress) {
    final percent = (progress.clamp(0.0, 1.0) * 100).toInt();
    final xpTotal = _calculateXpFromCourse(ref.watch(courseProvider));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFAFBFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progreso del Curso', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              color: const Color(0xFF2563EB),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$percent% completado', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(_formatProgressLabel(progress), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiempo de estudio', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text(_formatDuration(_studyTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('XP obtenida', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text('$xpTotal XP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    final monthLabel = DateFormat.yMMMM().format(_visibleMonth);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFFEFEFF), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header month with controls
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  monthLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _prevMonth,
                iconSize: 18,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
                iconSize: 18,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Calendar grid
          _buildCalendarGrid(),
          const SizedBox(height: 8),
          if (_selectedDate != null)
            Text('Seleccionado: ${DateFormat.yMMMd().format(_selectedDate!)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final startWeekday = _startWeekday(_visibleMonth); // 0..6, Sunday-based
    final totalDays = _daysInMonth(_visibleMonth);

    final cells = <Widget>[];
    // weekday headers
    const weekDays = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];
    for (var wd in weekDays) {
      cells.add(Center(child: Text(wd, style: const TextStyle(fontSize: 11, color: Colors.grey))));
    }

    // padding empties before start
    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    // days
    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      final selected = _selectedDate != null &&
          (date.year == _selectedDate!.year && date.month == _selectedDate!.month && date.day == _selectedDate!.day);
      final isToday = DateTime.now().year == date.year && DateTime.now().month == date.month && DateTime.now().day == date.day;
      final hasEntries = _calendarEntries[_dateKey(date)]?.isNotEmpty ?? false;

      cells.add(GestureDetector(
        onTap: () {
          _selectDate(date);
          _openDayDialog(date);
        },
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2563EB) : (isToday ? Colors.blue.shade50 : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: hasEntries ? Border.all(color: const Color(0xFF2563EB), width: 1) : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 11,
              color: selected ? Colors.white : (isToday ? const Color(0xFF2563EB) : Colors.black87),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ));
    }

    while (cells.length < 7 * 6) {
      cells.add(const SizedBox.shrink());
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 7,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.75,
        physics: const NeverScrollableScrollPhysics(),
        children: cells,
      ),
    );
  }

  Widget _buildChatCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 160, maxHeight: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFFFFFFF), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Canal de Mensajes', style: TextStyle(fontWeight: FontWeight.bold))),
              TextButton.icon(
                onPressed: _openMessageCenter,
                icon: const Icon(Icons.inbox, size: 16),
                label: const Text('Bandeja'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ListView.builder(
                controller: _chatScroll,
                itemCount: _messages.length,
                shrinkWrap: true,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final mine = m.sender == 'me';
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!mine)
                          CircleAvatar(radius: 14, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, size: 16, color: Colors.black54)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: mine ? const Color(0xFF2563EB) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.text,
                                  style: TextStyle(color: mine ? Colors.white : Colors.black87),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat.Hm().format(m.time),
                                  style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : Colors.grey),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (mine)
                          CircleAvatar(radius: 14, backgroundColor: Colors.blue.shade50, child: const Icon(Icons.person, size: 16, color: Color(0xFF2563EB))),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Input
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sendMessage,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14)),
                child: const Icon(Icons.send, size: 18),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFFFFFFFF), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.emoji_events_outlined, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Proximos Hitos', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Column(
            children: _milestones.map((m) {
              final date = (m['date'] is DateTime) ? m['date'] as DateTime : DateTime.tryParse(m['date'].toString()) ?? DateTime.now();
              final iconName = m['icon'] ?? 'flag';
              final icon = (iconName == 'rocket') ? Icons.rocket_launch : Icons.flag;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(icon, color: const Color(0xFF2563EB), size: 18)),
                title: Text(m['title'] ?? 'Hito', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(DateFormat.yMMMd().format(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SupportScreen(course: ref.read(courseProvider))),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.headset_mic, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Servicio Tecnico de Cibermedia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Centro de ayuda y IA', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              splashRadius: 20,
            )
          ],
        ),
      ),
    );
  }
}

/// Simple wrapper para mensajes
class _ChatMessage {
  final String sender; // 'me', 'tutor', 'system', ...
  final String text;
  final DateTime time;
  _ChatMessage({required this.sender, required this.text, required this.time});
}

enum _CalendarEntryType { event, alarm }

class _CalendarEntry {
  final String title;
  final _CalendarEntryType type;

  const _CalendarEntry({required this.title, required this.type});

  Map<String, dynamic> toMap() => {
        'title': title,
        'type': type.name,
      };

  factory _CalendarEntry.fromMap(Map<String, dynamic> map) => _CalendarEntry(
        title: map['title'] ?? '',
        type: map['type'] == 'alarm' ? _CalendarEntryType.alarm : _CalendarEntryType.event,
      );
}

class _MessageCenterSheet extends StatefulWidget {
  final List<_ChatMessage> internalMessages;
  final List<_ChatMessage> systemMessages;
  final ValueChanged<String> onSend;

  const _MessageCenterSheet({
    required this.internalMessages,
    required this.systemMessages,
    required this.onSend,
  });

  @override
  State<_MessageCenterSheet> createState() => _MessageCenterSheetState();
}

class _MessageCenterSheetState extends State<_MessageCenterSheet> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputController = TextEditingController();

  void _scheduleSetState(VoidCallback fn) {
    if (mounted) {
      Future.microtask(() => setState(fn));
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 460,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2563EB),
              tabs: const [
                Tab(text: 'Internos'),
                Tab(text: 'Sistema'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMessages(widget.internalMessages),
                  _buildMessages(widget.systemMessages),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final text = _inputController.text.trim();
                      if (text.isEmpty) return;
                      widget.onSend(text);
                      _inputController.clear();
                      _scheduleSetState(() {});
                    },
                    child: const Text('Enviar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(List<_ChatMessage> messages) {
    if (messages.isEmpty) {
      return const Center(child: Text('Sin mensajes.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(msg.text),
          subtitle: Text(DateFormat('dd/MM HH:mm').format(msg.time)),
          leading: Icon(msg.sender == 'system' ? Icons.info_outline : Icons.person_outline),
        );
      },
    );
  }
}

class SupportScreen extends StatefulWidget {
  final CourseModel? course;

  const SupportScreen({super.key, required this.course});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _issueController = TextEditingController();
  String? _aiResponse;
  bool _isConsulting = false;

  void _scheduleSetState(VoidCallback fn) {
    if (mounted) {
      Future.microtask(() => setState(fn));
    }
  }

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _consultAi() async {
    final issue = _issueController.text.trim();
    if (issue.isEmpty) return;
    _scheduleSetState(() {
      _isConsulting = true;
      _aiResponse = null;
    });
    final aiService = AiService();
    const guide = 'Guia rapida AppScorm: revisar contenido, exportacion SCORM, y sincronizacion de modulos.';
    final response = await aiService.analyzeDocument('Consulta: $issue\n$guide');
    if (!mounted) return;
    _scheduleSetState(() {
      _aiResponse = response;
      _isConsulting = false;
    });
  }

  void _sendTicket() {
    final issue = _issueController.text.trim();
    if (issue.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket enviado a soporte.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicio Tecnico'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Describe tu problema', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _issueController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ej: Fallo al exportar SCORM...',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isConsulting ? null : _consultAi,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_isConsulting ? 'Consultando...' : 'Consultar a la IA'),
            ),
            if (_aiResponse != null) ...[
              const SizedBox(height: 16),
              const Text('Respuesta IA', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_aiResponse!),
                ),
              ),
            ] else
              const Spacer(),
            ElevatedButton(
              onPressed: _sendTicket,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text('Enviar ticket', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
