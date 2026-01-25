import 'package:flutter/material.dart';
import '../creation_shared_widgets.dart';

class MultimediaSectionView extends StatelessWidget {
  final List<ChipOption> multimediaStrategyOptions;
  final String multimediaStrategy;
  final ValueChanged<String> onMultimediaStrategyChanged;
  final List<ChipOption> imageStyleOptions;
  final String imageStyle;
  final ValueChanged<String> onImageStyleChanged;

  const MultimediaSectionView({
    super.key,
    required this.multimediaStrategyOptions,
    required this.multimediaStrategy,
    required this.onMultimediaStrategyChanged,
    required this.imageStyleOptions,
    required this.imageStyle,
    required this.onImageStyleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ExpansionTile(
            title: const Text("Estrategia multimedia"),
            initiallyExpanded: true,
            children: [
              SectionCard(
                title: "Estrategia de imágenes",
                icon: Icons.movie,
                color: const Color(0xFF9333EA),
                children: [
                  const SectionLabel(text: "Define el enfoque visual"),
                  IconChoiceChips(
                    options: multimediaStrategyOptions,
                    current: multimediaStrategy,
                    onChanged: onMultimediaStrategyChanged,
                  ),
                ],
              ),
              SectionCard(
                title: "Estilo visual preferido",
                icon: Icons.palette,
                color: const Color(0xFF1D4ED8),
                children: [
                  const SectionLabel(text: "Look de las imágenes sugeridas"),
                  IconChoiceChips(
                    options: imageStyleOptions,
                    current: imageStyle,
                    onChanged: onImageStyleChanged,
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
