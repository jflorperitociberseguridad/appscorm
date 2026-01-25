import 'package:flutter/material.dart';

class ChipOption {
  final String label;
  final IconData icon;

  const ChipOption({required this.label, required this.icon});
}

class GuideStepData {
  final String index;
  final String text;

  const GuideStepData({required this.index, required this.text});
}

class GuideStep extends StatelessWidget {
  final String index;
  final String text;

  const GuideStep({super.key, required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFF0F172A),
          child: Text(index, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
        ),
      ],
    );
  }
}

class WelcomeCard extends StatelessWidget {
  final List<GuideStepData> steps;

  const WelcomeCard({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFE0E7FF), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Guía de inicio",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < steps.length; i++) ...[
              GuideStep(index: steps[i].index, text: steps[i].text),
              if (i < steps.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
      ),
    );
  }
}

class SliderLabel extends StatelessWidget {
  final String label;
  final int value;

  const SliderLabel({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Text("$value", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        ),
      ],
    );
  }
}

class SegmentedControl extends StatelessWidget {
  final List<String> options;
  final String current;
  final ValueChanged<String> onChanged;

  const SegmentedControl({
    super.key,
    required this.options,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt == current;
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          onSelected: (_) => onChanged(opt),
          selectedColor: const Color(0xFF6200EE),
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
    );
  }
}

class IconChoiceChips extends StatelessWidget {
  final List<ChipOption> options;
  final String current;
  final ValueChanged<String> onChanged;

  const IconChoiceChips({
    super.key,
    required this.options,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = opt.label == current;
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(opt.icon, size: 16, color: isSelected ? Colors.white : Colors.black54),
              const SizedBox(width: 6),
              Text(opt.label),
            ],
          ),
          selected: isSelected,
          onSelected: (_) => onChanged(opt.label),
          selectedColor: const Color(0xFF6200EE),
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
    );
  }
}

class FilterChips extends StatelessWidget {
  final List<ChipOption> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt.label);
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(opt.icon, size: 16, color: isSelected ? Colors.white : Colors.black54),
              const SizedBox(width: 6),
              Text(opt.label),
            ],
          ),
          selected: isSelected,
          onSelected: (_) {
            final next = List<String>.from(selected);
            if (isSelected) {
              next.remove(opt.label);
            } else {
              next.add(opt.label);
            }
            onChanged(next);
          },
          selectedColor: const Color(0xFF0F766E),
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
    );
  }
}

class PassScoreSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const PassScoreSlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (value >= 85) {
      color = const Color(0xFF059669);
      label = "Exigente";
    } else if (value >= 70) {
      color = const Color(0xFF0EA5E9);
      label = "Estándar";
    } else {
      color = const Color(0xFFF97316);
      label = "Flexible";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Text("${value.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: 50,
          max: 100,
          divisions: 10,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class InteractionDensitySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const InteractionDensitySlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("0", style: TextStyle(color: Color(0xFF475569))),
            Text(value.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text("12", style: TextStyle(color: Color(0xFF475569))),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 12,
          divisions: 12,
          activeColor: const Color(0xFF0F766E),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class PercentageSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final Color activeColor;
  final String lowLabel;
  final String highLabel;

  const PercentageSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    required this.lowLabel,
    required this.highLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(lowLabel, style: const TextStyle(color: Color(0xFF475569))),
            Text("${value.toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, color: activeColor)),
            Text(highLabel, style: const TextStyle(color: Color(0xFF475569))),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 10,
          activeColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class CommitIntervalSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const CommitIntervalSlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final seconds = value.toInt();
    final minutes = (seconds / 60).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("30 seg", style: TextStyle(color: Color(0xFF475569))),
            Text(
              seconds < 60 ? "$seconds seg" : "$minutes min",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text("5 min", style: TextStyle(color: Color(0xFF475569))),
          ],
        ),
        Slider(
          value: value,
          min: 30,
          max: 300,
          divisions: 9,
          activeColor: const Color(0xFF4B5563),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class DataDensitySlider extends StatelessWidget {
  final double value;
  final String label;
  final bool enabled;
  final ValueChanged<double>? onChanged;

  const DataDensitySlider({
    super.key,
    required this.value,
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Solo estados", style: TextStyle(color: Color(0xFF475569))),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text("Big Data", style: TextStyle(color: Color(0xFF475569))),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 4,
          activeColor: const Color(0xFF7C3AED),
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

class SwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

class AiAssistanceSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const AiAssistanceSlider({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Fiel al texto (0% invención)", style: TextStyle(color: Color(0xFF475569))),
            Text("${value.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text("Creatividad total (ejemplos externos)", style: TextStyle(color: Color(0xFF475569))),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 10,
          activeColor: const Color(0xFF7C3AED),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class PedagogicalDescription extends StatelessWidget {
  final String model;

  const PedagogicalDescription({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    String description;
    switch (model) {
      case 'Micro-Learning':
        description = 'Contenido atómico y directo.';
        break;
      case 'Inmersivo':
        description = 'Explicaciones profundas y narrativas.';
        break;
      case 'Capacitativo':
        description = 'Mucho contenido y muchos casos prácticos.';
        break;
      case 'Ejercitativo':
        description = 'Muchas tareas y ejercicios interactivos.';
        break;
      case 'Practicum':
        description = 'Simulación y aplicación directa.';
        break;
      default:
        description = 'Modelo personalizado.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(description, style: const TextStyle(color: Color(0xFF475569))),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.25),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF6200EE)),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text("Esto puede tardar unos segundos", style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class CreationOptionSets {
  static const List<ChipOption> introApproachOptions = [
    ChipOption(label: 'Motivacional', icon: Icons.local_fire_department),
    ChipOption(label: 'Analítico (Datos)', icon: Icons.query_stats),
    ChipOption(label: 'Basado en Casos Reales', icon: Icons.fact_check),
    ChipOption(label: 'Provocativo (Reto)', icon: Icons.emoji_events),
    ChipOption(label: 'Narrativo (Storytelling)', icon: Icons.auto_stories),
  ];

  static const List<ChipOption> conceptMapOptions = [
    ChipOption(label: 'Jerárquico', icon: Icons.account_tree),
    ChipOption(label: 'Mapa Mental Visual', icon: Icons.bubble_chart),
    ChipOption(label: 'Índice Estructurado', icon: Icons.list_alt),
    ChipOption(label: 'Diagrama de Flujo', icon: Icons.schema),
    ChipOption(label: 'Esquema de Conceptos Clave', icon: Icons.key),
  ];

  static const List<ChipOption> objectiveCategoryOptions = [
    ChipOption(label: 'Técnico', icon: Icons.precision_manufacturing),
    ChipOption(label: 'Habilidades Blandas', icon: Icons.handshake),
    ChipOption(label: 'Compliance', icon: Icons.verified_user),
    ChipOption(label: 'Educativo', icon: Icons.school),
    ChipOption(label: 'Basico', icon: Icons.menu_book),
  ];

  static const List<ChipOption> pedagogicalModelOptions = [
    ChipOption(label: 'Micro-Learning', icon: Icons.bolt),
    ChipOption(label: 'Inmersivo', icon: Icons.auto_awesome),
    ChipOption(label: 'Capacitativo', icon: Icons.fact_check),
    ChipOption(label: 'Ejercitativo', icon: Icons.fitness_center),
    ChipOption(label: 'Practicum', icon: Icons.construction),
  ];

  static const List<ChipOption> projectTypeOptions = [
    ChipOption(label: 'Curso Estándar', icon: Icons.auto_awesome_mosaic),
    ChipOption(label: 'Píldora Formativa', icon: Icons.lightbulb),
    ChipOption(label: 'Certificación Técnica', icon: Icons.verified),
    ChipOption(label: 'Onboarding Corporativo', icon: Icons.apartment),
  ];

  static const List<ChipOption> moduleStructureOptions = [
    ChipOption(label: 'Teoría + Ejemplo', icon: Icons.school),
    ChipOption(label: 'Método Cornell', icon: Icons.note_alt),
    ChipOption(label: 'Caso Real', icon: Icons.fact_check),
  ];

  static const List<ChipOption> toneStyleOptions = [
    ChipOption(label: 'Institucional', icon: Icons.account_balance),
    ChipOption(label: 'Cercano/Coach', icon: Icons.support_agent),
    ChipOption(label: 'Storytelling', icon: Icons.auto_stories),
    ChipOption(label: 'Técnico', icon: Icons.engineering),
  ];

  static const List<ChipOption> abstractionLevelOptions = [
    ChipOption(label: 'Desde Cero', icon: Icons.start),
    ChipOption(label: 'Nivel Profesional', icon: Icons.workspace_premium),
    ChipOption(label: 'Nivel Experto', icon: Icons.military_tech),
  ];

  static const List<ChipOption> voiceStyleOptions = [
    ChipOption(label: 'Tutor Senior', icon: Icons.school_outlined),
    ChipOption(label: 'Compañero', icon: Icons.groups),
    ChipOption(label: 'Experto', icon: Icons.engineering_outlined),
  ];

  static const List<ChipOption> readingPaceOptions = [
    ChipOption(label: 'Dinámico', icon: Icons.flash_on),
    ChipOption(label: 'Explicativo', icon: Icons.menu_book),
  ];

  static const List<ChipOption> challengeFrequencyOptions = [
    ChipOption(label: 'Baja (solo lectura)', icon: Icons.menu_book),
    ChipOption(label: 'Media (preguntas cada módulo)', icon: Icons.help_outline),
    ChipOption(label: 'Alta (gamificación constante)', icon: Icons.sports_esports),
    ChipOption(label: 'Superior (lectura y gamificacion)', icon: Icons.flash_on),
  ];

  static const List<ChipOption> multimediaStrategyOptions = [
    ChipOption(label: 'Solo Texto', icon: Icons.text_snippet),
    ChipOption(label: 'Sugerir Prompts (para IA de imagen)', icon: Icons.image_search),
    ChipOption(label: 'Anclajes de Vídeo', icon: Icons.video_library),
  ];

  static const List<ChipOption> imageStyleOptions = [
    ChipOption(label: 'Fotorealista', icon: Icons.camera_alt),
    ChipOption(label: 'Ilustración Plana/Modern', icon: Icons.brush),
    ChipOption(label: 'Diagrama Técnico/Esquema', icon: Icons.settings),
    ChipOption(label: 'Boceto a Mano Alzada', icon: Icons.edit),
    ChipOption(label: 'Infografía Abstracta', icon: Icons.show_chart),
  ];

  static const List<ChipOption> interactionTypeOptions = [
    ChipOption(label: 'Pregunta Flash (Test rápido)', icon: Icons.bolt),
    ChipOption(label: 'Pausa para Reflexionar (Sin respuesta)', icon: Icons.self_improvement),
    ChipOption(label: 'Mini-Caso Práctico', icon: Icons.assignment),
    ChipOption(label: 'Verificación de Concepto (True/False)', icon: Icons.rule),
  ];

  static const List<ChipOption> extractionLogicOptions = [
    ChipOption(label: 'Resumir PDF', icon: Icons.picture_as_pdf),
    ChipOption(label: 'Extraer solo Glosario', icon: Icons.menu_book),
    ChipOption(label: 'Convertir Audio en Temario', icon: Icons.graphic_eq),
    ChipOption(label: 'Analizar Casos Prácticos', icon: Icons.fact_check),
  ];

  static const List<ChipOption> faqAutomationOptions = [
    ChipOption(label: 'Preguntas Directas', icon: Icons.question_answer),
    ChipOption(label: 'Dudas de Aplicación Real', icon: Icons.build_circle),
    ChipOption(label: 'Preguntas por módulo', icon: Icons.view_agenda),
    ChipOption(label: 'Preguntas de Examen', icon: Icons.school),
  ];

  static const List<ChipOption> scormVersionOptions = [
    ChipOption(label: 'SCORM 1.2', icon: Icons.layers),
    ChipOption(label: 'SCORM 2004 4th Edition', icon: Icons.layers_outlined),
  ];

  static const List<ChipOption> scormMetadataOptions = [
    ChipOption(label: 'Incluir palabras clave', icon: Icons.tag),
    ChipOption(label: 'Descripción del catálogo', icon: Icons.description),
    ChipOption(label: 'Versión del paquete (v1.0.0)', icon: Icons.confirmation_number),
  ];

  static const List<ChipOption> scormNavigationOptions = [
    ChipOption(label: 'Libre', icon: Icons.open_in_full),
    ChipOption(label: 'Lineal (Siguiente bloque bloqueado hasta ver el anterior)', icon: Icons.lock),
    ChipOption(label: 'Bloqueo por Evaluación (Obligatorio aprobar para avanzar)', icon: Icons.verified_user),
  ];

  static const List<ChipOption> scormCompletionOptions = [
    ChipOption(label: 'Passed/Incomplete', icon: Icons.check_circle_outline),
    ChipOption(label: 'Completed/Failed', icon: Icons.cancel_outlined),
    ChipOption(label: 'Passed/Failed', icon: Icons.check_circle),
  ];

  static const List<ChipOption> scormExitOptions = [
    ChipOption(label: 'Auto-Commit al cerrar ventana', icon: Icons.logout),
    ChipOption(label: 'Cierre manual', icon: Icons.exit_to_app),
  ];

  static const List<ChipOption> finalExamLevelOptions = [
    ChipOption(label: 'Básico', icon: Icons.looks_one),
    ChipOption(label: 'Intermedio', icon: Icons.looks_two),
    ChipOption(label: 'Avanzado', icon: Icons.looks_3),
    ChipOption(label: 'Máster', icon: Icons.school),
  ];

  static const List<ChipOption> finalExamTimeOptions = [
    ChipOption(label: 'Sin límite', icon: Icons.timer_off),
    ChipOption(label: '15 min', icon: Icons.timer_outlined),
    ChipOption(label: '30 min', icon: Icons.timer),
    ChipOption(label: '60 min', icon: Icons.av_timer),
  ];

  static const List<ChipOption> moduleTestTypeOptions = [
    ChipOption(label: 'Autoevaluación', icon: Icons.self_improvement),
    ChipOption(label: 'Control de Paso', icon: Icons.lock),
  ];

  static const List<ChipOption> moduleTestStyleOptions = [
    ChipOption(label: 'Solo Test', icon: Icons.quiz),
    ChipOption(label: 'Verdadero/Falso', icon: Icons.rule),
    ChipOption(label: 'Casos rápidos', icon: Icons.assignment),
  ];

  static const List<ChipOption> targetLmsOptions = [
    ChipOption(label: 'Genérico', icon: Icons.language),
    ChipOption(label: 'Moodle', icon: Icons.school),
    ChipOption(label: 'Cornerstone', icon: Icons.business_center),
    ChipOption(label: 'SuccessFactors', icon: Icons.corporate_fare),
    ChipOption(label: 'Canvas', icon: Icons.dashboard_customize),
    ChipOption(label: 'Aiccart', icon: Icons.memory),
  ];

  static const List<ChipOption> compatibilityPatchOptions = [
    ChipOption(label: 'Forzar SCORM API find', icon: Icons.search),
    ChipOption(label: 'Fix de altura en Iframe', icon: Icons.aspect_ratio),
    ChipOption(label: 'Compatibilidad con App Móvil LMS', icon: Icons.phone_android),
  ];

  static const List<ChipOption> wcagLevelOptions = [
    ChipOption(label: 'Sin requisitos', icon: Icons.do_not_disturb),
    ChipOption(label: 'Nivel A', icon: Icons.looks_one),
    ChipOption(label: 'Nivel AA (Recomendado)', icon: Icons.looks_two),
    ChipOption(label: 'Nivel AAA', icon: Icons.looks_3),
  ];
}

IconData iconForContentBankType(String type) {
  switch (type) {
    case 'audio':
      return Icons.audiotrack;
    case 'video':
      return Icons.videocam;
    case 'image':
      return Icons.image;
    case 'document':
      return Icons.description;
    default:
      return Icons.insert_drive_file;
  }
}

String xApiDensityLabel(double value) {
  if (value <= 25) return 'Solo estados';
  if (value <= 50) return 'Eventos clave';
  if (value <= 75) return 'Interacciones frecuentes';
  return 'Cada interacción del usuario (Big Data)';
}

InputDecoration inputStyle(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
