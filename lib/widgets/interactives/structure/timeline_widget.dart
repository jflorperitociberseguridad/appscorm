import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/interactive_block.dart';
import '../../../../providers/course_provider.dart';

enum TimelineStyle { minimal, detailed, alternating }

class TimelineWidget extends StatefulWidget {
  final InteractiveBlock block;
  const TimelineWidget({super.key, required this.block});

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  late List<Map<String, dynamic>> events;
  late TimelineStyle _style;
  bool _editMode = false;
  final List<GlobalKey> _eventKeys = [];
  final Set<int> _revealed = {};
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    events = _normalizeEvents(widget.block.content['events']);
    _style = _parseStyle(widget.block.content['style']);
    widget.block.content['events'] = events;
    widget.block.content['style'] = _style.name;
    _eventKeys.addAll(List.generate(events.length, (_) => GlobalKey()));
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  List<Map<String, dynamic>> _normalizeEvents(dynamic raw) {
    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) {
        final map = (item is Map) ? item.cast<String, dynamic>() : <String, dynamic>{};
        return {
          'label': (map['label'] ?? map['date'] ?? '').toString(),
          'title': (map['title'] ?? 'Evento').toString(),
          'description': (map['description'] ?? map['desc'] ?? '').toString(),
          'icon': map['icon'] ?? Icons.flag_outlined.codePoint,
        };
      }).toList();
    }
    return [
      {
        'label': 'Fase 1',
        'title': 'Inicio',
        'description': 'Se activa el proceso.',
        'icon': Icons.flag_outlined.codePoint,
      },
      {
        'label': 'Fase 2',
        'title': 'Ejecucion',
        'description': 'Se completan los pasos criticos.',
        'icon': Icons.timeline.codePoint,
      },
      {
        'label': 'Fase 3',
        'title': 'Cierre',
        'description': 'Se evaluan resultados.',
        'icon': Icons.check_circle_outline.codePoint,
      },
    ];
  }

  TimelineStyle _parseStyle(dynamic raw) {
    switch (raw?.toString().toLowerCase()) {
      case 'minimal':
        return TimelineStyle.minimal;
      case 'alternating':
        return TimelineStyle.alternating;
      case 'detailed':
      default:
        return TimelineStyle.detailed;
    }
  }

  IconData _iconForEvent(Map<String, dynamic> event) {
    final raw = event['icon'];
    if (raw is int) {
      return IconData(raw, fontFamily: 'MaterialIcons');
    }
    if (raw is String) {
      final lower = raw.toLowerCase();
      if (lower.contains('flag')) return Icons.flag_outlined;
      if (lower.contains('check')) return Icons.check_circle_outline;
      if (lower.contains('info')) return Icons.info_outline;
      if (lower.contains('star')) return Icons.star_outline;
    }
    return Icons.flag_outlined;
  }

  void _checkVisibility() {
    if (!mounted) return;
    final screenHeight = MediaQuery.of(context).size.height;
    for (var i = 0; i < _eventKeys.length; i++) {
      final ctx = _eventKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox) continue;
      final position = box.localToGlobal(Offset.zero);
      if (position.dy < screenHeight - 120) {
        if (_revealed.add(i)) {
          setState(() {});
        }
      }
    }

    final lastIndex = _eventKeys.length - 1;
    if (lastIndex >= 0 && _revealed.contains(lastIndex) && !_completed) {
      _completed = true;
      _markCompleted();
    }
  }

  void _markCompleted() {
    widget.block.content['isCompleted'] = true;
    final alreadyEarned = widget.block.content['xpEarned'] == true;
    widget.block.content['xpEarned'] = true;
    final rawXp = widget.block.content['xp'];
    final earned = rawXp is num ? rawXp.toInt() : int.tryParse(rawXp?.toString() ?? '') ?? 0;
    widget.block.content['earnedXp'] = earned;
    if (!alreadyEarned) {
      Future.microtask(() {
        if (!mounted) return;
        final container = ProviderScope.containerOf(context, listen: false);
        container.read(courseProvider.notifier).updateBlockProgress(
              widget.block.id,
              isCompleted: true,
              xpEarned: true,
              earnedXp: earned,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          _checkVisibility();
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 640;
          final style = (_style == TimelineStyle.alternating && isMobile)
              ? TimelineStyle.detailed
              : _style;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.timeline),
                title: const Text("Linea de tiempo"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<TimelineStyle>(
                      value: _style,
                      underline: Container(
                        height: 1,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _style = value;
                          widget.block.content['style'] = _style.name;
                        });
                      },
                      items: TimelineStyle.values
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.name),
                              ))
                          .toList(),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _editMode = !_editMode),
                      icon: Icon(_editMode ? Icons.visibility : Icons.edit, size: 18),
                      label: Text(_editMode ? 'Vista' : 'Editar'),
                    ),
                  ],
                ),
              ),
              if (_editMode)
                _TimelineEditor(
                  events: events,
                  accent: Theme.of(context).colorScheme.primary,
                  onEventsChanged: (updated) {
                    setState(() {
                      events = updated;
                      widget.block.content['events'] = events;
                      _eventKeys
                        ..clear()
                        ..addAll(List.generate(events.length, (_) => GlobalKey()));
                      _revealed.clear();
                      _completed = false;
                    });
                  },
                )
              else
                _buildTimeline(style),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeline(TimelineStyle style) {
    final accent = Theme.of(context).colorScheme.primary;
    if (style == TimelineStyle.minimal) {
      return _MinimalTimeline(
        events: events,
        keys: _eventKeys,
        revealed: _revealed,
        iconForEvent: _iconForEvent,
        accent: accent,
      );
    }
    if (style == TimelineStyle.alternating) {
      return _AlternatingTimeline(
        events: events,
        keys: _eventKeys,
        revealed: _revealed,
        iconForEvent: _iconForEvent,
        accent: accent,
      );
    }
    return _DetailedTimeline(
      events: events,
      keys: _eventKeys,
      revealed: _revealed,
      iconForEvent: _iconForEvent,
      accent: accent,
    );
  }
}

class _MinimalTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final List<GlobalKey> keys;
  final Set<int> revealed;
  final IconData Function(Map<String, dynamic>) iconForEvent;
  final Color accent;

  const _MinimalTimeline({
    required this.events,
    required this.keys,
    required this.revealed,
    required this.iconForEvent,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: events.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final visible = revealed.contains(index);
        return _TimelineRow(
          key: keys[index],
          label: event['label']?.toString() ?? '',
          title: event['title']?.toString() ?? '',
          description: event['description']?.toString() ?? '',
          icon: iconForEvent(event),
          accent: accent,
          cardStyle: _TimelineCardStyle.minimal,
          visible: visible,
          alignLeft: true,
        );
      }).toList(),
    );
  }
}

class _DetailedTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final List<GlobalKey> keys;
  final Set<int> revealed;
  final IconData Function(Map<String, dynamic>) iconForEvent;
  final Color accent;

  const _DetailedTimeline({
    required this.events,
    required this.keys,
    required this.revealed,
    required this.iconForEvent,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: events.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final visible = revealed.contains(index);
        return _TimelineRow(
          key: keys[index],
          label: event['label']?.toString() ?? '',
          title: event['title']?.toString() ?? '',
          description: event['description']?.toString() ?? '',
          icon: iconForEvent(event),
          accent: accent,
          cardStyle: _TimelineCardStyle.card,
          visible: visible,
          alignLeft: true,
        );
      }).toList(),
    );
  }
}

class _AlternatingTimeline extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final List<GlobalKey> keys;
  final Set<int> revealed;
  final IconData Function(Map<String, dynamic>) iconForEvent;
  final Color accent;

  const _AlternatingTimeline({
    required this.events,
    required this.keys,
    required this.revealed,
    required this.iconForEvent,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: events.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final visible = revealed.contains(index);
        final alignLeft = index.isEven;
        return _TimelineRow(
          key: keys[index],
          label: event['label']?.toString() ?? '',
          title: event['title']?.toString() ?? '',
          description: event['description']?.toString() ?? '',
          icon: iconForEvent(event),
          accent: accent,
          cardStyle: _TimelineCardStyle.card,
          visible: visible,
          alignLeft: alignLeft,
        );
      }).toList(),
    );
  }
}

enum _TimelineCardStyle { minimal, card }

class _TimelineRow extends StatelessWidget {
  final String label;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final _TimelineCardStyle cardStyle;
  final bool visible;
  final bool alignLeft;

  const _TimelineRow({
    super.key,
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.cardStyle,
    required this.visible,
    required this.alignLeft,
  });

  @override
  Widget build(BuildContext context) {
    final card = _TimelineCard(
      label: label,
      title: title,
      description: description,
      icon: icon,
      accent: accent,
      style: cardStyle,
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: visible ? 1 : 0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(width: 2, height: 12, color: Colors.grey.shade300),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 1.2),
                    ),
                    child: Icon(icon, size: 14, color: accent),
                  ),
                  Container(width: 2, height: 48, color: Colors.grey.shade300),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: alignLeft
                  ? card
                  : Row(
                      children: [
                        const Expanded(child: SizedBox()),
                        Expanded(child: card),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final String label;
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final _TimelineCardStyle style;

  const _TimelineCard({
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final isMinimal = style == _TimelineCardStyle.minimal;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMinimal ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: isMinimal
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Text(label, style: TextStyle(fontSize: 12, color: accent)),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (description.isNotEmpty)
            MarkdownBody(
              data: description,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(height: 1.4),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineEditor extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final Color accent;
  final ValueChanged<List<Map<String, dynamic>>> onEventsChanged;

  const _TimelineEditor({
    required this.events,
    required this.accent,
    required this.onEventsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              final updated = [...events];
              updated.add({
                'label': 'Fase ${updated.length + 1}',
                'title': 'Nuevo hito',
                'description': '',
                'icon': Icons.flag_outlined.codePoint,
              });
              onEventsChanged(updated);
            },
            icon: Icon(Icons.add, color: accent),
            label: Text('Agregar hito', style: TextStyle(color: accent)),
          ),
        ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;
            final updated = [...events];
            final item = updated.removeAt(oldIndex);
            updated.insert(newIndex, item);
            onEventsChanged(updated);
          },
          children: [
            for (int idx = 0; idx < events.length; idx++)
              Card(
                key: ValueKey('timeline_event_$idx'),
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.drag_handle, size: 18),
                          const SizedBox(width: 6),
                          Text('Hito ${idx + 1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Etiqueta'),
                        controller: TextEditingController(text: events[idx]['label']?.toString() ?? ''),
                        onChanged: (v) {
                          events[idx]['label'] = v;
                          onEventsChanged(List<Map<String, dynamic>>.from(events));
                        },
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Titulo'),
                        controller: TextEditingController(text: events[idx]['title']?.toString() ?? ''),
                        onChanged: (v) {
                          events[idx]['title'] = v;
                          onEventsChanged(List<Map<String, dynamic>>.from(events));
                        },
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Descripcion (Markdown)'),
                        controller: TextEditingController(text: events[idx]['description']?.toString() ?? ''),
                        maxLines: 3,
                        onChanged: (v) {
                          events[idx]['description'] = v;
                          onEventsChanged(List<Map<String, dynamic>>.from(events));
                        },
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('Icono', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          PopupMenuButton<IconData>(
                            tooltip: 'Cambiar icono',
                            icon: Icon(
                              _iconFrom(events[idx]['icon']),
                              color: accent,
                            ),
                            onSelected: (icon) {
                              events[idx]['icon'] = icon.codePoint;
                              onEventsChanged(List<Map<String, dynamic>>.from(events));
                            },
                            itemBuilder: (context) => _timelineIconOptions
                                .map((opt) => PopupMenuItem(
                                      value: opt,
                                      child: Row(
                                        children: [
                                          Icon(opt, size: 18, color: accent),
                                          const SizedBox(width: 8),
                                          Text(_timelineIconLabel(opt)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              final updated = [...events]..removeAt(idx);
                              onEventsChanged(updated);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  IconData _iconFrom(dynamic raw) {
    if (raw is int) return IconData(raw, fontFamily: 'MaterialIcons');
    return Icons.flag_outlined;
  }
}

const List<IconData> _timelineIconOptions = [
  Icons.flag_outlined,
  Icons.timeline,
  Icons.check_circle_outline,
  Icons.lightbulb_outline,
  Icons.info_outline,
  Icons.star_outline,
  Icons.school_outlined,
];

String _timelineIconLabel(IconData icon) {
  if (icon == Icons.flag_outlined) return 'Bandera';
  if (icon == Icons.timeline) return 'Timeline';
  if (icon == Icons.check_circle_outline) return 'Check';
  if (icon == Icons.lightbulb_outline) return 'Idea';
  if (icon == Icons.info_outline) return 'Info';
  if (icon == Icons.star_outline) return 'Estrella';
  if (icon == Icons.school_outlined) return 'Aprendizaje';
  return 'Icono';
}
