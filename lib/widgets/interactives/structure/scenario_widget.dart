import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/interactive_block.dart';
import '../../../../providers/course_provider.dart';

class ScenarioWidget extends StatefulWidget {
  final InteractiveBlock block;
  const ScenarioWidget({super.key, required this.block});

  @override
  State<ScenarioWidget> createState() => _ScenarioWidgetState();
}

enum _ScenarioPhase { prompt, feedback }

class _ScenarioWidgetState extends State<ScenarioWidget> {
  late String _introText;
  late String _imagePath;
  late List<Map<String, dynamic>> _options;
  bool _editMode = false;
  _ScenarioPhase _phase = _ScenarioPhase.prompt;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _introText = (widget.block.content['introText'] ?? 'Situacion a resolver').toString();
    _imagePath = (widget.block.content['imagePath'] ?? '').toString();
    _options = _normalizeOptions(widget.block.content['options']);
    widget.block.content['options'] = _options;
  }

  List<Map<String, dynamic>> _normalizeOptions(dynamic raw) {
    if (raw is! List || raw.isEmpty) {
      return [
        {
          'text': 'Tomar una decision prudente',
          'feedback': 'Buena eleccion: reduce riesgos.',
          'isCorrect': true,
          'bonusXP': 20,
        },
        {
          'text': 'Ignorar la señal',
          'feedback': 'Riesgo elevado. Revisa el protocolo.',
          'isCorrect': false,
          'bonusXP': 0,
        },
      ];
    }
    return raw.map((item) {
      final map = (item is Map) ? item.cast<String, dynamic>() : <String, dynamic>{};
      return {
        'text': (map['text'] ?? 'Opcion').toString(),
        'feedback': (map['feedback'] ?? '').toString(),
        'isCorrect': map['isCorrect'] == true,
        'bonusXP': (map['bonusXP'] is num) ? (map['bonusXP'] as num).toInt() : 0,
      };
    }).toList();
  }

  void _selectOption(int index) {
    final option = _options[index];
    final baseXp = widget.block.content['xp'] is num ? (widget.block.content['xp'] as num).toInt() : 0;
    final bonusXp = option['isCorrect'] == true ? (option['bonusXP'] as int? ?? 0) : 0;
    final earnedXp = baseXp + bonusXp;

    setState(() {
      _selectedIndex = index;
      _phase = _ScenarioPhase.feedback;
      widget.block.content['isCompleted'] = true;
      widget.block.content['xpEarned'] = true;
      widget.block.content['earnedXp'] = earnedXp;
      widget.block.content['selectedOption'] = index;
    });

    _notifyProgress(earnedXp);
  }

  void _toggleEditMode() {
    setState(() {
      _editMode = !_editMode;
    });
  }

  void _resetScenario() {
    setState(() {
      _phase = _ScenarioPhase.prompt;
      _selectedIndex = null;
      widget.block.content['isCompleted'] = false;
      widget.block.content['xpEarned'] = false;
      widget.block.content['earnedXp'] = 0;
    });
  }

  void _syncContent() {
    widget.block.content['introText'] = _introText;
    widget.block.content['imagePath'] = _imagePath;
    widget.block.content['options'] = _options;
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

  Color _accentForStyle() {
    final style = (widget.block.content['prompt'] ?? widget.block.content['style'] ?? '').toString().toLowerCase();
    if (style.contains('isometr')) return Colors.teal;
    if (style.contains('3d')) return Colors.deepPurple;
    if (style.contains('infografía') || style.contains('infografia')) return Colors.orange;
    return Colors.indigo;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForStyle();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 640;
            final imageWidget = _ScenarioAvatar(imagePath: _imagePath, accent: accent);
            final contentWidget = _buildContent(accent);
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: imageWidget),
                      const SizedBox(width: 16),
                      Expanded(child: contentWidget),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      imageWidget,
                      const SizedBox(height: 12),
                      contentWidget,
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _buildContent(Color accent) {
    final selected = _selectedIndex != null ? _options[_selectedIndex!] : null;
    final isCorrect = selected?['isCorrect'] == true;
    final feedbackColor = isCorrect ? Colors.green.shade600 : Colors.deepOrange.shade600;
    final hasMinimumOptions = _options.length >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Escenario', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: _phase == _ScenarioPhase.feedback ? _resetScenario : null,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Reiniciar escenario'),
            ),
            TextButton.icon(
              onPressed: _toggleEditMode,
              icon: Icon(_editMode ? Icons.visibility : Icons.edit, size: 18),
              label: Text(_editMode ? 'Vista' : 'Editar'),
            ),
          ],
        ),
        _editMode
            ? _ScenarioEditor(
                introText: _introText,
                imagePath: _imagePath,
                options: _options,
                onIntroChanged: (v) {
                  _introText = v;
                  _syncContent();
                },
                onImageChanged: (v) {
                  _imagePath = v;
                  _syncContent();
                },
                onOptionsChanged: (options) {
                  _options = options;
                  _syncContent();
                  setState(() {});
                },
                accent: accent,
              )
            : _SpeechBubble(text: _introText, accent: accent),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _phase == _ScenarioPhase.prompt
              ? (_editMode
                  ? Column(
                      key: const ValueKey('validation'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!hasMinimumOptions)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: const Text(
                              'Agrega al menos 2 opciones para activar el escenario.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    )
                  : (hasMinimumOptions
                      ? Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _options.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final option = entry.value;
                            return _OptionButton(
                              text: option['text']?.toString() ?? '',
                              accent: accent,
                              onPressed: () => _selectOption(idx),
                            );
                          }).toList(),
                        )
                      : Container(
                          key: const ValueKey('validation_view'),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: const Text(
                            'Agrega al menos 2 opciones para activar el escenario.',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        )))
              : Container(
                  key: const ValueKey('feedback'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: feedbackColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: feedbackColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(isCorrect ? Icons.check_circle : Icons.info_outline, color: feedbackColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selected?['feedback']?.toString() ?? 'Respuesta registrada.',
                          style: TextStyle(color: feedbackColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _ScenarioAvatar extends StatelessWidget {
  final String imagePath;
  final Color accent;

  const _ScenarioAvatar({
    required this.imagePath,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath.trim().isNotEmpty;
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(imagePath, fit: BoxFit.cover),
            )
          : Icon(Icons.person, size: 64, color: accent),
    );
  }
}

class _ScenarioEditor extends StatelessWidget {
  final String introText;
  final String imagePath;
  final List<Map<String, dynamic>> options;
  final ValueChanged<String> onIntroChanged;
  final ValueChanged<String> onImageChanged;
  final ValueChanged<List<Map<String, dynamic>>> onOptionsChanged;
  final Color accent;

  const _ScenarioEditor({
    required this.introText,
    required this.imagePath,
    required this.options,
    required this.onIntroChanged,
    required this.onImageChanged,
    required this.onOptionsChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'Planteamiento'),
          controller: TextEditingController(text: introText),
          maxLines: 2,
          onChanged: onIntroChanged,
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(labelText: 'URL imagen/avatar'),
          controller: TextEditingController(text: imagePath),
          onChanged: onImageChanged,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Opciones', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                final updated = [...options];
                updated.add({
                  'text': 'Nueva decision',
                  'feedback': '',
                  'isCorrect': false,
                  'bonusXP': 0,
                });
                onOptionsChanged(updated);
              },
              icon: Icon(Icons.add, color: accent),
              label: Text('Agregar', style: TextStyle(color: accent)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...options.asMap().entries.map((entry) {
          final idx = entry.key;
          final option = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0.5,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Decision ${idx + 1}'),
                    controller: TextEditingController(text: option['text']),
                    onChanged: (v) {
                      option['text'] = v;
                      onOptionsChanged(List<Map<String, dynamic>>.from(options));
                    },
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Feedback'),
                    controller: TextEditingController(text: option['feedback']),
                    onChanged: (v) {
                      option['feedback'] = v;
                      onOptionsChanged(List<Map<String, dynamic>>.from(options));
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Bonus XP'),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: option['bonusXP']?.toString() ?? '0'),
                          onChanged: (v) {
                            option['bonusXP'] = int.tryParse(v) ?? 0;
                            onOptionsChanged(List<Map<String, dynamic>>.from(options));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          const Text('Correcta', style: TextStyle(fontSize: 12)),
                          Switch(
                            value: option['isCorrect'] == true,
                            activeThumbColor: accent,
                            onChanged: (v) {
                              option['isCorrect'] = v;
                              onOptionsChanged(List<Map<String, dynamic>>.from(options));
                            },
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          final updated = [...options]..removeAt(idx);
                          onOptionsChanged(updated);
                        },
                      ),
                    ],
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

class _SpeechBubble extends StatelessWidget {
  final String text;
  final Color accent;

  const _SpeechBubble({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String text;
  final Color accent;
  final VoidCallback onPressed;

  const _OptionButton({
    required this.text,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        side: WidgetStateProperty.all(BorderSide(color: accent.withValues(alpha: 0.4))),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? accent.withValues(alpha: 0.08)
              : accent.withValues(alpha: 0.04),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: accent, fontWeight: FontWeight.w600),
      ),
    );
  }
}
