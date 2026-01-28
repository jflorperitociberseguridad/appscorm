import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../models/interactive_block.dart';
import '../../../../providers/course_provider.dart';

class AudioWidget extends StatefulWidget {
  final InteractiveBlock block;
  const AudioWidget({super.key, required this.block});

  @override
  State<AudioWidget> createState() => _AudioWidgetState();
}

class _AudioWidgetState extends State<AudioWidget> {
  late TextEditingController _titleCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _authorCtrl;
  late final AudioPlayer _player;
  double _speed = 1.0;
  bool _earned = false;
  late final List<double> _wave;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.block.content['title'] ?? '');
    _urlCtrl = TextEditingController(text: widget.block.content['url'] ?? '');
    _authorCtrl = TextEditingController(text: widget.block.content['author'] ?? '');
    _player = AudioPlayer();
    _wave = List.generate(28, (i) => 0.3 + (i % 5) * 0.12);
    _initAudio();
  }

  Future<void> _initAudio() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    await _player.setUrl(url);
    _player.positionStream.listen((pos) {
      final dur = _player.duration;
      if (dur == null || dur.inMilliseconds == 0) return;
      final progress = pos.inMilliseconds / dur.inMilliseconds;
      if (progress >= 0.9 && !_earned) {
        _earned = true;
        _markCompleted();
      }
      if (mounted) setState(() {});
    });
  }

  void _save() {
    setState(() {
      widget.block.content['title'] = _titleCtrl.text;
      widget.block.content['url'] = _urlCtrl.text;
      widget.block.content['author'] = _authorCtrl.text;
    });
  }

  void _markCompleted() {
    widget.block.content['isCompleted'] = true;
    widget.block.content['xpEarned'] = true;
    final rawXp = widget.block.content['xp'];
    final earned = rawXp is num ? rawXp.toInt() : int.tryParse(rawXp?.toString() ?? '') ?? 0;
    widget.block.content['earnedXp'] = earned;
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(courseProvider.notifier).updateBlockProgress(
          widget.block.id,
          isCompleted: true,
          xpEarned: true,
          earnedXp: earned,
        );
  }

  @override
  void dispose() {
    _player.dispose();
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final duration = _player.duration ?? Duration.zero;
    final position = _player.position;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                  ),
                  child: Icon(Icons.podcasts, color: accent, size: 36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(labelText: 'Título del Audio'),
                        onChanged: (_) => _save(),
                      ),
                      TextField(
                        controller: _authorCtrl,
                        decoration: const InputDecoration(labelText: 'Autor'),
                        onChanged: (_) => _save(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL del archivo MP3',
                hintText: 'https://ejemplo.com/audio.mp3',
              ),
              onChanged: (_) => _save(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  iconSize: 40,
                  icon: Icon(
                    _player.playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: accent,
                  ),
                  onPressed: () {
                    if (_player.playing) {
                      _player.pause();
                    } else {
                      _player.play();
                    }
                    setState(() {});
                  },
                ),
                Expanded(
                  child: Column(
                    children: [
                      Slider(
                        value: progress.clamp(0.0, 1.0),
                        activeColor: accent,
                        inactiveColor: accent.withValues(alpha: 0.2),
                        onChanged: (v) {
                          final seek = duration * v;
                          _player.seek(seek);
                        },
                      ),
                      SizedBox(
                        height: 26,
                        child: Row(
                          children: _wave
                              .map((amp) => Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      height: max(6, amp * 20),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<double>(
                  value: _speed,
                  items: const [
                    DropdownMenuItem(value: 1.0, child: Text('1x')),
                    DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                    DropdownMenuItem(value: 2.0, child: Text('2x')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _speed = value);
                    _player.setSpeed(value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
