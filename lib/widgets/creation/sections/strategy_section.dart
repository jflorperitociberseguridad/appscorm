import 'package:flutter/material.dart';
import '../creation_shared_widgets.dart';

class StrategySectionView extends StatelessWidget {
  final InputDecoration Function(String hint) inputStyle;
  final VoidCallback onSuggestObjectives;
  final TextEditingController objectivesController;

  final List<ChipOption> introApproachOptions;
  final String introApproach;
  final ValueChanged<String> onIntroApproachChanged;
  final String introDensity;
  final ValueChanged<String> onIntroDensityChanged;
  final List<ChipOption> objectiveCategoryOptions;
  final String objectiveCategory;
  final ValueChanged<String> onObjectiveCategoryChanged;
  final List<ChipOption> conceptMapOptions;
  final String conceptMapFormat;
  final ValueChanged<String> onConceptMapFormatChanged;

  const StrategySectionView({
    super.key,
    required this.inputStyle,
    required this.onSuggestObjectives,
    required this.objectivesController,
    required this.introApproachOptions,
    required this.introApproach,
    required this.onIntroApproachChanged,
    required this.introDensity,
    required this.onIntroDensityChanged,
    required this.objectiveCategoryOptions,
    required this.objectiveCategory,
    required this.onObjectiveCategoryChanged,
    required this.conceptMapOptions,
    required this.conceptMapFormat,
    required this.onConceptMapFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ExpansionTile(
            title: const Text("Guía didáctica"),
            initiallyExpanded: true,
            children: [
              SectionCard(
                title: "Enfoque de la introducción",
                icon: Icons.tips_and_updates,
                color: const Color(0xFF2563EB),
                children: [
                  const SectionLabel(text: "Selecciona el enfoque"),
                  IconChoiceChips(
                    options: introApproachOptions,
                    current: introApproach,
                    onChanged: onIntroApproachChanged,
                  ),
                ],
              ),
              SectionCard(
                title: "Densidad de la introducción",
                icon: Icons.format_size,
                color: const Color(0xFF0F766E),
                children: [
                  const SectionLabel(text: "Nivel de detalle"),
                  SegmentedControl(
                    options: const ["Breve", "Estándar", "Detallada"],
                    current: introDensity,
                    onChanged: onIntroDensityChanged,
                  ),
                ],
              ),
              SectionCard(
                title: "Objetivos de aprendizaje",
                icon: Icons.flag,
                color: const Color(0xFF6D28D9),
                children: [
                  const SectionLabel(text: "Categoría de objetivos"),
                  IconChoiceChips(
                    options: objectiveCategoryOptions,
                    current: objectiveCategory,
                    onChanged: onObjectiveCategoryChanged,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: objectivesController,
                          decoration: inputStyle("Ej: Identificar riesgos..."),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: onSuggestObjectives,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text("Sugerir con IA"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SectionCard(
                title: "Mapa conceptual",
                icon: Icons.account_tree,
                color: const Color(0xFFB45309),
                children: [
                  const SectionLabel(text: "Formato de salida"),
                  IconChoiceChips(
                    options: conceptMapOptions,
                    current: conceptMapFormat,
                    onChanged: onConceptMapFormatChanged,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
