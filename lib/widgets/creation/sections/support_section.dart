import 'package:flutter/material.dart';
import '../creation_shared_widgets.dart';
import '../../../models/interactive_block.dart';

class SupportSectionView extends StatelessWidget {
  final InputDecoration Function(String hint) inputStyle;
  final TextEditingController resourcesController;
  final TextEditingController glossaryController;
  final List<InteractiveBlock> resourcesBlocks;
  final List<InteractiveBlock> glossaryBlocks;
  final List<InteractiveBlock> faqBlocks;
  final VoidCallback onResourcesBlocksChanged;
  final VoidCallback onGlossaryBlocksChanged;
  final VoidCallback onFaqBlocksChanged;
  final List<ChipOption> extractionLogicOptions;
  final String extractionLogic;
  final ValueChanged<String> onExtractionLogicChanged;
  final List<ChipOption> faqAutomationOptions;
  final String faqAutomation;
  final ValueChanged<String> onFaqAutomationChanged;
  final double numFaqs;
  final ValueChanged<double> onNumFaqsChanged;

  const SupportSectionView({
    super.key,
    required this.inputStyle,
    required this.resourcesController,
    required this.glossaryController,
    required this.resourcesBlocks,
    required this.glossaryBlocks,
    required this.faqBlocks,
    required this.onResourcesBlocksChanged,
    required this.onGlossaryBlocksChanged,
    required this.onFaqBlocksChanged,
    required this.extractionLogicOptions,
    required this.extractionLogic,
    required this.onExtractionLogicChanged,
    required this.faqAutomationOptions,
    required this.faqAutomation,
    required this.onFaqAutomationChanged,
    required this.numFaqs,
    required this.onNumFaqsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ExpansionTile(
            title: const Text("Recursos y FAQ"),
            initiallyExpanded: true,
            children: [
              SectionCard(
                title: "Lógica de extracción",
                icon: Icons.rule,
                color: const Color(0xFF0F766E),
                children: [
                  const SectionLabel(text: "Qué hacer con los documentos"),
                  IconChoiceChips(
                    options: extractionLogicOptions,
                    current: extractionLogic,
                    onChanged: onExtractionLogicChanged,
                  ),
                ],
              ),
              SectionCard(
                title: "Automatización de FAQ",
                icon: Icons.quiz,
                color: const Color(0xFFB91C1C),
                children: [
                  const SectionLabel(text: "Profundidad de preguntas"),
                  IconChoiceChips(
                    options: faqAutomationOptions,
                    current: faqAutomation,
                    onChanged: onFaqAutomationChanged,
                  ),
                ],
              ),
              const SectionLabel(text: "Recursos Adicionales (bloques)"),
              InteractiveBlockEditor(
                blocks: resourcesBlocks,
                onChanged: onResourcesBlocksChanged,
              ),
              const SizedBox(height: 20),
              const SectionLabel(text: "Términos del Glosario (bloques)"),
              InteractiveBlockEditor(
                blocks: glossaryBlocks,
                onChanged: onGlossaryBlocksChanged,
              ),
              const SizedBox(height: 20),
              const SectionLabel(text: "Preguntas Frecuentes (bloques)"),
              InteractiveBlockEditor(
                blocks: faqBlocks,
                onChanged: onFaqBlocksChanged,
              ),
              const SizedBox(height: 20),
              SliderLabel(label: "Cantidad de FAQ", value: numFaqs.toInt()),
              Slider(
                value: numFaqs,
                min: 0,
                max: 15,
                divisions: 15,
                activeColor: Colors.teal,
                onChanged: onNumFaqsChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
