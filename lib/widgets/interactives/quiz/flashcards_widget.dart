import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/interactive_block.dart';
import '../../../../providers/course_provider.dart';

class FlashcardsWidget extends StatefulWidget {
  final InteractiveBlock block;
  const FlashcardsWidget({super.key, required this.block});

  @override
  State<FlashcardsWidget> createState() => _FlashcardsWidgetState();
}

class _FlashcardsWidgetState extends State<FlashcardsWidget> with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> cards;
  late final AnimationController _xpController;
  late final Animation<double> _xpOpacity;
  late final Animation<Offset> _xpOffset;

  @override
  void initState() {
    super.initState();
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _xpOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _xpController, curve: Curves.easeOut),
    );
    _xpOffset = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _xpController, curve: Curves.easeOut),
    );
    final rawCards = widget.block.content['cards'];
    if (rawCards is List) {
      cards = rawCards.map((card) => _normalizeCard(card)).toList();
    } else {
      cards = [];
    }
    widget.block.content['cards'] = cards;
  }

  Map<String, dynamic> _normalizeCard(dynamic card) {
    final map = (card is Map) ? card.cast<String, dynamic>() : <String, dynamic>{};
    final frontText = map['frontText'] ?? map['question'] ?? '';
    final backText = map['backText'] ?? map['answer'] ?? '';
    return {
      'frontText': frontText.toString(),
      'backText': backText.toString(),
      'frontImage': map['frontImage']?.toString() ?? '',
      'isFlipped': map['isFlipped'] == true,
    };
  }

  void _addCard() {
    setState(() {
      cards.add({
        'frontText': '',
        'backText': '',
        'frontImage': '',
        'isFlipped': false,
      });
      widget.block.content['cards'] = cards;
      widget.block.content['isCompleted'] = false;
    });
  }

  void _removeCard(int index) {
    setState(() {
      cards.removeAt(index);
      widget.block.content['cards'] = cards;
      _checkCompletion();
    });
  }

  void _toggleFlip(int index, bool flipped) {
    setState(() {
      cards[index]['isFlipped'] = flipped;
      widget.block.content['cards'] = cards;
      _checkCompletion();
    });
  }

  void _checkCompletion() {
    final allFlipped = cards.isNotEmpty && cards.every((card) => card['isFlipped'] == true);
    if (allFlipped) {
      widget.block.content['isCompleted'] = true;
      final alreadyEarned = widget.block.content['xpEarned'] == true;
      widget.block.content['xpEarned'] = true;
      widget.block.content['earnedXp'] = widget.block.content['xp'] ?? 0;
      if (!alreadyEarned) {
        _notifyCourseUpdate();
        _showXpAnimation();
      }
    } else {
      widget.block.content['isCompleted'] = false;
    }
  }

  void _showXpAnimation() {
    _xpController.forward(from: 0);
  }

  void _notifyCourseUpdate() {
    Future.microtask(() {
      if (!mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      final course = container.read(courseProvider);
      if (course != null) {
        container.read(courseProvider.notifier).setCourse(course);
      }
    });
  }

  @override
  void dispose() {
    _xpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.style),
            title: const Text("Mazo de Flashcards"),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addCard,
            ),
          ),
          if (cards.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Añade tarjetas para iniciar el mazo.'),
            ),
          if (cards.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final available = constraints.maxWidth;
                final cardWidth = (available >= 520) ? 220.0 : (available / 2) - 18;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Stack(
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: cards.asMap().entries.map((e) {
                          final index = e.key;
                          final card = e.value;
                          return _FlipCardTile(
                            key: ValueKey('flashcard_$index'),
                            width: cardWidth.clamp(160, 260),
                            frontText: card['frontText']?.toString() ?? '',
                            backText: card['backText']?.toString() ?? '',
                            frontImage: card['frontImage']?.toString() ?? '',
                            isFlipped: card['isFlipped'] == true,
                            onFlipChanged: (flipped) => _toggleFlip(index, flipped),
                          );
                        }).toList(),
                      ),
                      Positioned(
                        right: 6,
                        top: -4,
                        child: SlideTransition(
                          position: _xpOffset,
                          child: FadeTransition(
                            opacity: _xpOpacity,
                            child: _XpToast(value: widget.block.content['xp'] ?? 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const Divider(),
          ...cards.asMap().entries.map((e) => ExpansionTile(
            title: Text("Carta ${e.key + 1}"),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Texto del frente'),
                      controller: TextEditingController(text: e.value['frontText']),
                      onChanged: (v) {
                        e.value['frontText'] = v;
                        widget.block.content['cards'] = cards;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Texto del dorso'),
                      controller: TextEditingController(text: e.value['backText']),
                      onChanged: (v) {
                        e.value['backText'] = v;
                        widget.block.content['cards'] = cards;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Imagen frontal (opcional)'),
                      controller: TextEditingController(text: e.value['frontImage']),
                      onChanged: (v) {
                        e.value['frontImage'] = v;
                        widget.block.content['cards'] = cards;
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeCard(e.key),
                    )
                  ],
                ),
              )
            ],
          )).toList()
        ],
      ),
    );
  }
}

class _XpToast extends StatelessWidget {
  final Object value;
  const _XpToast({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade200,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '+$value XP',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _FlipCardTile extends StatefulWidget {
  final String frontText;
  final String backText;
  final String frontImage;
  final bool isFlipped;
  final ValueChanged<bool> onFlipChanged;
  final double width;

  const _FlipCardTile({
    super.key,
    required this.width,
    required this.frontText,
    required this.backText,
    required this.frontImage,
    required this.isFlipped,
    required this.onFlipChanged,
  });

  @override
  State<_FlipCardTile> createState() => _FlipCardTileState();
}

class _FlipCardTileState extends State<_FlipCardTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: widget.isFlipped ? 1.0 : 0.0,
    );
    _rotation = Tween<double>(begin: 0, end: 3.1415926535).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _FlipCardTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFlipped != widget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final next = !widget.isFlipped;
    widget.onFlipChanged(next);
    if (next) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _rotation,
        builder: (context, child) {
          final angle = _rotation.value;
          final isFront = angle <= 1.5707963267;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Container(
              width: widget.width,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: isFront ? _buildFront() : _buildBack(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.frontImage.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Icon(Icons.image_outlined, color: Colors.indigo.shade300),
            ),
          Text(
            widget.frontText.isEmpty ? 'Tap para ver' : widget.frontText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.1415926535),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          widget.backText.isEmpty ? 'Respuesta pendiente' : widget.backText,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }
}
