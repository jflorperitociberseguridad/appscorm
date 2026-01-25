import 'package:flutter/material.dart';
import '../creation_shared_widgets.dart';

class InteractivitySectionView extends StatelessWidget {
  final double interactionDensity;
  final ValueChanged<double> onInteractionDensityChanged;
  final List<ChipOption> challengeFrequencyOptions;
  final String challengeFrequency;
  final ValueChanged<String> onChallengeFrequencyChanged;
  final List<ChipOption> interactionTypeOptions;
  final List<String> interactionTypes;
  final ValueChanged<List<String>> onInteractionTypesChanged;

  const InteractivitySectionView({
    super.key,
    required this.interactionDensity,
    required this.onInteractionDensityChanged,
    required this.challengeFrequencyOptions,
    required this.challengeFrequency,
    required this.onChallengeFrequencyChanged,
    required this.interactionTypeOptions,
    required this.interactionTypes,
    required this.onInteractionTypesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ExpansionTile(
            title: const Text("Interactividad"),
            initiallyExpanded: true,
            children: [
              SectionCard(
                title: "Frecuencia de retos",
                icon: Icons.sports_esports,
                color: const Color(0xFF16A34A),
                children: [
                  const SectionLabel(text: "Nivel de participación"),
                  IconChoiceChips(
                    options: challengeFrequencyOptions,
                    current: challengeFrequency,
                    onChanged: onChallengeFrequencyChanged,
                  ),
                ],
              ),
              SectionCard(
                title: "Tipología de interacciones",
                icon: Icons.sync_alt,
                color: const Color(0xFF0F766E),
                children: [
                  const SectionLabel(text: "Selecciona los tipos de paradas"),
                  FilterChips(
                    options: interactionTypeOptions,
                    selected: interactionTypes,
                    onChanged: onInteractionTypesChanged,
                  ),
                  const SizedBox(height: 16),
                  const SectionLabel(text: "Densidad de interacción"),
                  InteractionDensitySlider(
                    value: interactionDensity,
                    onChanged: onInteractionDensityChanged,
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
