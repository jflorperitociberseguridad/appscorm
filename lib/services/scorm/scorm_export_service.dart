import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

// Importaciones de tus modelos
import '../../models/course_model.dart';
import '../../models/interactive_block.dart';

// =============================================================================
// 1. SERVICIO PRINCIPAL DE EXPORTACIÓN (Lógica de Empaquetado SCORM 1.2)
// =============================================================================
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

    // ---------------------------------------------------------
    // PASO 1: Generar el archivo de Manifiesto (imsmanifest.xml)
    // ---------------------------------------------------------
    final manifestString = _manifestGen.generateManifest(
      course,
      enabledStaticSections: enabledStaticSections,
    );
    final manifestBytes = utf8.encode(manifestString);
    archive.addFile(ArchiveFile('imsmanifest.xml', manifestBytes.length, manifestBytes));

    // ---------------------------------------------------------
    // PASO 2: Generar las páginas dinámicas de los Módulos (module_X.html)
    // ---------------------------------------------------------
    for (int i = 0; i < course.modules.length; i++) {
      // Generamos el HTML completo para este módulo
      final htmlString = _htmlGen.generateModulePage(course, i);
      final htmlBytes = utf8.encode(htmlString);
      archive.addFile(ArchiveFile('module_$i.html', htmlBytes.length, htmlBytes));
    }

    // ---------------------------------------------------------
    // PASO 3: Generar las páginas estáticas (Intro, Recursos, Estadísticas...)
    // ---------------------------------------------------------
    final staticPages = _collectStaticPages(
      course,
      enabledStaticSections: enabledStaticSections,
    );
    staticPages.forEach((fileName, pageData) {
      final title = pageData['title']!;
      final content = pageData['content']!;
      // Usamos el generador para crear la página con el mismo diseño que el resto
      final htmlString = _htmlGen.generateStaticPage(course, title, content);
      final htmlBytes = utf8.encode(htmlString);
      archive.addFile(ArchiveFile(fileName, htmlBytes.length, htmlBytes));
    });

    // ---------------------------------------------------------
    // PASO 4: Compresión ZIP y Descarga/Guardado
    // ---------------------------------------------------------
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
  }) {
    // Función auxiliar para renderizar bloques a HTML
    String blocksToHtml(List<InteractiveBlock> blocks, String defaultText) {
      if (blocks.isEmpty) return defaultText;
      return _htmlGen.renderBlocks(blocks);
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
        parts.add(_htmlGen.renderBlocks(blocks));
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
        'content': blocksToHtml(course.general.blocks, '<p>Bienvenido a la información general del curso.</p>')
      };
    }
    if (isEnabled('intro')) {
      pages['intro.html'] = {
        'title': '1.2 Introducción', 
        'content': course.introText.trim().isNotEmpty
            ? course.introText
            : blocksToHtml(course.intro.introBlocks, '<p>Introducción al contenido.</p>')
      };
    }
    if (isEnabled('objectives')) {
      pages['objetivos.html'] = {
        'title': '1.3 Objetivos', 
        'content': course.objectives.isNotEmpty
            ? listToHtml(course.objectives, '<p>Objetivos de aprendizaje definidos.</p>')
            : blocksToHtml(course.intro.objectiveBlocks, '<p>Objetivos de aprendizaje definidos.</p>')
      };
    }
    if (isEnabled('map')) {
      pages['mapa.html'] = {
        'title': '1.4 Mapa Conceptual', 
        'content': blocksToHtml(course.conceptMap.blocks, '<p>Mapa visual del curso.</p>')
      };
    }
    if (isEnabled('resources')) {
      pages['recursos.html'] = {
        'title': '3.1 Recursos Didácticos', 
        'content': blocksToHtml(course.resources.blocks, '<p>Material complementario y bibliografía.</p>')
      };
    }
    if (isEnabled('glossary')) {
      pages['glosario.html'] = {
        'title': '3.2 Glosario', 
        'content': course.glossaryItems.isNotEmpty
            ? glossaryToHtml(course.glossaryItems, '<p>Definiciones clave.</p>')
            : blocksToHtml(course.glossary.blocks, '<p>Definiciones clave.</p>')
      };
    }
    if (isEnabled('faq')) {
      pages['faq.html'] = {
        'title': '3.3 Preguntas Frecuentes', 
        'content': course.faqItems.isNotEmpty
            ? faqsToHtml(course.faqItems, '<p>Respuestas a dudas comunes.</p>')
            : blocksToHtml(course.faq.blocks, '<p>Respuestas a dudas comunes.</p>')
      };
    }
    if (isEnabled('eval')) {
      pages['evaluacion.html'] = {
        'title': '3.4 Evaluación Final', 
        'content': evaluationToHtml(course.evaluation, '<p>Prueba de conocimientos.</p>')
      };
    }
    if (isEnabled('stats')) {
      pages['estadisticas.html'] = {
        'title': '3.5 Estadísticas', 
        'content': blocksToHtml(course.stats.blocks, '<p>Panel de seguimiento del alumno.</p>')
      };
    }
    if (isEnabled('bank')) {
      pages['banco.html'] = {
        'title': '3.6 Banco de Contenidos', 
        'content': blocksToHtml(course.contentBank.blocks, '<p>Repositorio de objetos de aprendizaje.</p>')
      };
    }
    return pages;
  }
}

// =============================================================================
// 2. GENERADOR DE MANIFIESTO (Estructura XML para Moodle/LMS)
// =============================================================================
class ManifestGenerator {
  const ManifestGenerator();
  static const esc = HtmlEscape();

  String generateManifest(
    CourseModel course, {
    Set<String>? enabledStaticSections,
  }) {
    final safeId = 'COURSE_${DateTime.now().millisecondsSinceEpoch}';
    final safeTitle = esc.convert(course.title);
    bool isEnabled(String sectionId) {
      return enabledStaticSections == null || enabledStaticSections.contains(sectionId);
    }

    final introMetadata = isEnabled('intro') ? _stripTags(course.introText) : '';
    final objectivesMetadata = isEnabled('objectives')
        ? course.objectives
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .join('; ')
        : '';

    final metadataExtra = StringBuffer();
    if (introMetadata.isNotEmpty) {
      metadataExtra.writeln('<description>${esc.convert(introMetadata)}</description>');
    }
    if (objectivesMetadata.isNotEmpty) {
      metadataExtra.writeln('<keywords>${esc.convert(objectivesMetadata)}</keywords>');
    }

    // 1. Generar items para los Módulos (Carpeta Temario)
    StringBuffer modulesItems = StringBuffer();
    StringBuffer guideItems = StringBuffer();
    StringBuffer resourcesItems = StringBuffer();
    StringBuffer resourcesDefs = StringBuffer();

    for (int i = 0; i < course.modules.length; i++) {
      final modId = 'MOD_$i';
      final file = 'module_$i.html';
      final title = esc.convert(course.modules[i].title);
      // Item del árbol
      modulesItems.writeln('<item identifier="ITEM-$modId" identifierref="RES-$modId"><title>Módulo ${i + 1}: $title</title></item>');
      // Recurso físico
      resourcesDefs.writeln('<resource identifier="RES-$modId" type="webcontent" adlcp:scormtype="sco" href="$file"><file href="$file"/></resource>');
    }

    void addGuideItem({
      required String sectionId,
      required String itemId,
      required String resourceId,
      required String title,
      required String file,
    }) {
      if (!isEnabled(sectionId)) return;
      guideItems.writeln('<item identifier="$itemId" identifierref="$resourceId"><title>$title</title></item>');
      resourcesDefs.writeln('<resource identifier="$resourceId" type="webcontent" adlcp:scormtype="asset" href="$file"><file href="$file"/></resource>');
    }

    void addResourceItem({
      required String sectionId,
      required String itemId,
      required String resourceId,
      required String title,
      required String file,
    }) {
      if (!isEnabled(sectionId)) return;
      resourcesItems.writeln('<item identifier="$itemId" identifierref="$resourceId"><title>$title</title></item>');
      resourcesDefs.writeln('<resource identifier="$resourceId" type="webcontent" adlcp:scormtype="asset" href="$file"><file href="$file"/></resource>');
    }

    // 2. Definir Recursos Estáticos (Deben coincidir con los nombres de archivo generados arriba)
    addGuideItem(
      sectionId: 'general',
      itemId: 'ITEM-GEN',
      resourceId: 'RES-GEN',
      title: '1.1 Información General',
      file: 'general.html',
    );
    addGuideItem(
      sectionId: 'intro',
      itemId: 'ITEM-INTRO',
      resourceId: 'RES-INTRO',
      title: '1.2 Introducción',
      file: 'intro.html',
    );
    addGuideItem(
      sectionId: 'objectives',
      itemId: 'ITEM-OBJ',
      resourceId: 'RES-OBJ',
      title: '1.3 Objetivos',
      file: 'objetivos.html',
    );
    addGuideItem(
      sectionId: 'map',
      itemId: 'ITEM-MAPA',
      resourceId: 'RES-MAPA',
      title: '1.4 Mapa Conceptual',
      file: 'mapa.html',
    );
    addResourceItem(
      sectionId: 'resources',
      itemId: 'ITEM-REC',
      resourceId: 'RES-REC',
      title: '3.1 Recursos Didácticos',
      file: 'recursos.html',
    );
    addResourceItem(
      sectionId: 'glossary',
      itemId: 'ITEM-GLOS',
      resourceId: 'RES-GLOS',
      title: '3.2 Glosario',
      file: 'glosario.html',
    );
    addResourceItem(
      sectionId: 'faq',
      itemId: 'ITEM-FAQ',
      resourceId: 'RES-FAQ',
      title: '3.3 Preguntas Frecuentes',
      file: 'faq.html',
    );
    addResourceItem(
      sectionId: 'eval',
      itemId: 'ITEM-EVAL',
      resourceId: 'RES-EVAL',
      title: '3.4 Evaluación Final',
      file: 'evaluacion.html',
    );
    addResourceItem(
      sectionId: 'stats',
      itemId: 'ITEM-STATS',
      resourceId: 'RES-STATS',
      title: '3.5 Estadísticas',
      file: 'estadisticas.html',
    );
    addResourceItem(
      sectionId: 'bank',
      itemId: 'ITEM-BANK',
      resourceId: 'RES-BANK',
      title: '3.6 Banco de Contenidos',
      file: 'banco.html',
    );

    // 3. Construir el XML completo
    return '''<?xml version="1.0" encoding="UTF-8"?>
<manifest identifier="$safeId" version="1.0" 
  xmlns="http://www.imsproject.org/xsd/imscp_rootv1p1p2" 
  xmlns:adlcp="http://www.adlnet.org/xsd/adlcp_rootv1p2" 
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
  xsi:schemaLocation="http://www.imsproject.org/xsd/imscp_rootv1p1p2 ims_xml.xsd">
  
  <metadata>
    <schema>ADL SCORM</schema>
    <schemaversion>1.2</schemaversion>
    <title>$safeTitle</title>
    ${metadataExtra.toString()}
  </metadata>
  
  <organizations default="ORG-1">
    <organization identifier="ORG-1">
      <title>$safeTitle</title>
      
      ${guideItems.length > 0 ? '''
      <item identifier="FOLDER-GUIDE">
        <title>1. GUÍA DIDÁCTICA</title>
        $guideItems
      </item>
      ''' : ''}
      
      ${course.modules.isNotEmpty ? '''
      <item identifier="FOLDER-CONTENTS">
        <title>2. TEMARIO DEL CURSO</title>
        $modulesItems
      </item>
      ''' : ''}
      
      ${resourcesItems.length > 0 ? '''
      <item identifier="FOLDER-RESOURCES">
        <title>3. RECURSOS Y EVALUACIÓN</title>
        $resourcesItems
      </item>
      ''' : ''}
    </organization>
  </organizations>
  
  <resources>
    $resourcesDefs
  </resources>
</manifest>''';
  }

  String _stripTags(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
// =============================================================================
// 3. GENERADOR HTML (Motor Visual y Diseño Azul)
// =============================================================================
class HtmlGenerator {
  const HtmlGenerator();
  static const esc = HtmlEscape();

  // ---------------------------------------------------------------------------
  // A. MÉTODOS PÚBLICOS (Estructura de Páginas)
  // ---------------------------------------------------------------------------

  /// Genera la página HTML completa para un módulo específico
  String generateModulePage(CourseModel course, int idx) {
    final module = course.modules[idx];
    final title = esc.convert(module.title);
    
    // Calculamos el progreso porcentual para mostrar en la barra
    final progress = ((idx + 1) / max(1, course.modules.length) * 100).toInt();
    
    // Generamos la botonera de navegación (Anterior / Siguiente)
    final nav = '''
      <div class="nav-area">
        ${idx > 0 
            ? '<a href="module_${idx - 1}.html" class="btn-nav sec">← Anterior</a>' 
            : '<span></span>'}
        
        ${idx < course.modules.length - 1 
            ? '<a href="module_${idx + 1}.html" class="btn-nav pri">Siguiente →</a>' 
            : '<button onclick="alert(\'¡Módulo Finalizado! Puedes repasar o ir al panel.\')" class="btn-nav success">Finalizar Módulo 🎉</button>'}
      </div>''';

    // Construimos el cuerpo: Título + Contenido de Bloques + Navegación
    final body = '''
      <h1 class="page-title">$title</h1>
      <hr class="divider">
      ${renderBlocks(module.blocks)}
      $nav
    ''';

    // Inyectamos todo en la plantilla maestra (Definida en la Parte 4)
    return _generatePageTemplate(title: title, bodyContent: body, progress: progress);
  }

  /// Genera una página estática (Intro, Objetivos, etc.) sin navegación compleja
  String generateStaticPage(CourseModel course, String title, String contentHtml) {
    final body = '''
      <h1 class="page-title">$title</h1>
      <hr class="divider">
      <div class="block text-block">$contentHtml</div>
    ''';
    // Las páginas estáticas no alteran la barra de progreso general
    return _generatePageTemplate(title: title, bodyContent: body, progress: 0);
  }

  // ---------------------------------------------------------------------------
  // B. RENDERIZADO DE BLOQUES (Conversión de Flutter a HTML)
  // ---------------------------------------------------------------------------
  String renderBlocks(List<InteractiveBlock> blocks) {
    if (blocks.isEmpty) return '<div class="empty-state">Sin contenido.</div>';
    
    final buf = StringBuffer();
    
    for (var block in blocks) {
      final type = block.type;
      final content = block.content;
      final id = block.id;

      // --- GRUPO 1: TEXTO Y MULTIMEDIA BÁSICA ---
      if (type == BlockType.textPlain || type == BlockType.textRich || type == BlockType.essay) {
        // Bloques de texto simple o enriquecido
        buf.writeln('<div class="block text-block">${content['text'] ?? ''}</div>');
      
      } else if (type == BlockType.image || type == BlockType.imageHotspot) {
        // Bloques de imagen con pie de foto
        final url = content['url'] ?? '';
        final caption = content['caption'] ?? '';
        buf.writeln('<div class="block media-block center"><img src="$url" alt="Imagen"><p class="caption">$caption</p></div>');
      
      } else if (type == BlockType.video) {
        // Bloques de video (detecta si es YouTube/Vimeo o archivo directo)
        final url = content['url'] ?? '';
        if (url.contains('youtube') || url.contains('vimeo')) {
           buf.writeln('<div class="block video-block"><iframe src="$url" frameborder="0" allowfullscreen></iframe></div>');
        } else {
           buf.writeln('<div class="block video-block"><video controls src="$url"></video></div>');
        }

      } else if (type == BlockType.audio) {
        // Reproductor de audio
        final url = content['url'] ?? '';
        buf.writeln('<div class="block audio-block"><h4>${content['title']??'Audio'}</h4><audio controls src="$url" style="width:100%"></audio></div>');

      } else if (type == BlockType.pdf) {
         // Botón para abrir PDF
         buf.writeln('<div class="block pdf-block"><a href="${content['url']}" target="_blank" class="btn-primary">📄 Ver Documento PDF</a></div>');

      } else if (type == BlockType.embed) {
         // Código embebido (Genially, H5P, etc.)
         buf.writeln('<div class="block embed-block">${content['code'] ?? ''}</div>');

      } else if (type == BlockType.quote) {
         // Citas destacadas
         buf.writeln('<div class="block quote-block"><blockquote>"${content['text']}"</blockquote><cite>- ${content['author']}</cite></div>');

      // --- GRUPO 2: BLOQUES ESTRUCTURALES ---
      } else if (type == BlockType.timeline) {
        // Línea de tiempo vertical
        final events = content['events'] as List? ?? [];
        buf.writeln('<div class="block timeline-block"><h3>Línea de Tiempo</h3><div class="timeline-container">');
        for (var e in events) {
          buf.writeln('<div class="timeline-item"><div class="tl-date">${e['date']}</div><div class="tl-content"><h4>${e['title']}</h4><p>${e['desc']}</p></div></div>');
        }
        buf.writeln('</div></div>');

      } else if (type == BlockType.process) {
        // Pasos numerados (Proceso)
        final steps = content['steps'] as List? ?? [];
        buf.writeln('<div class="block process-block"><h3>Proceso Paso a Paso</h3><div class="process-list">');
        int idx = 1;
        for (var s in steps) {
          buf.writeln('<div class="process-step"><div class="step-num">$idx</div><div class="step-text"><h4>${s['title']}</h4><p>${s['desc']}</p></div></div>');
          idx++;
        }
        buf.writeln('</div></div>');

      } else if (type == BlockType.accordion) {
         // Acordeón desplegable
         final items = content['items'] as List? ?? [];
         buf.writeln('<div class="block accordion-block">');
         for (var item in items) {
           buf.writeln('<details><summary>${item['title']}</summary><div class="details-content">${item['content']}</div></details>');
         }
         buf.writeln('</div>');
         // --- GRUPO 3: ESTRUCTURA AVANZADA (Pestañas / Tabs) ---
      } else if (type == BlockType.tabs) {
         final tabs = content['tabs'] as List? ?? [];
         buf.writeln('<div class="block tabs-block"><div class="tabs-header">');
         // Generamos los botones de las pestañas
         for(int i=0; i<tabs.length; i++) {
            buf.writeln('<button class="tab-btn" onclick="openTab(\'$id\', $i)">${tabs[i]['title']}</button>');
         }
         buf.writeln('</div>');
         // Generamos el contenido de cada pestaña
         for(int i=0; i<tabs.length; i++) {
            buf.writeln('<div id="tab-$id-$i" class="tab-content" style="display:${i==0?"block":"none"}">${tabs[i]['content']}</div>');
         }
         buf.writeln('</div>');

      // --- GRUPO 4: INTERACTIVOS VISUALES (Ordenar, Flashcards, FlipCard) ---
      } else if (type == BlockType.sorting) {
        // Bloque de ordenación (Drag & Drop visual simple)
        final items = List.from(content['items'] ?? []);
        buf.writeln('<div class="block sorting-block"><h3>${content['instruction'] ?? 'Ordena los elementos'}</h3><ul id="sort-$id" class="sortable-list">');
        for(var item in items) {
           buf.writeln('<li class="sort-item" draggable="true">${item['text'] ?? item}</li>');
        }
        buf.writeln('</ul></div>');

      } else if (type == BlockType.flashcards) {
         // Tarjetas de memoria (Flashcards) - Muestra la primera con efecto giro
         final cards = content['cards'] as List? ?? [];
         if(cards.isNotEmpty) {
           buf.writeln('<div class="block flashcard-block" onclick="this.classList.toggle(\'flipped\')"><div class="card-inner"><div class="card-front">${cards[0]['question']}</div><div class="card-back">${cards[0]['answer']}</div></div><p class="hint">Clic para girar (Carta 1/${cards.length})</p></div>');
         }

      } else if (type == BlockType.flipCard) {
         // Tarjeta giratoria simple
         buf.writeln('<div class="block flashcard-block" onclick="this.classList.toggle(\'flipped\')"><div class="card-inner"><div class="card-front">${content['front']}</div><div class="card-back">${content['back']}</div></div></div>');

      // --- GRUPO 5: BLOQUE DE ESTADÍSTICAS INTELIGENTE (Sincronización) ---
      } else if (type == BlockType.stats) {
        // AQUÍ ESTÁ LA SOLUCIÓN DE SINCRONIZACIÓN:
        // Este bloque inyecta un script que "roba" los datos del menú lateral (Dashboard)
        // y los pinta aquí dentro.
        buf.writeln('''
          <div class="block stats-block" style="background:white; padding:30px; border-radius:16px; box-shadow:0 4px 15px rgba(0,0,0,0.05);">
            <div style="display:flex; align-items:center; gap:15px; margin-bottom:20px; border-bottom:1px solid #f1f5f9; padding-bottom:15px">
              <div style="width:50px; height:50px; background:#eff6ff; border-radius:12px; display:flex; align-items:center; justify-content:center; color:#2563EB; font-size:24px">📊</div>
              <div>
                <h3 style="margin:0; color:#1e293b">Tus Métricas</h3>
                <p style="margin:0; font-size:13px; color:#64748b">Datos sincronizados en tiempo real</p>
              </div>
            </div>

            <div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap:20px">
              <div style="background:#f8fafc; padding:20px; border-radius:12px; border:1px solid #e2e8f0; text-align:center">
                <div style="font-size:12px; font-weight:bold; color:#64748b; text-transform:uppercase">Progreso Global</div>
                <div style="font-size:36px; font-weight:800; color:#2563EB; margin:10px 0" id="sync-prog-$id">--%</div>
                <div style="height:6px; background:#cbd5e1; border-radius:3px; overflow:hidden">
                   <div id="sync-bar-$id" style="height:100%; background:#2563EB; width:0%; transition:width 1s"></div>
                </div>
              </div>
              
              <div style="background:#f8fafc; padding:20px; border-radius:12px; border:1px solid #e2e8f0; text-align:center">
                <div style="font-size:12px; font-weight:bold; color:#64748b; text-transform:uppercase">Días de Estudio</div>
                <div style="font-size:36px; font-weight:800; color:#10b981; margin:10px 0" id="sync-days-$id">0</div>
                <div style="font-size:12px; color:#64748b">Días activos en calendario</div>
              </div>
            </div>
            
            <script>
              setTimeout(function() {
                try {
                  // 1. SINCRONIZAR PROGRESO: Busca el valor en el Panel Lateral
                  // La clase '.progress-card strong' se define en la Parte 4
                  var sideProg = document.querySelector('.dash-header .progress-card strong');
                  if(sideProg) {
                    var txt = sideProg.innerText;
                    // Actualiza el texto grande del bloque
                    document.getElementById('sync-prog-$id').innerText = txt;
                    // Actualiza la barra de progreso del bloque
                    document.getElementById('sync-bar-$id').style.width = txt;
                  }
                  
                  // 2. SINCRONIZAR DÍAS: Lee directamente del almacenamiento del navegador
                  var days = JSON.parse(localStorage.getItem('scorm_calendar') || '[]');
                  document.getElementById('sync-days-$id').innerText = days.length;
                } catch(e) { console.log('Error Sync Stats:', e); }
              }, 800); // Pequeño retardo para asegurar que el DOM ha cargado
            </script>
          </div>
        ''');

      // --- GRUPO 6: CUESTIONARIOS Y EVALUACIÓN ---
      } else if ([BlockType.singleChoice, BlockType.multipleChoice, BlockType.trueFalse, BlockType.questionSet].contains(type)) {
        // Lógica para renderizar preguntas tipo test
        final question = esc.convert(content['question'] ?? 'Pregunta');
        final options = List.from(content['options'] ?? []);
        // Extraemos índices correctos para la validación JS
        final correctIndices = List.from(content['correctIndices'] ?? (content['correctIndex'] != null ? [content['correctIndex']] : []));
        final jsArray = jsonEncode(correctIndices.map((e) => int.tryParse(e.toString()) ?? 0).toList());
        final inputType = (type == BlockType.multipleChoice) ? 'checkbox' : 'radio';

        buf.writeln('<div class="block quiz-block"><h3>$question</h3><div class="options">');
        for (int i = 0; i < options.length; i++) {
          buf.writeln('<label><input type="$inputType" name="q-$id" value="$i"> ${esc.convert(options[i].toString())}</label>');
        }
        // Botón que llama a la función checkQuiz (definida en Parte 4)
        buf.writeln('</div><button class="btn-primary" onclick=\'checkQuiz("${id}", $jsArray)\'>Comprobar</button><div id="fb-$id" class="feedback"></div></div>');
      
      } else {
        // Fallback para tipos de bloque no reconocidos o futuros (FillBlanks, etc.)
        buf.writeln('<div class="block generic">Bloque: ${type.name}</div>');
      }
    } // Fin del bucle for
    
    return buf.toString();
  }
  // ---------------------------------------------------------------------------
  // C. PLANTILLA MAESTRA (HTML + CSS + JS DASHBOARD)
  // ---------------------------------------------------------------------------
  String _generatePageTemplate({
    required String title,
    required String bodyContent,
    required int progress,
  }) {
    return '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <style>
    /* --- VARIABLES DE TEMA (DISEÑO AZUL PROFESIONAL) --- */
    :root { 
      --primary: #2563EB; 
      --primary-dark: #1e40af;
      --bg-body: #F8FAFC; 
      --sidebar-w: 340px; 
      --header-h: 64px; 
      --text-main: #334155; 
      --text-light: #64748b;
      --success: #10b981;
      --error: #ef4444;
    }
    
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
    
    body { background: var(--bg-body); color: var(--text-main); height: 100vh; display: flex; overflow: hidden; }

    /* --- LAYOUT PRINCIPAL --- */
    .main-area { 
      flex: 1; display: flex; flex-direction: column; 
      transition: margin-right 0.3s ease; 
    }
    
    .header { 
      height: var(--header-h); background: white; border-bottom: 1px solid #e2e8f0; 
      display: flex; align-items: center; justify-content: space-between; padding: 0 24px; 
      box-shadow: 0 1px 2px rgba(0,0,0,0.03); z-index: 10;
    }

    .brand { font-weight: 700; font-size: 18px; color: var(--primary-dark); display: flex; align-items: center; gap: 10px; }
    
    .content-scroll { flex: 1; overflow-y: auto; padding: 40px 24px; scroll-behavior: smooth; }
    .content-wrapper { max-width: 850px; margin: 0 auto; width: 100%; padding-bottom: 80px; }

    /* --- SIDEBAR RETRÁCTIL (DASHBOARD) --- */
    .sidebar { 
      width: var(--sidebar-w); background: white; border-left: 1px solid #e2e8f0; 
      height: 100vh; display: flex; flex-direction: column; 
      position: fixed; right: 0; top: 0; 
      transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1); 
      z-index: 1000; 
      box-shadow: -4px 0 20px rgba(0,0,0,0.05); 
    }
    
    .sidebar.closed { transform: translateX(100%); }
    
    /* Botón Toggle en Cabecera */
    .toggle-btn { 
      cursor: pointer; background: #eff6ff; color: var(--primary); 
      border: 1px solid #dbeafe; padding: 8px 16px; border-radius: 8px; 
      font-weight: 600; font-size: 14px; transition: all 0.2s;
      display: flex; align-items: center; gap: 6px;
    }
    .toggle-btn:hover { background: #dbeafe; }

    /* --- ESTILOS DE BLOQUES DE CONTENIDO --- */
    .page-title { font-size: 28px; font-weight: 800; color: #1e293b; margin-bottom: 16px; letter-spacing: -0.5px; }
    .divider { border: 0; border-top: 1px solid #e2e8f0; margin: 24px 0; }
    
    .block { 
      background: white; padding: 30px; border-radius: 16px; margin-bottom: 24px; 
      box-shadow: 0 2px 4px rgba(0,0,0,0.02); border: 1px solid #f1f5f9; 
    }
    .block h3 { margin-bottom: 15px; color: #1e293b; border-bottom: 1px solid #f1f5f9; padding-bottom: 10px; }

    /* Media */
    .media-block.center { text-align: center; }
    .media-block img { max-width: 100%; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1); }
    .caption { font-size: 13px; color: var(--text-light); margin-top: 10px; font-style: italic; }
    .video-block iframe, .video-block video { width: 100%; border-radius: 8px; aspect-ratio: 16/9; }
    .quote-block { border-left: 4px solid var(--primary); padding-left: 20px; font-style: italic; color: #555; background: #f8fafc; padding: 20px; border-radius: 0 12px 12px 0; }

    /* Timeline */
    .timeline-container { position: relative; padding-left: 10px; }
    .timeline-item { border-left: 2px solid var(--primary); padding-left: 25px; margin-bottom: 25px; position: relative; }
    .timeline-item::before { 
      content:''; position: absolute; left: -7px; top: 0; width: 12px; height: 12px; 
      background: var(--primary); border: 2px solid white; border-radius: 50%; box-shadow: 0 0 0 2px var(--primary);
    }
    .tl-date { font-size: 12px; font-weight: bold; color: var(--primary); text-transform: uppercase; margin-bottom: 4px; }
    
    /* Process */
    .process-step { display: flex; gap: 20px; margin-bottom: 20px; align-items: flex-start; }
    .step-num { 
      width: 36px; height: 36px; background: var(--primary); color: white; 
      border-radius: 50%; display: flex; align-items: center; justify-content: center; 
      font-weight: bold; font-size: 16px; flex-shrink: 0; box-shadow: 0 2px 4px rgba(37,99,235,0.3);
    }

    /* Interactivos */
    .flashcard-block { height: 240px; perspective: 1000px; cursor: pointer; user-select: none; }
    .card-inner { position: relative; width: 100%; height: 100%; transition: transform 0.6s cubic-bezier(0.4,0,0.2,1); transform-style: preserve-3d; }
    .flashcard-block.flipped .card-inner { transform: rotateY(180deg); }
    .card-front, .card-back { 
      position: absolute; width: 100%; height: 100%; backface-visibility: hidden; 
      display: flex; align-items: center; justify-content: center; padding: 30px; 
      font-size: 20px; text-align: center; border-radius: 16px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
    }
    .card-front { background: white; border: 1px solid #e2e8f0; color: #1e293b; }
    .card-back { background: #eff6ff; border: 1px solid #bfdbfe; color: var(--primary-dark); transform: rotateY(180deg); font-weight: bold; }

    .sortable-list { list-style: none; padding: 0; }
    .sort-item { 
      background: #f8fafc; border: 1px solid #e2e8f0; padding: 12px 16px; margin-bottom: 8px; 
      border-radius: 8px; cursor: move; display: flex; align-items: center; gap: 10px;
    }
    .sort-item::before { content: '☰'; color: #94a3b8; }
    
    .nav-area { display: flex; justify-content: space-between; margin-top: 40px; padding-top: 20px; border-top: 1px solid #e2e8f0; }
    .btn-nav { 
      padding: 12px 24px; border-radius: 10px; text-decoration: none; font-weight: 600; 
      font-size: 14px; border: none; cursor: pointer; transition: transform 0.1s;
    }
    .btn-nav:active { transform: scale(0.98); }
    .btn-nav.pri { background: var(--primary); color: white; box-shadow: 0 4px 6px -1px rgba(37,99,235,0.3); }
    .btn-nav.sec { background: white; border: 1px solid #e2e8f0; color: #334155; }
    .btn-nav.success { background: var(--success); color: white; }

    /* Tabs */
    .tabs-header { display: flex; gap: 10px; border-bottom: 2px solid #e2e8f0; margin-bottom: 20px; }
    .tab-btn { background: none; border: none; padding: 10px 15px; cursor: pointer; font-weight: 600; color: #64748b; border-bottom: 2px solid transparent; margin-bottom: -2px; }
    .tab-btn:hover { color: var(--primary); border-bottom-color: var(--primary); }

    /* --- ESTILOS DEL DASHBOARD (SIDEBAR) --- */
    .dash-header { padding: 24px; border-bottom: 1px solid #f1f5f9; background: white; }
    .dash-top-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
    .dash-title { font-size: 14px; font-weight: 700; color: #0f172a; text-transform: uppercase; letter-spacing: 0.5px; }
    .close-icon { font-size: 24px; cursor: pointer; color: #94a3b8; line-height: 1; border: none; background: none; }
    
    .progress-card { background: #f1f5f9; padding: 16px; border-radius: 12px; }
    .progress-track { height: 8px; background: #cbd5e1; border-radius: 4px; overflow: hidden; margin: 10px 0; }
    .progress-fill { height: 100%; background: var(--primary); width: $progress%; transition: width 1s ease-out; }
    
    .dash-body { flex: 1; overflow-y: auto; padding: 24px; background: #F8FAFC; }
    
    /* Widget: Calendario */
    .widget-card { background: white; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.02); }
    .widget-title { font-size: 12px; font-weight: 700; color: #64748b; margin-bottom: 12px; display: flex; align-items: center; gap: 6px; }
    
    .cal-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; text-align: center; font-size: 12px; }
    .cal-cell { padding: 6px 0; border-radius: 6px; color: #475569; cursor: pointer; transition: background 0.2s; }
    .cal-cell:hover { background: #e2e8f0; }
    .cal-head { font-weight: bold; color: #94a3b8; font-size: 10px; cursor: default; }
    .cal-head:hover { background: none; }
    .cal-active { background: var(--primary); color: white; font-weight: bold; }
    .cal-active:hover { background: var(--primary-dark); }
    
    /* Widget: Chat/Mensajes */
    .msg-list { display: flex; flex-direction: column; gap: 10px; max-height: 150px; overflow-y: auto; margin-bottom: 10px; }
    .msg-bubble { background: #f1f5f9; padding: 8px 12px; border-radius: 8px; font-size: 12px; color: #334155; }
    .msg-input-area { display: flex; gap: 6px; }
    .msg-input { flex: 1; border: 1px solid #e2e8f0; border-radius: 6px; padding: 6px; font-size: 12px; }
    
    /* Widget: Hitos */
    .milestone { display: flex; align-items: center; gap: 12px; padding: 8px 0; border-bottom: 1px dashed #e2e8f0; }
    .milestone:last-child { border-bottom: none; }
    .ms-dot { width: 10px; height: 10px; background: var(--success); border-radius: 50%; box-shadow: 0 0 0 2px #d1fae5; }
    
    /* Widget: Soporte */
    .support-card { 
      background: linear-gradient(135deg, #1e40af, #3b82f6); 
      color: white; padding: 20px; border-radius: 16px; margin-top: 10px;
      display: flex; align-items: center; gap: 16px; cursor: pointer;
      box-shadow: 0 10px 15px -3px rgba(37,99,235,0.4); transition: transform 0.2s;
    }
    .support-card:hover { transform: translateY(-2px); }
    
    /* Responsive Mobile */
    @media (max-width: 768px) {
      .sidebar { width: 100%; max-width: 320px; }
      .content-wrapper { padding: 10px; }
      .block { padding: 20px; }
    }
  </style>
</head>
<body>

  <div class="main-area" id="mainArea">
    <div class="header">
      <div class="brand">
        <span style="font-size:24px">🎓</span> <span>Módulo de Aprendizaje</span>
      </div>
      <button class="toggle-btn" onclick="toggleSidebar()">
        <span>📊</span> <span>Mi Panel</span>
      </button>
    </div>
    
    <div class="content-scroll">
      <div class="content-wrapper">
        $bodyContent
      </div>
    </div>
  </div>

  <div class="sidebar" id="sidebar">
    <div class="dash-header">
      <div class="dash-top-row">
        <span class="dash-title">TU PROGRESO</span>
        <button class="close-icon" onclick="toggleSidebar()">✕</button>
      </div>
      
      <div class="progress-card">
        <div style="display:flex; justify-content:space-between; font-size:12px; color:#475569; margin-bottom:5px;">
           <span>Completado</span> <strong>$progress%</strong>
        </div>
        <div class="progress-track"><div class="progress-fill"></div></div>
        <div style="font-size:11px; color:#64748b; text-align:right">Sigue así, vas muy bien.</div>
      </div>
    </div>

    <div class="dash-body">
      
      <div class="widget-card">
        <div class="widget-title"><span>📅</span> CALENDARIO ESTUDIO</div>
        <div class="cal-grid" id="calendarGrid">
           <div class="cal-cell cal-head">L</div><div class="cal-cell cal-head">M</div><div class="cal-cell cal-head">X</div><div class="cal-cell cal-head">J</div><div class="cal-cell cal-head">V</div><div class="cal-cell cal-head">S</div><div class="cal-cell cal-head">D</div>
           <div class="cal-cell day" onclick="toggleDay(this)">1</div><div class="cal-cell day" onclick="toggleDay(this)">2</div><div class="cal-cell day" onclick="toggleDay(this)">3</div><div class="cal-cell day" onclick="toggleDay(this)">4</div><div class="cal-cell day" onclick="toggleDay(this)">5</div><div class="cal-cell day" onclick="toggleDay(this)">6</div><div class="cal-cell day" onclick="toggleDay(this)">7</div>
           <div class="cal-cell day" onclick="toggleDay(this)">8</div><div class="cal-cell day" onclick="toggleDay(this)">9</div><div class="cal-cell day" onclick="toggleDay(this)">10</div><div class="cal-cell day" onclick="toggleDay(this)">11</div><div class="cal-cell day" onclick="toggleDay(this)">12</div><div class="cal-cell day" onclick="toggleDay(this)">13</div><div class="cal-cell day" onclick="toggleDay(this)">14</div>
           <div class="cal-cell day" onclick="toggleDay(this)">15</div><div class="cal-cell day" onclick="toggleDay(this)">16</div><div class="cal-cell day" onclick="toggleDay(this)">17</div><div class="cal-cell day" onclick="toggleDay(this)">18</div><div class="cal-cell day" onclick="toggleDay(this)">19</div><div class="cal-cell day" onclick="toggleDay(this)">20</div><div class="cal-cell day" onclick="toggleDay(this)">21</div>
           <div class="cal-cell day" onclick="toggleDay(this)">22</div><div class="cal-cell day" onclick="toggleDay(this)">23</div><div class="cal-cell day" onclick="toggleDay(this)">24</div><div class="cal-cell day" onclick="toggleDay(this)">25</div><div class="cal-cell day" onclick="toggleDay(this)">26</div><div class="cal-cell day" onclick="toggleDay(this)">27</div><div class="cal-cell day" onclick="toggleDay(this)">28</div>
        </div>
      </div>

      <div class="widget-card">
        <div class="widget-title"><span>💬</span> NOTAS Y AVISOS</div>
        <div class="msg-list" id="chatList">
           <div class="msg-bubble"><strong>Sistema:</strong> Bienvenido al curso. Recuerda completar el módulo 1 antes del viernes.</div>
        </div>
        <div class="msg-input-area">
           <input type="text" id="chatInput" class="msg-input" placeholder="Escribir nota..." onkeypress="if(event.key==='Enter') sendNote()">
           <button onclick="sendNote()" style="background:var(--primary); color:white; border:none; border-radius:6px; width:30px">➤</button>
        </div>
      </div>

      <div class="support-card" onclick="window.location.href='mailto:soporte@curso.com'">
        <div style="font-size:24px">🎧</div>
        <div>
          <div style="font-weight:bold; font-size:14px">Soporte Técnico</div>
          <div style="font-size:11px; opacity:0.9">Click para contactar</div>
        </div>
      </div>
      
    </div>
  </div>

  <script>
    // --- LÓGICA JAVASCRIPT DEL DASHBOARD ---
    
    // 1. Sidebar Toggle
    function toggleSidebar() {
      const sb = document.getElementById('sidebar');
      sb.classList.toggle('closed');
    }

    // 2. Quiz Checker (Para bloques de evaluación)
    function checkQuiz(id, correctIndices) {
      const inputs = document.getElementsByName('q-' + id);
      let selected = [];
      for(let i=0; i<inputs.length; i++) {
        if(inputs[i].checked) selected.push(i);
      }
      const fb = document.getElementById('fb-' + id);
      const isCorrect = JSON.stringify(selected.sort()) === JSON.stringify(correctIndices.sort());
      
      if(isCorrect) {
        fb.innerHTML = '<div style="background:#dcfce7; color:#166534; padding:10px; border-radius:6px; margin-top:10px; font-weight:bold">✅ ¡Respuesta Correcta!</div>';
      } else {
        fb.innerHTML = '<div style="background:#fee2e2; color:#991b1b; padding:10px; border-radius:6px; margin-top:10px; font-weight:bold">❌ Respuesta Incorrecta.</div>';
      }
    }

    // 3. Tab System
    function openTab(blockId, index) {
       const contents = document.querySelectorAll('[id^="tab-' + blockId + '-"]');
       contents.forEach(c => c.style.display = 'none');
       document.getElementById('tab-' + blockId + '-' + index).style.display = 'block';
    }

    // 4. Notes System (LocalStorage Persistence)
    function sendNote() {
      const input = document.getElementById('chatInput');
      const text = input.value;
      if(!text) return;
      
      const list = document.getElementById('chatList');
      const div = document.createElement('div');
      div.className = 'msg-bubble';
      div.style.marginTop = '5px';
      div.innerHTML = '<strong>Tú:</strong> ' + text;
      list.appendChild(div);
      
      let notes = JSON.parse(localStorage.getItem('scorm_notes') || '[]');
      notes.push(text);
      localStorage.setItem('scorm_notes', JSON.stringify(notes));
      input.value = '';
      list.scrollTop = list.scrollHeight;
    }

    // 5. Calendar System (LocalStorage Persistence)
    function toggleDay(el) {
       el.classList.toggle('cal-active');
       saveCalendar();
    }

    function saveCalendar() {
       const activeDays = [];
       document.querySelectorAll('.cal-active').forEach(el => {
          if(el.classList.contains('day')) activeDays.push(el.innerText);
       });
       localStorage.setItem('scorm_calendar', JSON.stringify(activeDays));
    }

    function loadCalendar() {
       const activeDays = JSON.parse(localStorage.getItem('scorm_calendar') || '[]');
       const allDays = document.querySelectorAll('.cal-cell.day');
       allDays.forEach(day => {
          if(activeDays.includes(day.innerText)) {
             day.classList.add('cal-active');
          }
       });
    }

    // INIT
    window.onload = function() {
      // Cargar Notas
      const notes = JSON.parse(localStorage.getItem('scorm_notes') || '[]');
      const list = document.getElementById('chatList');
      notes.forEach(n => {
        const div = document.createElement('div');
        div.className = 'msg-bubble';
        div.style.marginTop = '5px';
        div.innerHTML = '<strong>Tú:</strong> ' + n;
        list.appendChild(div);
      });

      // Cargar Calendario
      loadCalendar();
      
      // Auto-cerrar sidebar en móvil
      if(window.innerWidth < 1000) {
        document.getElementById('sidebar').classList.add('closed');
      }
    };
  </script>
</body>
</html>
    ''';
  }
}
