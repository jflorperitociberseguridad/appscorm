import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/interactive_block.dart';
import '../../../../providers/course_provider.dart';

enum ComparisonStyle { versus, table, slider }

class ComparisonWidget extends StatefulWidget {
  final InteractiveBlock block;
  const ComparisonWidget({super.key, required this.block});
  @override
  State<ComparisonWidget> createState() => _ComparisonWidgetState();
}

class _ComparisonWidgetState extends State<ComparisonWidget> {
  late Map<String, dynamic> _itemA;
  late Map<String, dynamic> _itemB;
  late ComparisonStyle _style;
  late Set<int> _visitedA;
  late Set<int> _visitedB;
  double _sliderValue = 0.5;
  bool _sliderMoved = false;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _itemA = _normalizeItem(widget.block.content['itemA'], 'Item A');
    _itemB = _normalizeItem(widget.block.content['itemB'], 'Item B');
    _style = _parseStyle(widget.block.content['comparisonStyle']);
    _visitedA = _normalizeVisited(widget.block.content['visitedA']);
    _visitedB = _normalizeVisited(widget.block.content['visitedB']);
    _sliderValue = (widget.block.content['sliderValue'] is num)
        ? (widget.block.content['sliderValue'] as num).toDouble().clamp(0.1, 0.9)
        : 0.5;
    _sliderMoved = widget.block.content['sliderMoved'] == true;
    widget.block.content['itemA'] = _itemA;
    widget.block.content['itemB'] = _itemB;
    widget.block.content['comparisonStyle'] = _style.name;
    widget.block.content['visitedA'] = _visitedA.toList();
    widget.block.content['visitedB'] = _visitedB.toList();
    widget.block.content['sliderValue'] = _sliderValue;
    widget.block.content['sliderMoved'] = _sliderMoved;
  }

  Map<String, dynamic> _normalizeItem(dynamic raw, String fallbackTitle) {
    final map = (raw is Map) ? raw.cast<String, dynamic>() : <String, dynamic>{};
    final features = map['features'];
    final list = (features is List)
        ? features.map((e) => e.toString()).toList()
        : <String>['Punto clave 1', 'Punto clave 2', 'Punto clave 3'];
    return {
      'title': (map['title'] ?? fallbackTitle).toString(),
      'subtitle': (map['subtitle'] ?? '').toString(),
      'image': (map['image'] ?? '').toString(),
      'features': list,
    };
  }

  ComparisonStyle _parseStyle(dynamic raw) {
    final value = raw?.toString() ?? '';
    return ComparisonStyle.values.firstWhere(
      (style) => style.name == value,
      orElse: () => ComparisonStyle.versus,
    );
  }

  Set<int> _normalizeVisited(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => int.tryParse(e.toString()) ?? -1).where((e) => e >= 0).toSet();
    }
    return <int>{};
  }

  void _markVisited(bool isA, int index) {
    setState(() {
      if (isA) {
        _visitedA.add(index);
        widget.block.content['visitedA'] = _visitedA.toList();
      } else {
        _visitedB.add(index);
        widget.block.content['visitedB'] = _visitedB.toList();
      }
      _checkCompletion();
    });
  }

  void _updateSlider(double value) {
    setState(() {
      _sliderValue = value.clamp(0.1, 0.9);
      _sliderMoved = true;
      widget.block.content['sliderValue'] = _sliderValue;
      widget.block.content['sliderMoved'] = _sliderMoved;
      _checkCompletion();
    });
  }

  void _checkCompletion() {
    final totalA = (_itemA['features'] as List).length;
    final totalB = (_itemB['features'] as List).length;
    final visitedAll = _visitedA.length >= totalA && _visitedB.length >= totalB;
    final sliderOk = _style != ComparisonStyle.slider || _sliderMoved;
    if (!visitedAll || !sliderOk) return;
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
    final accent = Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final style = _style;
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
                    const Icon(Icons.compare_arrows),
                    const SizedBox(width: 8),
                    const Text('Comparacion', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    DropdownButton<ComparisonStyle>(
                      value: _style,
                      items: ComparisonStyle.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s == ComparisonStyle.versus
                                    ? 'Versus'
                                    : s == ComparisonStyle.table
                                        ? 'Table'
                                        : 'Slider'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _style = value;
                          widget.block.content['comparisonStyle'] = value.name;
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
                const SizedBox(height: 12),
                if (style == ComparisonStyle.slider)
                  _buildSliderView(accent, isCompact)
                else if (style == ComparisonStyle.table)
                  _buildTableView(accent, isCompact)
                else
                  _buildVersusView(accent, isCompact),
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

  Widget _buildVersusView(Color accent, bool isCompact) {
    final left = _buildItemCard(_itemA, accent, true);
    final right = _buildItemCard(_itemB, accent, false);
    if (isCompact) {
      return Column(
        children: [
          left,
          const SizedBox(height: 12),
          right,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: left),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
        ),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, Color accent, bool isA) {
    final features = (item['features'] as List).cast<String>();
    final image = item['image']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item['title'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
          if ((item['subtitle'] ?? '').toString().trim().isNotEmpty)
            Text(item['subtitle'].toString(), style: const TextStyle(color: Colors.black54)),
          if (image.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  image,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 140,
                    child: Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features.asMap().entries.map((entry) {
              final index = entry.key;
              final visited = isA ? _visitedA.contains(index) : _visitedB.contains(index);
              return GestureDetector(
                onTap: () => _markVisited(isA, index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: visited ? accent : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: visited ? Colors.white : Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(Color accent, bool isCompact) {
    final featuresA = (_itemA['features'] as List).cast<String>();
    final featuresB = (_itemB['features'] as List).cast<String>();
    final rows = featuresA.length > featuresB.length ? featuresA.length : featuresB.length;
    final header = Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(_itemA['title'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(_itemB['title'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    final body = Column(
      children: List.generate(rows, (index) {
        final aText = index < featuresA.length ? featuresA[index] : '';
        final bText = index < featuresB.length ? featuresB[index] : '';
        final aVisited = _visitedA.contains(index);
        final bVisited = _visitedB.contains(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: aText.isEmpty ? null : () => _markVisited(true, index),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: aVisited ? accent.withValues(alpha: 0.18) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(aText, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: bText.isEmpty ? null : () => _markVisited(false, index),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: bVisited ? accent.withValues(alpha: 0.18) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(bText, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );

    if (isCompact) {
      return Column(
        children: [
          header,
          const SizedBox(height: 8),
          body,
        ],
      );
    }
    return Column(
      children: [
        header,
        const SizedBox(height: 8),
        body,
      ],
    );
  }

  Widget _buildSliderView(Color accent, bool isCompact) {
    final imageA = _itemA['image']?.toString() ?? '';
    final imageB = _itemB['image']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageA.isEmpty || imageB.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Añade imagenes en ambos items para activar el slider.'),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final height = isCompact ? 200.0 : 260.0;
              final width = constraints.maxWidth;
              return GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final local = details.localPosition.dx;
                  _updateSlider(local / width);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(
                        imageA,
                        height: height,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          height: 200,
                          child: Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: _sliderValue,
                          child: Image.network(
                            imageB,
                            height: height,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      Positioned(
                        left: _sliderValue * width - 12,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            border: Border.all(color: accent),
                          ),
                          child: Icon(Icons.drag_handle, color: accent),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        _buildVersusView(accent, isCompact),
      ],
    );
  }

  Widget _buildEditor(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildItemEditor(_itemA, 'Item A', accent, true),
        const SizedBox(height: 12),
        _buildItemEditor(_itemB, 'Item B', accent, false),
      ],
    );
  }

  Widget _buildItemEditor(Map<String, dynamic> item, String label, Color accent, bool isA) {
    final features = (item['features'] as List).cast<String>();
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Titulo'),
              controller: TextEditingController(text: item['title']),
              onChanged: (v) {
                item['title'] = v;
                widget.block.content[isA ? 'itemA' : 'itemB'] = item;
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Subtitulo'),
              controller: TextEditingController(text: item['subtitle']),
              onChanged: (v) {
                item['subtitle'] = v;
                widget.block.content[isA ? 'itemA' : 'itemB'] = item;
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Imagen (URL)'),
              controller: TextEditingController(text: item['image']),
              onChanged: (v) {
                item['image'] = v;
                widget.block.content[isA ? 'itemA' : 'itemB'] = item;
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Features', style: TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  icon: Icon(Icons.add_circle, color: accent),
                  onPressed: () {
                    setState(() {
                      features.add('Nuevo punto');
                      widget.block.content[isA ? 'itemA' : 'itemB'] = item;
                    });
                  },
                ),
              ],
            ),
            ...features.asMap().entries.map((entry) {
              final index = entry.key;
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Punto'),
                      controller: TextEditingController(text: entry.value),
                      onChanged: (v) {
                        features[index] = v;
                        widget.block.content[isA ? 'itemA' : 'itemB'] = item;
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        features.removeAt(index);
                        widget.block.content[isA ? 'itemA' : 'itemB'] = item;
                      });
                    },
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
