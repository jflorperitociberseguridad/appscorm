import 'package:flutter/material.dart';

class GamificationChatMessage {
  final String sender;
  final String text;
  final DateTime time;

  GamificationChatMessage({required this.sender, required this.text, required this.time});
}

enum CalendarEntryType { event, alarm }

class GamificationCalendarEntry {
  final String title;
  final CalendarEntryType type;

  const GamificationCalendarEntry({required this.title, required this.type});

  Map<String, dynamic> toMap() => {
        'title': title,
        'type': type.name,
      };

  factory GamificationCalendarEntry.fromMap(Map<String, dynamic> map) => GamificationCalendarEntry(
        title: map['title'] ?? '',
        type: map['type'] == 'alarm' ? CalendarEntryType.alarm : CalendarEntryType.event,
      );
}

class GamificationMilestone {
  final String title;
  final DateTime date;
  final IconData icon;

  const GamificationMilestone({required this.title, required this.date, required this.icon});
}

IconData gamificationIcon(String name) {
  switch (name) {
    case 'rocket':
      return Icons.rocket_launch;
    case 'flag':
    default:
      return Icons.flag;
  }
}
