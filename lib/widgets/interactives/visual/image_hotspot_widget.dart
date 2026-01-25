import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/interactive_block.dart';
import '../../../../providers/course_provider.dart';

class ImageHotspotWidget extends StatefulWidget {
  final InteractiveBlock block;

  const ImageHotspotWidget({super.key, required this.block});

  @override
  State<ImageHotspotWidget> createState() => _ImageHotspotWidgetState();
}

class _ImageHotspotWidgetState extends State<ImageHotspotWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late List<Map<String, dynamic>> _hotspots;
  bool _editMode = false;
  bool _snapToGrid = false;
  static const double _gridStep = 5;
  int _nextHotspotId = 1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: false);
    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeOut);
    _hotspots = _normalizeHotspots(widget.block.content['hotspots']);
    widget.block.content['hotspots'] = _hotspots;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _normalizeHotspots(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((item) {
      final map = (item is Map) ? item.cast<String, dynamic>() : <String, dynamic>{};
      final dx = _toPercent(map['dx'] ?? map['x'] ?? 50);
      final dy = _toPercent(map['dy'] ?? map['y'] ?? 50);
      final id = map['id'] ?? _nextHotspotId++;
      return {
        'id': id,
        'dx': dx,
        'dy': dy,
        'title': (map['title'] ?? map['text'] ?? 'Punto clave').toString(),
        'description': (map['description'] ?? map['detail'] ?? '').toString(),
        'isVisited': map['isVisited'] == true,
        'isRemoving': false,
      };
    }).toList();
  }

  double _toPercent(dynamic value) {
    if (value is num) {
      return value.clamp(0, 100).toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value) ?? 50;
      return parsed.clamp(0, 100).toDouble();
    }
    return 50;
  }

  void _markVisited(int index) {
    setState(() {
      _hotspots[index]['isVisited'] = true;
      widget.block.content['hotspots'] = _hotspots;
      _checkCompletion();
    });
  }

  void _checkCompletion() {
    final allVisited = _hotspots.isNotEmpty && _hotspots.every((h) => h['isVisited'] == true);
    if (allVisited) {
      widget.block.content['isCompleted'] = true;
      final alreadyEarned = widget.block.content['xpEarned'] == true;
      widget.block.content['xpEarned'] = true;
      final rawXp = widget.block.content['xp'];
      final earned = rawXp is num ? rawXp.toInt() : int.tryParse(rawXp?.toString() ?? '') ?? 0;
      widget.block.content['earnedXp'] = earned;
      if (!alreadyEarned) {
        _notifyCourseUpdate(earned);
      }
    } else {
      widget.block.content['isCompleted'] = false;
    }
  }

  void _notifyCourseUpdate(int earnedXp) {
    Future.microtask(() {
      if (!mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(courseProvider.notifier).updateBlockProgress(
            widget.block.id,
            isCompleted: true,
            xpEarned: true,
            earnedXp: earnedXp,
          );
    });
  }

  void _addHotspot(double dxPercent, double dyPercent) {
    setState(() {
      _hotspots.add({
        'id': _nextHotspotId++,
        'dx': _snapValue(dxPercent),
        'dy': _snapValue(dyPercent),
        'title': 'Nuevo punto',
        'description': '',
        'isVisited': false,
        'isRemoving': false,
      });
      widget.block.content['hotspots'] = _hotspots;
    });
  }

  void _updateHotspotPosition(int index, double dxPercent, double dyPercent) {
    setState(() {
      _hotspots[index]['dx'] = _snapValue(dxPercent);
      _hotspots[index]['dy'] = _snapValue(dyPercent);
      widget.block.content['hotspots'] = _hotspots;
    });
  }

  void _removeHotspot(int hotspotId) {
    final index = _hotspots.indexWhere((h) => h['id'] == hotspotId);
    if (index == -1) return;
    final removed = Map<String, dynamic>.from(_hotspots[index]);
    setState(() {
      _hotspots[index]['isRemoving'] = true;
      widget.block.content['hotspots'] = _hotspots;
      _checkCompletion();
    });
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      final currentIndex = _hotspots.indexWhere((h) => h['id'] == hotspotId);
      if (currentIndex == -1) return;
      setState(() {
        _hotspots.removeAt(currentIndex);
        widget.block.content['hotspots'] = _hotspots;
        _checkCompletion();
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Hotspot eliminado'),
        duration: const Duration(milliseconds: 1200),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () {
            setState(() {
              final existingIndex = _hotspots.indexWhere((h) => h['id'] == hotspotId);
              if (existingIndex == -1) {
                final insertIndex = index.clamp(0, _hotspots.length);
                _hotspots.insert(insertIndex, removed);
              } else {
                _hotspots[existingIndex]['isRemoving'] = false;
              }
              widget.block.content['hotspots'] = _hotspots;
              _checkCompletion();
            });
          },
        ),
      ),
    );
  }

  double _snapValue(double value) {
    if (!_snapToGrid) return value;
    final snapped = (value / _gridStep).round() * _gridStep;
    return snapped.clamp(0, 100);
  }

  Future<void> _openHotspotEditor(int index, Color accent) async {
    final hotspot = _hotspots[index];
    final titleController = TextEditingController(text: hotspot['title'] ?? '');
    final descController = TextEditingController(text: hotspot['description'] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar hotspot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Titulo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descripcion'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('delete'),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: Text('Guardar', style: TextStyle(color: accent)),
          ),
        ],
      ),
    );
    if (result == 'save') {
      setState(() {
        hotspot['title'] = titleController.text.trim();
        hotspot['description'] = descController.text.trim();
        widget.block.content['hotspots'] = _hotspots;
      });
    } else if (result == 'delete') {
      _removeHotspot(hotspot['id'] as int);
    }
    titleController.dispose();
    descController.dispose();
  }

  Color _accentForStyle() {
    final style = (widget.block.content['prompt'] ?? widget.block.content['style'] ?? '').toString().toLowerCase();
    if (style.contains('isometr')) return Colors.teal;
    if (style.contains('3d')) return Colors.deepPurple;
    if (style.contains('infografía') || style.contains('infografia')) return Colors.orange;
    if (style.contains('boceto')) return Colors.brown;
    if (style.contains('diagrama')) return Colors.blueGrey;
    return Colors.indigo;
  }

  Future<void> _openHotspotDialog(Map<String, dynamic> hotspot, Color accent) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(hotspot['title'] ?? 'Detalle'),
          content: Text(hotspot['description'] ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, color: accent, fontSize: 16),
          contentTextStyle: const TextStyle(fontSize: 13, color: Colors.black87),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.block.content['url'] ?? 'https://placehold.co/1200x800';
    final caption = widget.block.content['caption']?.toString();
    final accent = _accentForStyle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const Icon(Icons.edit_location_alt_outlined, size: 18),
              const SizedBox(width: 6),
              const Text('Modo edicion de hotspots', style: TextStyle(fontSize: 12)),
              const Spacer(),
              IconButton(
                icon: Icon(_snapToGrid ? Icons.grid_on : Icons.grid_off, color: accent),
                tooltip: _snapToGrid ? 'Alinear a grilla' : 'Grilla desactivada',
                onPressed: () => setState(() => _snapToGrid = !_snapToGrid),
              ),
              Switch(
                value: _editMode,
                onChanged: (value) => setState(() => _editMode = value),
                activeColor: accent,
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = width / (16 / 9);
            return AspectRatio(
              aspectRatio: 16 / 9,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: _editMode
                    ? (details) {
                        final local = details.localPosition;
                        final dx = (local.dx / width) * 100;
                        final dy = (local.dy / height) * 100;
                        _addHotspot(dx.clamp(0, 100), dy.clamp(0, 100));
                      }
                    : null,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        url,
                        width: constraints.maxWidth,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    ..._hotspots.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final spot = entry.value;
                      final dx = (spot['dx'] as num?)?.toDouble() ?? 50;
                      final dy = (spot['dy'] as num?)?.toDouble() ?? 50;
                      return Positioned(
                        left: (dx / 100) * width - 14,
                        top: (dy / 100) * height - 14,
                        child: GestureDetector(
                          onPanUpdate: _editMode
                              ? (details) {
                                  final newDx = ((dx / 100) * width + details.delta.dx) / width * 100;
                                  final newDy = ((dy / 100) * height + details.delta.dy) / height * 100;
                                  _updateHotspotPosition(
                                    idx,
                                    newDx.clamp(0, 100),
                                    newDy.clamp(0, 100),
                                  );
                                }
                              : null,
                          onLongPress: _editMode ? () => _removeHotspot(spot['id'] as int) : null,
                          onTap: () async {
                            if (_editMode) {
                              await _openHotspotEditor(idx, accent);
                            } else {
                              await _openHotspotDialog(spot, accent);
                              _markVisited(idx);
                            }
                          },
                          child: AnimatedOpacity(
                            opacity: spot['isRemoving'] == true ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 220),
                            child: AnimatedScale(
                              scale: spot['isRemoving'] == true ? 0.6 : 1.0,
                              duration: const Duration(milliseconds: 220),
                              child: _HotspotDot(
                                accent: accent,
                                visited: spot['isVisited'] == true,
                                pulse: _pulseAnimation,
                                onTap: () {},
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
        if (caption != null && caption.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              caption,
              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _HotspotDot extends StatelessWidget {
  final Color accent;
  final bool visited;
  final Animation<double> pulse;
  final VoidCallback onTap;

  const _HotspotDot({
    required this.accent,
    required this.visited,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final scale = 1 + (pulse.value * 0.6);
          final opacity = (1 - pulse.value).clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: opacity * 0.5,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: accent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  visited ? Icons.check : Icons.add,
                  size: 16,
                  color: accent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
