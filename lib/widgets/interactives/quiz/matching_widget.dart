import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/interactive_block.dart';
import '../../../../providers/course_provider.dart';

class MatchingWidget extends StatefulWidget {
  final InteractiveBlock block;
  const MatchingWidget({super.key, required this.block});

  @override
  State<MatchingWidget> createState() => _MatchingWidgetState();
}

class _MatchingWidgetState extends State<MatchingWidget> with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _leftItems;
  late List<Map<String, dynamic>> _rightItems;
  final Set<int> _matchedLeftIds = {};
  final Set<int> _matchedRightIds = {};
  int? _selectedLeftId;
  int? _selectedRightId;
  int? _errorLeftId;
  int? _errorRightId;

  @override
  void initState() {
    super.initState();
    _leftItems = _normalizeLeftItems(widget.block.content['leftItems']);
    _rightItems = _normalizeRightItems(widget.block.content['rightItems'], _leftItems);
    widget.block.content['leftItems'] = _leftItems;
    widget.block.content['rightItems'] = _rightItems;
  }

  int _toId(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  List<Map<String, dynamic>> _normalizeLeftItems(dynamic raw) {
    if (raw is List && raw.isNotEmpty) {
      return raw.asMap().entries.map((entry) {
        final map = (entry.value is Map) ? (entry.value as Map).cast<String, dynamic>() : <String, dynamic>{};
        final id = _toId(map['id'], entry.key + 1);
        return {
          'id': id,
          'text': (map['text'] ?? map['label'] ?? 'Concepto ${entry.key + 1}').toString(),
        };
      }).toList();
    }
    return List.generate(3, (i) => {
          'id': i + 1,
          'text': 'Concepto ${i + 1}',
        });
  }

  List<Map<String, dynamic>> _normalizeRightItems(dynamic raw, List<Map<String, dynamic>> left) {
    if (raw is List && raw.isNotEmpty) {
      return raw.asMap().entries.map((entry) {
        final map = (entry.value is Map) ? (entry.value as Map).cast<String, dynamic>() : <String, dynamic>{};
        final fallbackId = entry.key < left.length ? left[entry.key]['id'] : entry.key + 1;
        final id = _toId(map['id'], fallbackId is int ? fallbackId : entry.key + 1);
        return {
          'id': id,
          'text': (map['text'] ?? map['label'] ?? 'Definicion ${entry.key + 1}').toString(),
        };
      }).toList();
    }
    return left
        .map((item) => {
              'id': item['id'],
              'text': 'Definicion de ${item['text']}',
            })
        .toList();
  }

  void _selectLeft(int id) {
    if (_matchedLeftIds.contains(id)) return;
    setState(() => _selectedLeftId = id);
    _tryMatch();
  }

  void _selectRight(int id) {
    if (_matchedRightIds.contains(id)) return;
    setState(() => _selectedRightId = id);
    _tryMatch();
  }

  void _tryMatch() {
    if (_selectedLeftId == null || _selectedRightId == null) return;
    if (_selectedLeftId == _selectedRightId) {
      setState(() {
        _matchedLeftIds.add(_selectedLeftId!);
        _matchedRightIds.add(_selectedRightId!);
        _selectedLeftId = null;
        _selectedRightId = null;
      });
      _checkCompletion();
      return;
    }
    setState(() {
      _errorLeftId = _selectedLeftId;
      _errorRightId = _selectedRightId;
      _selectedLeftId = null;
      _selectedRightId = null;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _errorLeftId = null;
        _errorRightId = null;
      });
    });
  }

  void _checkCompletion() {
    if (_matchedLeftIds.length != _leftItems.length) return;
    widget.block.content['isCompleted'] = true;
    final alreadyEarned = widget.block.content['xpEarned'] == true;
    widget.block.content['xpEarned'] = true;
    final rawXp = widget.block.content['xp'];
    final earned = rawXp is num ? rawXp.toInt() : int.tryParse(rawXp?.toString() ?? '') ?? 0;
    widget.block.content['earnedXp'] = earned;
    if (!alreadyEarned) {
      _notifyProgress(earned);
    }
  }

  void _notifyProgress(int earnedXp) {
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 620;
        final leftColumn = _buildColumn(
          title: 'Conceptos',
          items: _leftItems,
          selectedId: _selectedLeftId,
          errorId: _errorLeftId,
          matchedIds: _matchedLeftIds,
          onTap: _selectLeft,
          accent: Colors.indigo,
        );
        final rightColumn = _buildColumn(
          title: 'Definiciones',
          items: _rightItems,
          selectedId: _selectedRightId,
          errorId: _errorRightId,
          matchedIds: _matchedRightIds,
          onTap: _selectRight,
          accent: Colors.teal,
        );

        if (isStacked) {
          return Column(
            children: [
              leftColumn,
              const SizedBox(height: 12),
              rightColumn,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: leftColumn),
            const SizedBox(width: 12),
            Expanded(child: rightColumn),
          ],
        );
      },
    );
  }

  Widget _buildColumn({
    required String title,
    required List<Map<String, dynamic>> items,
    required int? selectedId,
    required int? errorId,
    required Set<int> matchedIds,
    required ValueChanged<int> onTap,
    required Color accent,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...items.map((item) {
              final id = item['id'] as int? ?? 0;
              final matched = matchedIds.contains(id);
              final selected = selectedId == id;
              final error = errorId == id;
              return _MatchTile(
                key: ValueKey('match_$id'),
                text: item['text']?.toString() ?? '',
                accent: accent,
                matched: matched,
                selected: selected,
                error: error,
                onTap: () => onTap(id),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MatchTile extends StatefulWidget {
  final String text;
  final Color accent;
  final bool matched;
  final bool selected;
  final bool error;
  final VoidCallback onTap;

  const _MatchTile({
    super.key,
    required this.text,
    required this.accent,
    required this.matched,
    required this.selected,
    required this.error,
    required this.onTap,
  });

  @override
  State<_MatchTile> createState() => _MatchTileState();
}

class _MatchTileState extends State<_MatchTile> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _MatchTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.error && widget.error) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey.shade300;
    Color fillColor = Colors.white;
    if (widget.matched) {
      borderColor = Colors.green.shade400;
      fillColor = Colors.green.shade50;
    } else if (widget.error) {
      borderColor = Colors.red.shade400;
      fillColor = Colors.red.shade50;
    } else if (widget.selected) {
      borderColor = widget.accent;
      fillColor = widget.accent.withValues(alpha: 0.08);
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final tick = (_shakeAnimation.value / 2).floor().isEven ? 1 : -1;
        final dx = widget.error ? _shakeAnimation.value * tick : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.matched ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.4),
            ),
            child: Row(
              children: [
                Expanded(child: Text(widget.text)),
                if (widget.matched) const Icon(Icons.check_circle, color: Colors.green, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
