import 'package:flutter/material.dart';
import '../creation_shared_widgets.dart';

class ScormSectionView extends StatelessWidget {
  final InputDecoration Function(String hint) inputStyle;
  final TextEditingController scormIdentifierController;
  final TextEditingController scormNotesController;

  final List<ChipOption> scormVersionOptions;
  final String scormVersion;
  final ValueChanged<String> onScormVersionChanged;
  final ValueChanged<String> onScormIdentifierChanged;
  final List<ChipOption> scormMetadataOptions;
  final List<String> scormMetadataTags;
  final ValueChanged<List<String>> onScormMetadataTagsChanged;

  final List<ChipOption> scormNavigationOptions;
  final String scormNavigationMode;
  final ValueChanged<String> onScormNavigationModeChanged;
  final bool scormShowLmsButtons;
  final ValueChanged<bool> onScormShowLmsButtonsChanged;
  final bool scormCustomNav;
  final ValueChanged<bool> onScormCustomNavChanged;
  final bool scormBookmarking;
  final ValueChanged<bool> onScormBookmarkingChanged;

  final double scormMasteryScore;
  final ValueChanged<double> onScormMasteryScoreChanged;
  final List<ChipOption> scormCompletionOptions;
  final String scormCompletionStatus;
  final ValueChanged<String> onScormCompletionStatusChanged;
  final bool scormReportTime;
  final ValueChanged<bool> onScormReportTimeChanged;

  final bool scormDebugMode;
  final ValueChanged<bool> onScormDebugModeChanged;
  final List<ChipOption> scormExitOptions;
  final String scormExitBehavior;
  final ValueChanged<String> onScormExitBehaviorChanged;
  final double scormCommitIntervalSeconds;
  final ValueChanged<double> onScormCommitIntervalSecondsChanged;

  const ScormSectionView({
    super.key,
    required this.inputStyle,
    required this.scormIdentifierController,
    required this.scormNotesController,
    required this.scormVersionOptions,
    required this.scormVersion,
    required this.onScormVersionChanged,
    required this.onScormIdentifierChanged,
    required this.scormMetadataOptions,
    required this.scormMetadataTags,
    required this.onScormMetadataTagsChanged,
    required this.scormNavigationOptions,
    required this.scormNavigationMode,
    required this.onScormNavigationModeChanged,
    required this.scormShowLmsButtons,
    required this.onScormShowLmsButtonsChanged,
    required this.scormCustomNav,
    required this.onScormCustomNavChanged,
    required this.scormBookmarking,
    required this.onScormBookmarkingChanged,
    required this.scormMasteryScore,
    required this.onScormMasteryScoreChanged,
    required this.scormCompletionOptions,
    required this.scormCompletionStatus,
    required this.onScormCompletionStatusChanged,
    required this.scormReportTime,
    required this.onScormReportTimeChanged,
    required this.scormDebugMode,
    required this.onScormDebugModeChanged,
    required this.scormExitOptions,
    required this.scormExitBehavior,
    required this.onScormExitBehaviorChanged,
    required this.scormCommitIntervalSeconds,
    required this.onScormCommitIntervalSecondsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ExpansionTile(
            leading: const Icon(Icons.settings_ethernet),
            title: const Text("Estándar y metadatos del paquete (LOM)"),
            initiallyExpanded: true,
            children: [
              SectionCard(
                title: "Versión y metadatos",
                icon: Icons.settings_ethernet,
                color: const Color(0xFF0F172A),
                children: [
                  const SectionLabel(text: "Versión"),
                  IconChoiceChips(
                    options: scormVersionOptions,
                    current: scormVersion,
                    onChanged: onScormVersionChanged,
                  ),
                  const SizedBox(height: 12),
                  const SectionLabel(text: "Identifier del manifiesto"),
                  TextField(
                    controller: scormIdentifierController,
                    decoration: inputStyle("Ej: curso_prevencion_riesgos_2024"),
                    onChanged: onScormIdentifierChanged,
                  ),
                  const SizedBox(height: 12),
                  const SectionLabel(text: "Etiquetado de metadatos"),
                  FilterChips(
                    options: scormMetadataOptions,
                    selected: scormMetadataTags,
                    onChanged: onScormMetadataTagsChanged,
                  ),
                ],
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.history_edu),
            title: const Text("Reglas de navegación y secuenciación"),
            children: [
              SectionCard(
                title: "Modo de avance",
                icon: Icons.history_edu,
                color: const Color(0xFFB45309),
                children: [
                  const SectionLabel(text: "Modo de avance"),
                  IconChoiceChips(
                    options: scormNavigationOptions,
                    current: scormNavigationMode,
                    onChanged: onScormNavigationModeChanged,
                  ),
                  const SizedBox(height: 12),
                  SwitchRow(
                    title: "Mostrar botones nativos del LMS",
                    value: scormShowLmsButtons,
                    onChanged: onScormShowLmsButtonsChanged,
                  ),
                  SwitchRow(
                    title: "Usar navegación personalizada del curso",
                    value: scormCustomNav,
                    onChanged: onScormCustomNavChanged,
                  ),
                  SwitchRow(
                    title: "Recordar última pantalla visitada automáticamente",
                    value: scormBookmarking,
                    onChanged: onScormBookmarkingChanged,
                  ),
                ],
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.verified_outlined),
            title: const Text("Criterios de éxito y puntuación (Mastery)"),
            children: [
              SectionCard(
                title: "Mastery y estado final",
                icon: Icons.verified_outlined,
                color: const Color(0xFF15803D),
                children: [
                  const SectionLabel(text: "Mastery score"),
                  PercentageSlider(
                    value: scormMasteryScore,
                    onChanged: onScormMasteryScoreChanged,
                    activeColor: const Color(0xFF15803D),
                    lowLabel: "0%",
                    highLabel: "100%",
                  ),
                  const SizedBox(height: 12),
                  const SectionLabel(text: "Estado al finalizar"),
                  IconChoiceChips(
                    options: scormCompletionOptions,
                    current: scormCompletionStatus,
                    onChanged: onScormCompletionStatusChanged,
                  ),
                  SwitchRow(
                    title: "Reportar tiempo de sesión al LMS",
                    value: scormReportTime,
                    onChanged: onScormReportTimeChanged,
                  ),
                ],
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.terminal),
            title: const Text("Comunicación y depuración (Debug Mode)"),
            children: [
              SectionCard(
                title: "Commit y diagnósticos",
                icon: Icons.terminal,
                color: const Color(0xFF4B5563),
                children: [
                  const SectionLabel(text: "Frecuencia de guardado (commit)"),
                  CommitIntervalSlider(
                    value: scormCommitIntervalSeconds,
                    onChanged: onScormCommitIntervalSecondsChanged,
                  ),
                  const SizedBox(height: 12),
                  SwitchRow(
                    title: "Activar consola SCORM en pantalla",
                    subtitle: "Muestra logs de la API SCORM en tiempo real",
                    value: scormDebugMode,
                    onChanged: onScormDebugModeChanged,
                  ),
                  const SizedBox(height: 8),
                  const SectionLabel(text: "Acción al salir"),
                  IconChoiceChips(
                    options: scormExitOptions,
                    current: scormExitBehavior,
                    onChanged: onScormExitBehaviorChanged,
                  ),
                ],
              ),
              SectionCard(
                title: "Reglas SCORM adicionales",
                icon: Icons.rule,
                color: const Color(0xFF1F2937),
                children: [
                  TextField(
                    controller: scormNotesController,
                    maxLines: 3,
                    decoration: inputStyle("Ej: completar módulos + nota mínima..."),
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
