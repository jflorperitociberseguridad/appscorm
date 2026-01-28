import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../models/interactive_block.dart';

enum AccordionStyle { standard, minimal, boxed, iconized }

class AccordionWidget extends StatefulWidget {
  final InteractiveBlock block;
  const AccordionWidget({super.key, required this.block});

  @override
  State<AccordionWidget> createState() => _AccordionWidgetState();
}

class _AccordionWidgetState extends State<AccordionWidget> with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _items;
  late bool _exclusive;
  late AccordionStyle _style;

  @override
  void initState() {
    super.initState();
    _items = _normalizeItems(widget.block.content['items']);
    _exclusive = widget.block.content['exclusive'] == true;
    _style = _parseStyle(widget.block.content['style']);
    widget.block.content['items'] = _items;
    widget.block.content['exclusive'] = _exclusive;
    widget.block.content['style'] = _style.name;
  }

  List<Map<String, dynamic>> _normalizeItems(dynamic raw) {
    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) {
        final map = (item is Map) ? item.cast<String, dynamic>() : <String, dynamic>{};
        return {
          'title': (map['title'] ?? 'Seccion').toString(),
          'content': (map['content'] ?? map['text'] ?? 'Contenido...').toString(),
          'icon': map['icon'],
          'expanded': map['expanded'] == true,
        };
      }).toList();
    }
    return [
      {
        'title': 'Seccion 1',
        'content': 'Contenido del acordeon...',
        'icon': Icons.info_outline.codePoint,
        'expanded': false,
      },
      {
        'title': 'Seccion 2',
        'content': 'Mas informacion...',
        'icon': Icons.tips_and_updates_outlined.codePoint,
        'expanded': false,
      },
    ];
  }

  AccordionStyle _parseStyle(dynamic value) {
    final raw = value?.toString().toLowerCase();
    switch (raw) {
      case 'minimal':
        return AccordionStyle.minimal;
      case 'boxed':
        return AccordionStyle.boxed;
      case 'iconized':
        return AccordionStyle.iconized;
      case 'standard':
      default:
        return AccordionStyle.standard;
    }
  }

  void _toggle(int index) {
    setState(() {
      if (_exclusive) {
        for (var i = 0; i < _items.length; i++) {
          _items[i]['expanded'] = i == index ? !(_items[i]['expanded'] == true) : false;
        }
      } else {
        _items[index]['expanded'] = !(_items[index]['expanded'] == true);
      }
      widget.block.content['items'] = _items;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AccordionControls(
          style: _style,
          exclusive: _exclusive,
          accent: accent,
          onStyleChanged: (style) {
            setState(() {
              _style = style;
              widget.block.content['style'] = _style.name;
            });
          },
          onExclusiveChanged: (value) {
            setState(() {
              _exclusive = value;
              widget.block.content['exclusive'] = value;
            });
          },
        ),
        const SizedBox(height: 8),
        ...List.generate(_items.length, (index) {
          final item = _items[index];
          final expanded = item['expanded'] == true;
          return _AccordionItem(
            title: item['title']?.toString() ?? '',
            content: item['content']?.toString() ?? '',
            icon: _style == AccordionStyle.iconized ? _iconFrom(item['icon']) : null,
            expanded: expanded,
            style: _style,
            accent: accent,
            onTap: () => _toggle(index),
            onIconChanged: _style == AccordionStyle.iconized
                ? (icon) {
                    setState(() {
                      item['icon'] = icon.codePoint;
                      widget.block.content['items'] = _items;
                    });
                  }
                : null,
          );
        }),
      ],
    );
  }

  IconData? _iconFrom(dynamic raw) {
    if (raw is int) {
      return IconData(raw, fontFamily: 'MaterialIcons');
    }
    return Icons.circle_outlined;
  }
}

class _AccordionItem extends StatelessWidget {
  final String title;
  final String content;
  final IconData? icon;
  final bool expanded;
  final AccordionStyle style;
  final Color accent;
  final VoidCallback onTap;
  final ValueChanged<IconData>? onIconChanged;

  const _AccordionItem({
    required this.title,
    required this.content,
    required this.icon,
    required this.expanded,
    required this.style,
    required this.accent,
    required this.onTap,
    this.onIconChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMinimal = style == AccordionStyle.minimal;
    final isBoxed = style == AccordionStyle.boxed;
    final isStandard = style == AccordionStyle.standard;

    final baseDecoration = BoxDecoration(
      color: isStandard ? accent.withValues(alpha: 0.06) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
      boxShadow: isBoxed
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ]
          : null,
    );

    final itemDecoration = isMinimal
        ? BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          )
        : baseDecoration;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: itemDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: accent),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.w600, color: accent),
                      ),
                    ),
                    if (onIconChanged != null)
                      PopupMenuButton<IconData>(
                        tooltip: 'Cambiar icono',
                        icon: Icon(Icons.edit, color: accent, size: 18),
                        onSelected: onIconChanged,
                        itemBuilder: (context) => _iconOptions
                            .map(
                              (opt) => PopupMenuItem(
                                value: opt,
                                child: Row(
                                  children: [
                                    Icon(opt, size: 18, color: accent),
                                    const SizedBox(width: 8),
                                    Text(_iconLabel(opt)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: accent,
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  child: expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: MarkdownBody(
                            data: content,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(height: 1.4),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccordionControls extends StatelessWidget {
  final AccordionStyle style;
  final bool exclusive;
  final Color accent;
  final ValueChanged<AccordionStyle> onStyleChanged;
  final ValueChanged<bool> onExclusiveChanged;

  const _AccordionControls({
    required this.style,
    required this.exclusive,
    required this.accent,
    required this.onStyleChanged,
    required this.onExclusiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('Estilo', style: TextStyle(fontWeight: FontWeight.w600)),
        DropdownButton<AccordionStyle>(
          value: style,
          underline: Container(height: 1, color: accent.withValues(alpha: 0.3)),
          items: AccordionStyle.values
              .map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.name),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) onStyleChanged(value);
          },
        ),
        const SizedBox(width: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: exclusive,
              onChanged: onExclusiveChanged,
              activeThumbColor: accent,
            ),
            const Text('Exclusivo', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}

const List<IconData> _iconOptions = [
  Icons.info_outline,
  Icons.lightbulb_outline,
  Icons.bookmark_border,
  Icons.check_circle_outline,
  Icons.school_outlined,
  Icons.settings_outlined,
  Icons.star_border,
];

String _iconLabel(IconData icon) {
  if (icon == Icons.info_outline) return 'Info';
  if (icon == Icons.lightbulb_outline) return 'Idea';
  if (icon == Icons.bookmark_border) return 'Marcador';
  if (icon == Icons.check_circle_outline) return 'Check';
  if (icon == Icons.school_outlined) return 'Aprendizaje';
  if (icon == Icons.settings_outlined) return 'Ajustes';
  if (icon == Icons.star_border) return 'Destacado';
  return 'Icono';
}
