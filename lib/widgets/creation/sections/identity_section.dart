import 'package:flutter/material.dart';
import '../creation_shared_widgets.dart';

class IdentitySectionView extends StatelessWidget {
  final double aiAssistanceLevel;
  final ValueChanged<double> onAiAssistanceChanged;
  final List<ChipOption> projectTypeOptions;
  final String projectType;
  final ValueChanged<String> onProjectTypeChanged;
  final TextEditingController titleController;
  final TextEditingController baseContentController;
  final InputDecoration Function(String hint) inputStyle;

  const IdentitySectionView({
    super.key,
    required this.aiAssistanceLevel,
    required this.onAiAssistanceChanged,
    required this.projectTypeOptions,
    required this.projectType,
    required this.onProjectTypeChanged,
    required this.titleController,
    required this.baseContentController,
    required this.inputStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ExpansionTile(
            title: const Text("Identidad del curso"),
            initiallyExpanded: true,
            children: [
              WelcomeCard(
                steps: const [
                  GuideStepData(index: "1", text: "Configura el ADN del curso"),
                  GuideStepData(index: "2", text: "Sube tus fuentes al Banco"),
                  GuideStepData(index: "3", text: "Pulsa Generar para construir la estructura"),
                ],
              ),
              const SizedBox(height: 20),
              SectionCard(
                title: "Tipo de proyecto",
                icon: Icons.layers_outlined,
                color: const Color(0xFF1D4ED8),
                children: [
                  const SectionLabel(text: "Selecciona el formato"),
                  IconChoiceChips(
                    options: projectTypeOptions,
                    current: projectType,
                    onChanged: onProjectTypeChanged,
                  ),
                ],
              ),
              SectionCard(
                title: "Nivel de asistencia IA",
                icon: Icons.auto_awesome,
                color: const Color(0xFF7C3AED),
                children: [
                  const SectionLabel(text: "Grado de creatividad"),
                  AiAssistanceSlider(
                    value: aiAssistanceLevel,
                    onChanged: onAiAssistanceChanged,
                  ),
                ],
              ),
              const SectionLabel(text: "Título del Curso"),
              TextField(
                controller: titleController,
                decoration: inputStyle("Ej: Prevención de Riesgos"),
              ),
              const SizedBox(height: 20),
              const SectionLabel(text: "Contenido Base (Fuente)"),
              TextField(
                controller: baseContentController,
                maxLines: 8,
                decoration: inputStyle("Notas o extractos adicionales (opcional)..."),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
