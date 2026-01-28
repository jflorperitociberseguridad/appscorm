import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

// Importaciones de tus modelos
import '../../models/course_model.dart';
import '../../models/interactive_block.dart';
import 'scorm_export_assets.dart';
import 'scorm_block_mappers.dart';

class ScormExportService {
  // Instanciamos los generadores auxiliares
  final HtmlGenerator _htmlGen = const HtmlGenerator();
  final ManifestGenerator _manifestGen = const ManifestGenerator();

  /// Método principal llamado desde la UI para generar el ZIP
  Future<String> exportCourse(
    CourseModel course, {
    String? filename,
    Set<String>? enabledStaticSections,
  }) async {
    final archive = Archive();

    final assetMap = buildScormAssetMap(course);
    final manifestString = _manifestGen.generateManifest(
      course,
      enabledStaticSections: enabledStaticSections,
      assetFiles: assetMap.values.toList(),
    );
    final manifestBytes = utf8.encode(manifestString);
    archive.addFile(ArchiveFile('imsmanifest.xml', manifestBytes.length, manifestBytes));
    for (int i = 0; i < course.modules.length; i++) {
      try {
        await Future<void>.sync(() {
          final fileName = 'module_$i.html';
          final htmlContent = _htmlGen.generateModulePage(course, i, assetMap: assetMap);
          final htmlBytes = utf8.encode(htmlContent);
          archive.addFile(ArchiveFile(fileName, htmlBytes.length, htmlBytes));
        });
      } catch (_) {
        // Ignora fallos de renderizado por módulo para continuar la exportación.
      }
    }

    final indexContent = StringBuffer();
    if (course.modules.isEmpty) {
      indexContent.writeln('<p>No hay módulos disponibles en este curso.</p>');
    } else {
      indexContent.writeln('<ul>');
      for (int i = 0; i < course.modules.length; i++) {
        final title = HtmlGenerator.esc.convert(course.modules[i].title);
        indexContent.writeln('<li><a href="module_$i.html">Módulo ${i + 1}: $title</a></li>');
      }
      indexContent.writeln('</ul>');
    }
    final indexHtml = _htmlGen.generateStaticPage(course, 'Inicio del Curso', indexContent.toString());
    final indexBytes = utf8.encode(indexHtml);
    archive.addFile(ArchiveFile('index.html', indexBytes.length, indexBytes));
    final staticPages = _collectStaticPages(
      course,
      enabledStaticSections: enabledStaticSections,
      assetMap: assetMap,
    );
    staticPages.forEach((fileName, pageData) {
      final title = pageData['title']!;
      final content = pageData['content']!;
      // Usamos el generador para crear la página con el mismo diseño que el resto
      final htmlString = _htmlGen.generateStaticPage(course, title, content);
      final htmlBytes = utf8.encode(htmlString);
      archive.addFile(ArchiveFile(fileName, htmlBytes.length, htmlBytes));
    });

    if (assetMap.isNotEmpty) {
      try {
        await addScormAssetsToArchive(archive, assetMap);
      } catch (_) {
        // Si falla la carga de assets, continuamos exportando el SCORM base.
      }
    }
    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive)!;
    final zipBytes = Uint8List.fromList(zipData);
    
    // Nombre del archivo de salida
    final outName = filename != null && filename.isNotEmpty
        ? filename
        : 'scorm_curso_${DateTime.now().millisecondsSinceEpoch}.zip';

    if (kIsWeb) {
      // Lógica para Web: Crear Blob y descargar
      final blob = html.Blob([zipBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', outName)
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      return outName;
    } else {
      // Lógica para Móvil/Desktop: Guardar en temporales
      final tmpDir = await getTemporaryDirectory();
      final outPath = p.join(tmpDir.path, outName);
      final outFile = File(outPath);
      await outFile.writeAsBytes(zipBytes, flush: true);
      return outFile.path;
    }
  }

  /// Helper para recolectar todo el contenido estático del curso y prepararlo para HTML
  Map<String, Map<String, String>> _collectStaticPages(
    CourseModel course, {
    Set<String>? enabledStaticSections,
    Map<String, String>? assetMap,
  }) {
    bool hasMeaningfulBlocks(List<InteractiveBlock> blocks) {
      for (final block in blocks) {
        if (block.content.isEmpty) continue;
        for (final value in block.content.values) {
          if (value == null) continue;
          if (value is String && value.trim().isEmpty) continue;
          if (value is List && value.isEmpty) continue;
          if (value is Map && value.isEmpty) continue;
          return true;
        }
      }
      return false;
    }

    // Función auxiliar para renderizar bloques a HTML
    String blocksToHtml(List<InteractiveBlock> blocks, String defaultText) {
      if (blocks.isEmpty || !hasMeaningfulBlocks(blocks)) return defaultText;
      return _htmlGen.renderBlocks(blocks, assetMap: assetMap);
    }

    List<InteractiveBlock> ensureBlocksFromText(List<InteractiveBlock> blocks, String text) {
      if (text.trim().isEmpty) return blocks;
      if (hasMeaningfulBlocks(blocks)) return blocks;
      return [
        InteractiveBlock.create(type: BlockType.textPlain, content: {'text': text})
      ];
    }

    String listToHtml(List<String> items, String emptyText) {
      final cleanItems = items.map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
      if (cleanItems.isEmpty) return emptyText;
      final buf = StringBuffer('<ul>');
      for (final item in cleanItems) {
        buf.writeln('<li>${HtmlGenerator.esc.convert(item)}</li>');
      }
      buf.writeln('</ul>');
      return buf.toString();
    }

    String glossaryToHtml(List<GlossaryItem> items, String emptyText) {
      final cleanItems = items.where((item) {
        final term = item.term.trim();
        final definition = item.definition.trim();
        return term.isNotEmpty || definition.isNotEmpty;
      }).toList();
      if (cleanItems.isEmpty) return emptyText;
      final buf = StringBuffer('<div class="glossary-list">');
      for (final item in cleanItems) {
        final term = HtmlGenerator.esc.convert(item.term);
        final definition = HtmlGenerator.esc.convert(item.definition);
        buf.writeln('<p><strong>$term</strong>: $definition</p>');
      }
      buf.writeln('</div>');
      return buf.toString();
    }

    String faqsToHtml(List<FaqItem> items, String emptyText) {
      final cleanItems = items.where((item) {
        final question = item.question.trim();
        final answer = item.answer.trim();
        return question.isNotEmpty || answer.isNotEmpty;
      }).toList();
      if (cleanItems.isEmpty) return emptyText;
      final buf = StringBuffer('<div class="faq-list">');
      for (final item in cleanItems) {
        final question = HtmlGenerator.esc.convert(item.question);
        final answer = HtmlGenerator.esc.convert(item.answer);
        buf.writeln('<div class="faq-item"><h3>$question</h3><p>$answer</p></div>');
      }
      buf.writeln('</div>');
      return buf.toString();
    }

    String evaluationToHtml(EvaluationSection evaluation, String emptyText) {
      final blocks = evaluation.blocks;
      final parts = <String>[];
      final criteria = evaluation.participationCriteria.trim();
      if (criteria.isNotEmpty) {
        parts.add('<div class="block text-block"><strong>Criterios:</strong> ${HtmlGenerator.esc.convert(criteria)}</div>');
      }
      if (blocks.isNotEmpty) {
        parts.add(_htmlGen.renderBlocks(blocks, assetMap: assetMap));
      }
      if (parts.isEmpty) return emptyText;
      return parts.join('\n');
    }

    bool isEnabled(String sectionId) {
      return enabledStaticSections == null || enabledStaticSections.contains(sectionId);
    }

    // Mapeo: Nombre de archivo -> { Título, Contenido HTML }
    final pages = <String, Map<String, String>>{};
    if (isEnabled('general')) {
      pages['general.html'] = {
        'title': '1.1 Información General', 
        'content': blocksToHtml(course.general.blocks, '')
      };
    }
    final introBlocks = ensureBlocksFromText(course.intro.introBlocks, course.introText);
    final resourcesBlocks = ensureBlocksFromText(course.resources.blocks, course.resources.bibliography);
    if (isEnabled('intro')) {
      pages['intro.html'] = {
        'title': '1.2 Introducción', 
        'content': blocksToHtml(introBlocks, '')
      };
    }
    if (isEnabled('objectives')) {
      pages['objetivos.html'] = {
        'title': '1.3 Objetivos', 
        'content': course.objectives.isNotEmpty
            ? listToHtml(course.objectives, '')
            : blocksToHtml(course.intro.objectiveBlocks, '')
      };
    }
    if (isEnabled('map')) {
      pages['mapa.html'] = {
        'title': '1.4 Mapa Conceptual', 
        'content': blocksToHtml(course.conceptMap.blocks, '')
      };
    }
    if (isEnabled('resources')) {
      pages['recursos.html'] = {
        'title': '3.1 Recursos Didácticos', 
        'content': blocksToHtml(resourcesBlocks, '')
      };
    }
    if (isEnabled('glossary')) {
      pages['glosario.html'] = {
        'title': '3.2 Glosario', 
        'content': course.glossaryItems.isNotEmpty
            ? glossaryToHtml(course.glossaryItems, '')
            : blocksToHtml(course.glossary.blocks, '')
      };
    }
    if (isEnabled('faq')) {
      pages['faq.html'] = {
        'title': '3.3 Preguntas Frecuentes', 
        'content': course.faqItems.isNotEmpty
            ? faqsToHtml(course.faqItems, '')
            : blocksToHtml(course.faq.blocks, '')
      };
    }
    if (isEnabled('eval')) {
      pages['evaluacion.html'] = {
        'title': '3.4 Evaluación Final', 
        'content': evaluationToHtml(course.evaluation, '')
      };
    }
    if (isEnabled('stats')) {
      pages['estadisticas.html'] = {
        'title': '3.5 Estadísticas', 
        'content': blocksToHtml(course.stats.blocks, '')
      };
    }
    if (isEnabled('bank')) {
      pages['banco.html'] = {
        'title': '3.6 Banco de Contenidos', 
        'content': blocksToHtml(course.contentBank.blocks, '')
      };
    }
    return pages;
  }

}
