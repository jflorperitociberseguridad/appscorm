import 'package:flutter/material.dart';

class GamificationProgressPanel extends StatelessWidget {
  final double progress;
  final Duration studyDuration;
  final int xpTotal;

  const GamificationProgressPanel({
    super.key,
    required this.progress,
    required this.studyDuration,
    required this.xpTotal,
  });

  String get _progressLabel {
    if (progress >= 1.0) return 'Completado';
    if (progress >= 0.75) return 'Casi alli';
    if (progress >= 0.5) return 'Avanzado';
    if (progress >= 0.25) return 'En progreso';
    return 'Inicio';
  }

  String get _durationLabel {
    final hours = studyDuration.inHours;
    final minutes = studyDuration.inMinutes.remainder(60);
    final seconds = studyDuration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progreso del Curso', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              color: const Color(0xFF2563EB),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$percent% completado', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text(_progressLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiempo de estudio', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text(_durationLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('XP obtenida', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text('$xpTotal XP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
