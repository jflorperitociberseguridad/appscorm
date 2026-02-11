import 'package:flutter/material.dart';

import '../../models/course_model.dart';
import 'support_screen.dart';

class GamificationSupportPanel extends StatelessWidget {
  final CourseModel? course;

  const GamificationSupportPanel({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SupportScreen(course: course)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.headset_mic, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Servicio Tecnico de Cibermedia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Centro de ayuda y IA', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              splashRadius: 20,
            )
          ],
        ),
      ),
    );
  }
}
