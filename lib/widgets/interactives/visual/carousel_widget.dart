import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/interactive_block.dart';
import '../../../../providers/course_provider.dart';
import '../interactive_block_modes.dart';

class CarouselWidget extends StatefulWidget {
  final InteractiveBlock block;
  final InteractiveBlockMode mode;
  final ValueChanged<BlockContentChanged>? onContentChanged;

  const CarouselWidget({
    super.key,
    required this.block,
    this.mode = InteractiveBlockMode.interactive,
    this.onContentChanged,
  });

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  late List<Map<String, dynamic>> _items;
  late final PageController _pageController;
  late final TextEditingController _xpController;
  final List<_SlideEditors> _slideEditors = [];
  int _currentIndex = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _items = _normalizeItems(widget.block.content['items']);
    widget.block.content['items'] = _items;
    _pageController = PageController();
    _xpController = TextEditingController(text: widget.block.content['xp']?.toString() ?? '');
    _prepareEditorControllers();
    if (_items.length <= 1) {
      _maybeComplete(0);
    }
  }

  @override
  void didUpdateWidget(covariant CarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content) {
      _items = _normalizeItems(widget.block.content['items']);
      widget.block.content['items'] = _items;
      _prepareEditorControllers();
      _xpController.text = widget.block.content['xp']?.toString() ?? '';
      if (_items.length <= 1) {
        _maybeComplete(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _xpController.dispose();
    for (final editor in _slideEditors) {
      editor.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _normalizeItems(dynamic raw) {
    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) {
        final map = (item is Map) ? item.cast<String, dynamic>() : <String, dynamic>{};
        return {
          'imageUrl': (map['imageUrl'] ?? map['url'] ?? map['front'] ?? '').toString(),
          'title': (map['title'] ?? map['caption'] ?? '').toString(),
          'description': (map['description'] ?? map['back'] ?? '').toString(),
        };
      }).toList();
    }
    return [
      {
        'imageUrl': '',
        'title': 'Diapositiva 1',
        'description': 'Descripcion del recurso.',
      },
    ];
  }

  void _prepareEditorControllers() {
    for (final editor in _slideEditors) {
      editor.dispose();
    }
    _slideEditors
      ..clear()
      ..addAll(_items.map((map) => _SlideEditors(map)));
  }

  Map<String, dynamic> _currentContent() {
    final content = Map<String, dynamic>.from(widget.block.content);
    content['items'] = _items.map((item) => Map<String, dynamic>.from(item)).toList();
    final xpParsed = int.tryParse(_xpController.text);
    content['xp'] = xpParsed ?? _xpController.text;
    return content;
  }

  void _notifyContentChanged() {
    if (widget.onContentChanged == null) return;
    widget.onContentChanged!(BlockContentChanged(_currentContent()));
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Carrusel vacio'),
        ),
      );
    }

    if (widget.mode == InteractiveBlockMode.interactive) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildPageView(),
              if (_items.length > 1) _buildPaginationDots(),
            ],
          ),
        ),
      );
    }

    return _buildEditingInterface();
  }

  Widget _buildPageView() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _items.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                _maybeComplete(index);
              },
              itemBuilder: (context, index) {
                final item = _items[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(item['imageUrl']?.toString() ?? ''),
                    if ((item['title'] ?? '').toString().trim().isNotEmpty ||
                        (item['description'] ?? '').toString().trim().isNotEmpty)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((item['title'] ?? '').toString().trim().isNotEmpty)
                                Text(
                                  item['title'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if ((item['description'] ?? '').toString().trim().isNotEmpty)
                                MarkdownBody(
                                  data: item['description'].toString(),
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(color: Colors.white70, height: 1.3),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            if (_items.length > 1)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () => _goTo(_currentIndex - 1),
                ),
              ),
            if (_items.length > 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () => _goTo(_currentIndex + 1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationDots() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_items.length, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentIndex == index ? 14 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentIndex == index ? Colors.indigo : Colors.indigo.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEditingInterface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _xpController,
          decoration: const InputDecoration(
            labelText: 'XP total',
            hintText: 'Número entero',
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => _notifyContentChanged(),
        ),
        const SizedBox(height: 12),
        ..._items.asMap().entries.map((entry) => _buildSlideEditor(entry.key, entry.value)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _addSlide,
            icon: const Icon(Icons.add),
            label: const Text('Agregar diapositiva'),
          ),
        ),
      ],
    );
  }

  Widget _buildSlideEditor(int index, Map<String, dynamic> slide) {
    final controllers = _slideEditors[index];
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Diapositiva ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeSlide(index),
                ),
              ],
            ),
            TextFormField(
              controller: controllers.imageUrl,
              decoration: const InputDecoration(labelText: 'URL de la imagen'),
              onChanged: (value) => _updateSlideField(index, 'imageUrl', value),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controllers.title,
              decoration: const InputDecoration(labelText: 'Título'),
              onChanged: (value) => _updateSlideField(index, 'title', value),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controllers.description,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
              onChanged: (value) => _updateSlideField(index, 'description', value),
            ),
          ],
        ),
      ),
    );
  }

  void _addSlide() {
    setState(() {
      _items.add({
        'imageUrl': '',
        'title': 'Nueva diapositiva',
        'description': '',
      });
      _prepareEditorControllers();
    });
    _notifyContentChanged();
  }

  void _removeSlide(int index) {
    setState(() {
      _items.removeAt(index);
      _prepareEditorControllers();
    });
    _notifyContentChanged();
  }

  void _updateSlideField(int index, String key, String value) {
    _items[index][key] = value;
    _notifyContentChanged();
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return Container(
        color: Colors.black12,
        child: const Center(child: Icon(Icons.image, size: 48, color: Colors.black38)),
      );
    }
    if (url.startsWith('data:')) {
      try {
        final data = base64Decode(url.split(',').last);
        return Image.memory(data, fit: BoxFit.cover);
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image));
      }
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
    );
  }

  void _maybeComplete(int index) {
    if (_items.isEmpty || index != _items.length - 1 || _completed) return;
    _completed = true;
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

  void _goTo(int index) {
    if (index < 0 || index >= _items.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }
}

class _SlideEditors {
  final TextEditingController imageUrl;
  final TextEditingController title;
  final TextEditingController description;

  _SlideEditors(Map<String, dynamic> slide)
      : imageUrl = TextEditingController(text: slide['imageUrl']?.toString() ?? ''),
        title = TextEditingController(text: slide['title']?.toString() ?? ''),
        description = TextEditingController(text: slide['description']?.toString() ?? '');

  void dispose() {
    imageUrl.dispose();
    title.dispose();
    description.dispose();
  }
}
