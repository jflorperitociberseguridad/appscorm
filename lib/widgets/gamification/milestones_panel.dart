import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'models.dart';

class GamificationMilestonesPanel extends StatelessWidget {
  final List<GamificationMilestone> milestones;

  const GamificationMilestonesPanel({super.key, required this.milestones});

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Proximos Hitos', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: milestones.map((m) {
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(m.icon, color: const Color(0xFF2563EB), size: 18),
                ),
                title: Text(m.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  DateFormat.yMMMd().format(m.date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
