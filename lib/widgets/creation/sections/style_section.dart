import 'package:flutter/material.dart';
import '../creation_shared_widgets.dart';

class StyleSectionView extends StatelessWidget {
  final InputDecoration Function(String hint) inputStyle;
  final TextEditingController styleNotesController;

  final List<ChipOption> toneStyleOptions;
  final String toneStyle;
  final ValueChanged<String> onToneStyleChanged;
  final List<ChipOption> abstractionLevelOptions;
  final String abstractionLevel;
  final ValueChanged<String> onAbstractionLevelChanged;
  final List<ChipOption> voiceStyleOptions;
  final String voiceStyle;
  final ValueChanged<String> onVoiceStyleChanged;
  final List<ChipOption> readingPaceOptions;
  final String readingPace;
  final ValueChanged<String> onReadingPaceChanged;

  const StyleSectionView({
    super.key,
    required this.inputStyle,
    required this.styleNotesController,
    required this.toneStyleOptions,
    required this.toneStyle,
    required this.onToneStyleChanged,
    required this.abstractionLevelOptions,
    required this.abstractionLevel,
    required this.onAbstractionLevelChanged,
    required this.voiceStyleOptions,
    required this.voiceStyle,
    required this.onVoiceStyleChanged,
    required this.readingPaceOptions,
    required this.readingPace,
    required this.onReadingPaceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ExpansionTile(
            title: const Text("Estilo y narrativa"),
            initiallyExpanded: true,
            children: [
              SectionCard(
                title: "Tono",
                icon: Icons.record_voice_over,
                color: const Color(0xFF334155),
                children: [
                  const SectionLabel(text: "Selecciona el tono"),
                  IconChoiceChips(
                    options: toneStyleOptions,
                    current: toneStyle,
                    onChanged: onToneStyleChanged,
                  ),
                ],
              ),
              SectionCard(
                title: "Nivel de abstracción",
                icon: Icons.layers,
                color: const Color(0xFF0EA5E9),
                children: [
                  const SectionLabel(text: "Punto de partida"),
                  IconChoiceChips(
                    options: abstractionLevelOptions,
                    current: abstractionLevel,
                    onChanged: onAbstractionLevelChanged,
                  ),
                ],
              ),
              SectionCard(
                title: "Voz y ritmo",
                icon: Icons.record_voice_over,
                color: const Color(0xFF0F766E),
                children: [
                  const SectionLabel(text: "Voz de la IA"),
                  IconChoiceChips(
                    options: voiceStyleOptions,
                    current: voiceStyle,
                    onChanged: onVoiceStyleChanged,
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel(text: "Ritmo de lectura"),
                  IconChoiceChips(
                    options: readingPaceOptions,
                    current: readingPace,
                    onChanged: onReadingPaceChanged,
                  ),
                ],
              ),
              SectionCard(
                title: "Notas de estilo",
                icon: Icons.edit_note,
                color: const Color(0xFF6366F1),
                children: [
                  TextField(
                    controller: styleNotesController,
                    maxLines: 3,
                    decoration: inputStyle("Ej: tono visual editorial, ritmo dinámico..."),
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
