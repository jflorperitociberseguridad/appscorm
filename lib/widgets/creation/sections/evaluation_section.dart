import 'package:flutter/material.dart';
import '../creation_shared_widgets.dart';

class EvaluationSectionView extends StatelessWidget {
  final List<ChipOption> finalExamLevelOptions;
  final String finalExamLevel;
  final ValueChanged<String> onFinalExamLevelChanged;
  final double finalExamQuestions;
  final ValueChanged<double> onFinalExamQuestionsChanged;
  final double finalExamComplexRatio;
  final ValueChanged<double> onFinalExamComplexRatioChanged;
  final List<ChipOption> finalExamTimeOptions;
  final String finalExamTimeLimit;
  final ValueChanged<String> onFinalExamTimeLimitChanged;
  final bool finalExamShowTimer;
  final ValueChanged<bool> onFinalExamShowTimerChanged;
  final bool finalExamShuffleQuestions;
  final ValueChanged<bool> onFinalExamShuffleQuestionsChanged;
  final bool finalExamShuffleAnswers;
  final ValueChanged<bool> onFinalExamShuffleAnswersChanged;
  final bool finalExamAllowBack;
  final ValueChanged<bool> onFinalExamAllowBackChanged;
  final bool finalExamShowFeedback;
  final ValueChanged<bool> onFinalExamShowFeedbackChanged;
  final bool finalExamGenerateDiploma;
  final ValueChanged<bool> onFinalExamGenerateDiplomaChanged;

  final bool moduleTestsEnabled;
  final ValueChanged<bool> onModuleTestsEnabledChanged;
  final double moduleTestQuestions;
  final ValueChanged<double> onModuleTestQuestionsChanged;
  final List<ChipOption> moduleTestTypeOptions;
  final String moduleTestType;
  final ValueChanged<String> onModuleTestTypeChanged;
  final bool moduleTestImmediateFeedback;
  final ValueChanged<bool> onModuleTestImmediateFeedbackChanged;
  final List<ChipOption> moduleTestStyleOptions;
  final String moduleTestStyle;
  final ValueChanged<String> onModuleTestStyleChanged;

  const EvaluationSectionView({
    super.key,
    required this.finalExamLevelOptions,
    required this.finalExamLevel,
    required this.onFinalExamLevelChanged,
    required this.finalExamQuestions,
    required this.onFinalExamQuestionsChanged,
    required this.finalExamComplexRatio,
    required this.onFinalExamComplexRatioChanged,
    required this.finalExamTimeOptions,
    required this.finalExamTimeLimit,
    required this.onFinalExamTimeLimitChanged,
    required this.finalExamShowTimer,
    required this.onFinalExamShowTimerChanged,
    required this.finalExamShuffleQuestions,
    required this.onFinalExamShuffleQuestionsChanged,
    required this.finalExamShuffleAnswers,
    required this.onFinalExamShuffleAnswersChanged,
    required this.finalExamAllowBack,
    required this.onFinalExamAllowBackChanged,
    required this.finalExamShowFeedback,
    required this.onFinalExamShowFeedbackChanged,
    required this.finalExamGenerateDiploma,
    required this.onFinalExamGenerateDiplomaChanged,
    required this.moduleTestsEnabled,
    required this.onModuleTestsEnabledChanged,
    required this.moduleTestQuestions,
    required this.onModuleTestQuestionsChanged,
    required this.moduleTestTypeOptions,
    required this.moduleTestType,
    required this.onModuleTestTypeChanged,
    required this.moduleTestImmediateFeedback,
    required this.onModuleTestImmediateFeedbackChanged,
    required this.moduleTestStyleOptions,
    required this.moduleTestStyle,
    required this.onModuleTestStyleChanged,
    required this.finalExamPassScore,
    required this.onFinalExamPassScoreChanged,
  });

  final double finalExamPassScore;
  final ValueChanged<double> onFinalExamPassScoreChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ExpansionTile(
            title: const Text("Evaluación final"),
            initiallyExpanded: true,
            children: [
              SectionCard(
                title: "Evaluación Final de Certificación",
                icon: Icons.verified,
                color: const Color(0xFFB91C1C),
                children: [
                  const SectionLabel(text: "Nivel"),
                  IconChoiceChips(
                    options: finalExamLevelOptions,
                    current: finalExamLevel,
                    onChanged: onFinalExamLevelChanged,
                  ),
                  const SizedBox(height: 12),
                  SliderLabel(label: "Preguntas", value: finalExamQuestions.toInt()),
                  Slider(
                    value: finalExamQuestions,
                    min: 5,
                    max: 50,
                    divisions: 45,
                    activeColor: const Color(0xFFB91C1C),
                    onChanged: onFinalExamQuestionsChanged,
                  ),
                  const SectionLabel(text: "Dificultad (complejas vs. directas)"),
                  PercentageSlider(
                    value: finalExamComplexRatio,
                    onChanged: onFinalExamComplexRatioChanged,
                    activeColor: const Color(0xFFB91C1C),
                    lowLabel: "Directas",
                    highLabel: "Complejas",
                  ),
                  const SizedBox(height: 12),
                  const SectionLabel(text: "Nota de corte"),
                  PassScoreSlider(
                    value: finalExamPassScore,
                    onChanged: onFinalExamPassScoreChanged,
                  ),
                  const SizedBox(height: 12),
                  const SectionLabel(text: "Tiempo"),
                  IconChoiceChips(
                    options: finalExamTimeOptions,
                    current: finalExamTimeLimit,
                    onChanged: onFinalExamTimeLimitChanged,
                  ),
                  SwitchRow(
                    title: "Mostrar cuenta atrás al alumno",
                    value: finalExamShowTimer,
                    onChanged: onFinalExamShowTimerChanged,
                  ),
                  const SizedBox(height: 8),
                  SwitchRow(
                    title: "Aleatorizar preguntas",
                    value: finalExamShuffleQuestions,
                    onChanged: onFinalExamShuffleQuestionsChanged,
                  ),
                  SwitchRow(
                    title: "Aleatorizar respuestas",
                    value: finalExamShuffleAnswers,
                    onChanged: onFinalExamShuffleAnswersChanged,
                  ),
                  SwitchRow(
                    title: "Permitir volver atrás",
                    subtitle: "Modo secuencial si se desactiva",
                    value: finalExamAllowBack,
                    onChanged: onFinalExamAllowBackChanged,
                  ),
                  SwitchRow(
                    title: "Mostrar feedback pedagógico al finalizar",
                    value: finalExamShowFeedback,
                    onChanged: onFinalExamShowFeedbackChanged,
                  ),
                  SwitchRow(
                    title: "Generar diploma PDF automático al aprobar",
                    value: finalExamGenerateDiploma,
                    onChanged: onFinalExamGenerateDiplomaChanged,
                  ),
                ],
              ),
              SectionCard(
                title: "Autoevaluaciones por Módulo",
                icon: Icons.fact_check,
                color: const Color(0xFF1D4ED8),
                children: [
                  SwitchRow(
                    title: "Incluir test al final de cada módulo",
                    value: moduleTestsEnabled,
                    onChanged: onModuleTestsEnabledChanged,
                  ),
                  const SizedBox(height: 12),
                  SliderLabel(label: "Preguntas por módulo", value: moduleTestQuestions.toInt()),
                  Slider(
                    value: moduleTestQuestions,
                    min: 3,
                    max: 10,
                    divisions: 7,
                    activeColor: const Color(0xFF1D4ED8),
                    onChanged: moduleTestsEnabled ? onModuleTestQuestionsChanged : null,
                  ),
                  const SectionLabel(text: "Tipo"),
                  IconChoiceChips(
                    options: moduleTestTypeOptions,
                    current: moduleTestType,
                    onChanged: moduleTestsEnabled ? onModuleTestTypeChanged : (_) {},
                  ),
                  SwitchRow(
                    title: "Corregir en el acto",
                    subtitle: "El alumno sabe si acertó al pulsar",
                    value: moduleTestImmediateFeedback,
                    onChanged: moduleTestsEnabled ? onModuleTestImmediateFeedbackChanged : null,
                  ),
                  const SectionLabel(text: "Estilo de pregunta"),
                  IconChoiceChips(
                    options: moduleTestStyleOptions,
                    current: moduleTestStyle,
                    onChanged: moduleTestsEnabled ? onModuleTestStyleChanged : (_) {},
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
