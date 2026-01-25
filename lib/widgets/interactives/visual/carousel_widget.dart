import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/interactive_block.dart';
import '../../../../providers/course_provider.dart';

class CarouselWidget extends StatefulWidget {
  final InteractiveBlock block;
  const CarouselWidget({super.key, required this.block});

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  late List<Map<String, dynamic>> _items;
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _items = _normalizeItems(widget.block.content['items']);
    widget.block.content['items'] = _items;
    _pageController = PageController();
    if (_items.length <= 1) {
      _maybeComplete(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    if (_items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Carrusel vacio'),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            AspectRatio(
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
                                        Colors.black.withOpacity(0.65),
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
                          onPressed: _currentIndex == 0 ? null : () => _goTo(_currentIndex - 1),
                        ),
                      ),
                    if (_items.length > 1)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                          onPressed: _currentIndex == _items.length - 1
                              ? null
                              : () => _goTo(_currentIndex + 1),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_items.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentIndex == index ? 18 : 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index ? accent : Colors.black26,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
