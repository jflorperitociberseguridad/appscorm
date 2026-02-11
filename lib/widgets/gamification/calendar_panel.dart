import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/course_model.dart';
import 'models.dart';

class GamificationCalendarPanel extends StatefulWidget {
  final CourseModel? course;

  const GamificationCalendarPanel({super.key, required this.course});

  @override
  State<GamificationCalendarPanel> createState() => _GamificationCalendarPanelState();
}

class _GamificationCalendarPanelState extends State<GamificationCalendarPanel> {
  DateTime _visibleMonth = DateTime.now();
  DateTime? _selectedDate;
  final Map<String, List<GamificationCalendarEntry>> _calendarEntries = {};
  String? _activeCourseId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.course != null) {
        _loadCourseData(widget.course!);
      }
    });
  }

  @override
  void didUpdateWidget(covariant GamificationCalendarPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.course != null && widget.course!.id != _activeCourseId) {
      _loadCourseData(widget.course!);
    }
  }

  void _scheduleSetState(VoidCallback fn) {
    if (mounted) {
      Future.microtask(() => setState(fn));
    }
  }

  Future<void> _loadCourseData(CourseModel course) async {
    _activeCourseId = course.id;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_calendarKey(course.id));
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _calendarEntries
        ..clear()
        ..addAll(decoded.map((key, value) {
          final list = (value as List).map((e) => GamificationCalendarEntry.fromMap(Map<String, dynamic>.from(e))).toList();
          return MapEntry(key, list);
        }));
    }
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

  void _selectDate(DateTime date) {
    _scheduleSetState(() {
      _selectedDate = date;
    });
  }

  DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  int _daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;
  int _startWeekday(DateTime d) => _firstOfMonth(d).weekday % 7;
  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _openDayDialog(DateTime date) async {
    final key = _dateKey(date);
    final entries = _calendarEntries[key] ?? [];
    final titleController = TextEditingController();
    CalendarEntryType selectedType = CalendarEntryType.event;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agenda · ${DateFormat('dd MMM yyyy').format(date)}'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('No hay eventos registrados.', style: TextStyle(color: Colors.grey)),
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
                        leading: Icon(entry.type == CalendarEntryType.event ? Icons.event : Icons.alarm),
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
                  labelText: 'Nueva tarea o alarma',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CalendarEntryType>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: CalendarEntryType.event, child: Text('Evento')),
                  DropdownMenuItem(value: CalendarEntryType.alarm, child: Text('Alarma')),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ElevatedButton(
            onPressed: () {
              final text = titleController.text.trim();
              if (text.isNotEmpty) {
                _scheduleSetState(() {
                  final updated = [...entries, GamificationCalendarEntry(title: text, type: selectedType)];
                  _calendarEntries[key] = updated;
                });
                _persistCalendar();
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    titleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat.yMMMM().format(_visibleMonth);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFFEFEFF),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _buildCalendarGrid(),
          const SizedBox(height: 8),
          if (_selectedDate != null)
            Text('Seleccionado: ${DateFormat.yMMMd().format(_selectedDate!)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final startWeekday = _startWeekday(_visibleMonth);
    final totalDays = _daysInMonth(_visibleMonth);

    final cells = <Widget>[];
    const weekDays = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];
    for (var wd in weekDays) {
      cells.add(Center(child: Text(wd, style: const TextStyle(fontSize: 11, color: Colors.grey))));
    }

    for (int i = 0; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      final selected = _selectedDate != null &&
          date.year == _selectedDate!.year &&
          date.month == _selectedDate!.month &&
          date.day == _selectedDate!.day;
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

  String _calendarKey(String courseId) => 'calendar_entries_$courseId';
}
