import 'package:flutter/material.dart';

import '../../models/course_model.dart';
import '../../services/manuscript_service.dart';
import '../manuscript_viewer_overlay.dart';
import 'course_generation_controller.dart';

class ManuscriptLogicHandler {
  final ManuscriptService manuscriptService;
  final CourseGenerationController courseGenerationController;

  ManuscriptLogicHandler({
    ManuscriptService? manuscriptService,
    CourseGenerationController? courseGenerationController,
  })  : manuscriptService = manuscriptService ?? ManuscriptService(),
        courseGenerationController = courseGenerationController ?? CourseGenerationController();

  bool _hasContentBankInput(List<Map<String, String>> contentBankFiles, String contentBankNotes) {
    if (contentBankNotes.trim().isNotEmpty) return true;
    for (final file in contentBankFiles) {
      final name = file['name']?.trim() ?? '';
      final path = file['path']?.trim() ?? '';
      final extension = file['extension']?.trim() ?? '';
      if (name.isNotEmpty || path.isNotEmpty || extension.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Future<void> startManuscriptFlow({
    required BuildContext context,
    required bool mounted,
    required String title,
    required String baseContent,
    required List<Map<String, String>> contentBankFiles,
    required String contentBankNotes,
    required Map<String, dynamic> generationConfig,
    required CourseConfig courseConfig,
    required void Function(String message) onLoadingMessage,
    required void Function(bool value) onLoadingChanged,
  }) async {
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ El título del curso es obligatorio.")),
      );
      return;
    }
    if (!_hasContentBankInput(contentBankFiles, contentBankNotes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, añade contenido al banco antes de generar el manuscrito'),
        ),
      );
      return;
    }

    onLoadingMessage('Diseñando la arquitectura pedagógica del curso...');
    onLoadingChanged(true);

    try {
      final contentBankSummary = buildContentBankSummary(contentBankFiles);
      final sourceText = [
        if (contentBankSummary.isNotEmpty) "MATERIALES MULTIMODALES:\n$contentBankSummary",
        if (contentBankNotes.trim().isNotEmpty) "NOTAS DEL BANCO:\n$contentBankNotes",
        if (baseContent.trim().isNotEmpty) "NOTAS DEL AUTOR:\n$baseContent",
      ].join('\n\n');

      final result = await manuscriptService.generate(
        courseConfig: courseConfig,
        contentBankText: sourceText,
        generationConfig: generationConfig,
      );
      if (!context.mounted) return;
      if (!mounted) return;
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.reason?.isNotEmpty == true ? result.reason! : 'No fue posible generar el manuscrito.'),
          ),
        );
        return;
      }
      final manuscript = result.markdown;
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ManuscriptViewerOverlay(
          manuscriptMarkdown: manuscript,
          onValidate: () {
            Navigator.of(context).pop();
            courseGenerationController.generateCourseFromManuscript(
              context: context,
              manuscript: manuscript,
              config: generationConfig,
              contentBankFiles: contentBankFiles,
              courseConfig: courseConfig,
              onLoadingMessage: onLoadingMessage,
              onLoadingChanged: onLoadingChanged,
              mounted: mounted,
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible generar el manuscrito: $e')),
      );
    } finally {
      if (mounted) onLoadingChanged(false);
    }
  }

  String buildContentBankSummary(List<Map<String, String>> files) {
    if (files.isEmpty) return '';
    final buffer = StringBuffer();
    for (final file in files) {
      final name = file['name'] ?? 'archivo';
      final type = file['type'] ?? 'desconocido';
      final extension = file['extension'] ?? '';
      buffer.writeln('- $name (${type.toUpperCase()}${extension.isNotEmpty ? ', .$extension' : ''})');
    }
    return buffer.toString().trim();
  }
}
