import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/interactive_block.dart';
import '../../../../providers/course_provider.dart';

enum TabsStyle { classic, pills, vertical }

class TabsWidget extends StatefulWidget {
  final InteractiveBlock block;
  const TabsWidget({super.key, required this.block});

  @override
  State<TabsWidget> createState() => _TabsWidgetState();
}

class _TabsWidgetState extends State<TabsWidget> {
  late List<Map<String, dynamic>> _tabs;
  late TabsStyle _style;
  late Set<int> _visited;
  int _currentIndex = 0;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _tabs = _normalizeTabs(widget.block.content['tabs']);
    _style = _parseStyle(widget.block.content['style']);
    _visited = _normalizeVisited(widget.block.content['visited']);
    widget.block.content['tabs'] = _tabs;
    widget.block.content['style'] = _style.name;
    widget.block.content['visited'] = _visited.toList();
    if (_tabs.isNotEmpty) {
      _markVisited(0);
    }
  }

  List<Map<String, dynamic>> _normalizeTabs(dynamic raw) {
    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) {
        final map = (item is Map) ? item.cast<String, dynamic>() : <String, dynamic>{};
        return {
          'title': (map['title'] ?? 'Pestana').toString(),
          'content': (map['content'] ?? map['text'] ?? '').toString(),
          'icon': map['icon'],
        };
      }).toList();
    }
    return [
      {'title': 'Pestana 1', 'content': 'Contenido de la pestana 1.', 'icon': Icons.info_outline.codePoint},
      {'title': 'Pestana 2', 'content': 'Contenido de la pestana 2.', 'icon': Icons.star_outline.codePoint},
    ];
  }

  TabsStyle _parseStyle(dynamic raw) {
    final value = raw?.toString() ?? '';
    return TabsStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => TabsStyle.classic,
    );
  }

  Set<int> _normalizeVisited(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => int.tryParse(e.toString()) ?? -1).where((e) => e >= 0).toSet();
    }
    return <int>{};
  }

  IconData _iconFrom(dynamic raw) {
    if (raw is int) return IconData(raw, fontFamily: 'MaterialIcons');
    if (raw is String) {
      final value = int.tryParse(raw);
      if (value != null) return IconData(value, fontFamily: 'MaterialIcons');
    }
    return Icons.info_outline;
  }

  void _markVisited(int index) {
    _visited.add(index);
    widget.block.content['visited'] = _visited.toList();
    if (_visited.length == _tabs.length) {
      _completeBlock();
    }
  }

  void _completeBlock() {
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

  void _selectTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() {
      _currentIndex = index;
      _markVisited(index);
    });
  }

  void _addTab() {
    setState(() {
      _tabs.add({
        'title': 'Nueva Pestana',
        'content': '',
        'icon': Icons.info_outline.codePoint,
      });
      widget.block.content['tabs'] = _tabs;
    });
  }

  void _removeTab(int index) {
    setState(() {
      _tabs.removeAt(index);
      widget.block.content['tabs'] = _tabs;
      _visited = _visited.where((id) => id < _tabs.length).toSet();
      widget.block.content['visited'] = _visited.toList();
      if (_currentIndex >= _tabs.length) {
        _currentIndex = (_tabs.length - 1).clamp(0, _tabs.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    if (_tabs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Añade pestanas para empezar.'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final style = _style;
        final showInlineContent = style == TabsStyle.vertical && !isCompact;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Pestanas', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    DropdownButton<TabsStyle>(
                      value: _style,
                      items: TabsStyle.values
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s == TabsStyle.classic
                                  ? 'Classic'
                                  : s == TabsStyle.pills
                                      ? 'Pills'
                                      : 'Vertical'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _style = value;
                          widget.block.content['style'] = value.name;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: _editMode ? 'Vista' : 'Editar',
                      icon: Icon(_editMode ? Icons.visibility : Icons.edit),
                      onPressed: () => setState(() => _editMode = !_editMode),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTabsBar(style, accent, isCompact),
                if (!showInlineContent) ...[
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: _buildTabContent(_tabs[_currentIndex], accent, key: ValueKey(_currentIndex)),
                  ),
                ],
                if (_editMode) ...[
                  const Divider(height: 28),
                  _buildEditor(accent),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabsBar(TabsStyle style, Color accent, bool isCompact) {
    if (style == TabsStyle.vertical && !isCompact) {
      return SizedBox(
        height: 220,
        child: Row(
          children: [
            SizedBox(
              width: 180,
              child: ListView.builder(
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  final selected = _currentIndex == index;
                  return ListTile(
                    dense: true,
                    leading: Icon(_iconFrom(_tabs[index]['icon']), color: selected ? accent : Colors.black54),
                    title: Text(
                      _tabs[index]['title'].toString(),
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? accent : Colors.black87,
                      ),
                    ),
                    onTap: () => _selectTab(index),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: _buildTabContent(_tabs[_currentIndex], accent, key: ValueKey(_currentIndex)),
              ),
            ),
          ],
        ),
      );
    }

    if (_style == TabsStyle.vertical && isCompact) {
      return DropdownButton<int>(
        value: _currentIndex,
        items: _tabs
            .asMap()
            .entries
            .map((entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(_iconFrom(entry.value['icon']), size: 18),
                      const SizedBox(width: 8),
                      Text(entry.value['title'].toString()),
                    ],
                  ),
                ))
            .toList(),
        onChanged: (index) {
          if (index == null) return;
          _selectTab(index);
        },
      );
    }

    final isPills = style == TabsStyle.pills;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final selected = _currentIndex == index;
          final child = Row(
            children: [
              Icon(
                _iconFrom(tab['icon']),
                size: 16,
                color: selected ? Colors.white : accent,
              ),
              const SizedBox(width: 6),
              Text(tab['title'].toString()),
            ],
          );
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _selectTab(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? accent : (isPills ? accent.withOpacity(0.12) : Colors.transparent),
                  borderRadius: BorderRadius.circular(isPills ? 999 : 12),
                  border: Border.all(color: selected ? accent : accent.withOpacity(0.4)),
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      child,
                      if (!isPills)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(top: 6),
                          height: 3,
                          width: selected ? 24 : 0,
                          decoration: BoxDecoration(
                            color: selected ? accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> tab, Color accent, {required Key key}) {
    final content = tab['content']?.toString() ?? '';
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: MarkdownBody(
        data: content.isEmpty ? 'Sin contenido.' : content,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(height: 1.4),
        ),
      ),
    );
  }

  Widget _buildEditor(Color accent) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Editor de pestanas', style: TextStyle(fontWeight: FontWeight.w600)),
            IconButton(
              onPressed: _addTab,
              icon: Icon(Icons.add_circle, color: accent),
              tooltip: 'Agregar pestana',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      PopupMenuButton<IconData>(
                        tooltip: 'Icono',
                        icon: Icon(_iconFrom(tab['icon']), color: accent),
                        onSelected: (icon) {
                          setState(() {
                            tab['icon'] = icon.codePoint;
                            widget.block.content['tabs'] = _tabs;
                          });
                        },
                        itemBuilder: (context) => _tabIconOptions
                            .map(
                              (icon) => PopupMenuItem(
                                value: icon,
                                child: Row(
                                  children: [
                                    Icon(icon, size: 18, color: accent),
                                    const SizedBox(width: 8),
                                    Text(_tabIconLabel(icon)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Titulo'),
                          controller: TextEditingController(text: tab['title']),
                          onChanged: (v) {
                            tab['title'] = v;
                            widget.block.content['tabs'] = _tabs;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeTab(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Contenido (Markdown)'),
                    maxLines: 3,
                    controller: TextEditingController(text: tab['content']),
                    onChanged: (v) {
                      tab['content'] = v;
                      widget.block.content['tabs'] = _tabs;
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

const List<IconData> _tabIconOptions = [
  Icons.info_outline,
  Icons.star_outline,
  Icons.book_outlined,
  Icons.lightbulb_outline,
  Icons.school_outlined,
  Icons.flag_outlined,
  Icons.list_alt_outlined,
];

String _tabIconLabel(IconData icon) {
  if (icon == Icons.info_outline) return 'Info';
  if (icon == Icons.star_outline) return 'Estrella';
  if (icon == Icons.book_outlined) return 'Libro';
  if (icon == Icons.lightbulb_outline) return 'Idea';
  if (icon == Icons.school_outlined) return 'Aprendizaje';
  if (icon == Icons.flag_outlined) return 'Bandera';
  if (icon == Icons.list_alt_outlined) return 'Lista';
  return 'Icono';
}
