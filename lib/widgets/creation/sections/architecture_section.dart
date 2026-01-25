import 'package:flutter/material.dart';
import '../creation_shared_widgets.dart';

class ArchitectureSectionView extends StatelessWidget {
  final List<ChipOption> pedagogicalModelOptions;
  final String pedagogicalModel;
  final ValueChanged<String> onPedagogicalModelChanged;
  final double numModules;
  final ValueChanged<double> onNumModulesChanged;
  final String moduleDepth;
  final ValueChanged<String> onModuleDepthChanged;
  final double paragraphsPerBlock;
  final ValueChanged<double> onParagraphsPerBlockChanged;
  final List<ChipOption> moduleStructureOptions;
  final String moduleStructure;
  final ValueChanged<String> onModuleStructureChanged;

  const ArchitectureSectionView({
    super.key,
    required this.pedagogicalModelOptions,
    required this.pedagogicalModel,
    required this.onPedagogicalModelChanged,
    required this.numModules,
    required this.onNumModulesChanged,
    required this.moduleDepth,
    required this.onModuleDepthChanged,
    required this.paragraphsPerBlock,
    required this.onParagraphsPerBlockChanged,
    required this.moduleStructureOptions,
    required this.moduleStructure,
    required this.onModuleStructureChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ExpansionTile(
            title: const Text("Arquitectura del temario"),
            initiallyExpanded: true,
            children: [
              SectionCard(
                title: "Modelo pedagógico",
                icon: Icons.schema,
                color: const Color(0xFF0F172A),
                children: [
                  const SectionLabel(text: "Define el estilo de aprendizaje"),
                  IconChoiceChips(
                    options: pedagogicalModelOptions,
                    current: pedagogicalModel,
                    onChanged: onPedagogicalModelChanged,
                  ),
                  const SizedBox(height: 12),
                  PedagogicalDescription(model: pedagogicalModel),
                ],
              ),
              SectionCard(
                title: "Estructura del temario",
                icon: Icons.view_module,
                color: const Color(0xFFEA580C),
                children: [
                  SliderLabel(label: "Número de Módulos", value: numModules.toInt()),
                  Slider(
                    value: numModules,
                    min: 1,
                    max: 12,
                    divisions: 11,
                    activeColor: Colors.orange,
                    onChanged: onNumModulesChanged,
                  ),
                  const SectionLabel(text: "Profundidad del Contenido"),
                  SegmentedControl(
                    options: const ["Básica", "Intermedia", "Avanzada"],
                    current: moduleDepth,
                    onChanged: onModuleDepthChanged,
                  ),
                ],
              ),
              SectionCard(
                title: "Granularidad del contenido",
                icon: Icons.tune,
                color: const Color(0xFFDC2626),
                children: [
                  SliderLabel(label: "Párrafos por Bloque", value: paragraphsPerBlock.toInt()),
                  Slider(
                    value: paragraphsPerBlock,
                    min: 5,
                    max: 30,
                    divisions: 25,
                    activeColor: const Color(0xFFDC2626),
                    onChanged: onParagraphsPerBlockChanged,
                  ),
                  const SectionLabel(text: "Estructura interna"),
                  IconChoiceChips(
                    options: moduleStructureOptions,
                    current: moduleStructure,
                    onChanged: onModuleStructureChanged,
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
