import 'dart:io'; // NECESARIO para Linux (escribir en disco)
import 'dart:convert'; // Para utf8 y HtmlEscape
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart'; // Para encontrar carpetas en Linux
import 'package:path/path.dart' as p; // Para unir rutas de forma segura

// Asegúrate de que estas rutas a tus modelos sean correctas
import '../../models/course_model.dart';
import '../../models/module_model.dart';
import '../../models/interactive_block.dart';

// ==========================================
// CLASE 1: GENERADOR DE HTML (Estilos y JS)
// ==========================================
class HtmlGenerator {
  String generateModuleHtml(ModuleModel module) {
    final safeTitle = const HtmlEscape().convert(module.title);
    final buffer = StringBuffer();
    
    // HTML5 Boilerplate & Estilos Mejorados (TU CÓDIGO ORIGINAL)
    buffer.writeln('''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$safeTitle</title>
    <style>
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; max-width: 1000px; margin: 0 auto; padding: 20px; background: #ffffff; color: #2d3436; line-height: 1.6; }
        
        /* Minimal Header */
        .module-header { text-align: center; margin-bottom: 60px; padding-bottom: 20px; border-bottom: 1px solid #eee; }
        .module-header h1 { font-size: 2.5em; font-weight: 300; color: #333; margin: 0; }
        
        /* Seamless Blocks (No Box/Cajon) */
        .block { margin-bottom: 50px; padding: 0; background: transparent; border: none; box-shadow: none; }
        .block h3 { font-size: 1.4em; margin-bottom: 15px; color: #444; }
        
        /* Content Styling */
        .block-text { font-size: 1.1em; }
        .block-image, .block-video { text-align: center; margin: 40px 0; }
        .block-image img, .block-video video { max-width: 100%; border-radius: 8px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }
        .hotspot-container { box-shadow: 0 10px 30px rgba(0,0,0,0.15); border-radius: 8px; overflow: hidden; }
        
        /* Interactions Styling */
        .btn-check, .btn-option { background: white; border: 1px solid #ddd; padding: 12px 20px; border-radius: 6px; cursor: pointer; font-size: 1em; transition: all 0.2s; color: #333; }
        .btn-check:hover, .btn-option:hover { border-color: #333; background: #f9f9f9; }
        .btn-check { background: #333; color: white; border: none; padding: 12px 30px; }
        .btn-check:hover { background: #000; transform: translateY(-2px); }
        
        /* Feedback */
        .feedback { margin-top: 15px; padding: 15px; border-radius: 6px; font-weight: 500; }
        .feedback.correct { color: #00b894; background: #e6fffa; }
        .feedback.incorrect { color: #d63031; background: #fff5f5; }
        
        /* Interactive Elements */
        .card-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 20px; }
        .flip-card { background: white; border: 1px solid #eaeaea; padding: 30px; border-radius: 12px; cursor: pointer; min-height: 140px; display: flex; align-items: center; justify-content: center; text-align: center; box-shadow: 0 4px 6px rgba(0,0,0,0.02); transition: transform 0.3s; }
        .flip-card:hover { transform: translateY(-5px); box-shadow: 0 10px 20px rgba(0,0,0,0.05); }
        .flip-card.flipped { background: #fff8e1; border-color: #ffe082; }

        .accordion-item { border-bottom: 1px solid #eee; }
        .accordion-header { padding: 20px 0; cursor: pointer; font-weight: 600; display: flex; justify-content: space-between; font-size: 1.1em; }
        .accordion-content { padding: 0 0 20px 0; display: none; color: #666; }
        .accordion-item.active .accordion-content { display: block; }
        
        /* Hotspots */
        .hotspot-container { position: relative; display: inline-block; max-width: 100%; }
        .hotspot-img { display: block; max-width: 100%; height: auto; }
        .hotspot-point { position: absolute; width: 30px; height: 30px; background: rgba(50, 50, 50, 0.9); border: 3px solid white; border-radius: 50%; cursor: pointer; transform: translate(-50%, -50%); box-shadow: 0 4px 8px rgba(0,0,0,0.2); transition: transform 0.2s; }
        .hotspot-point:hover { transform: translate(-50%, -50%) scale(1.1); background: #000; }
        .hotspot-tooltip { position: absolute; background: #222; color: white; padding: 8px 14px; border-radius: 6px; font-size: 14px; pointer-events: none; opacity: 0; transition: opacity 0.2s; white-space: nowrap; z-index: 100; bottom: 120%; left: 50%; transform: translateX(-50%); }
        .hotspot-point:hover .hotspot-tooltip { opacity: 1; }
    </style>
    <script>
        var API = null;
        function findAPI(win) {
            if (win.API != null) return win.API;
            if (win.parent == win || win.parent == null) return null;
            return findAPI(win.parent);
        }
        function initSCORM() {
            API = findAPI(window);
            if (API) { API.LMSInitialize(""); API.LMSSetValue("cmi.core.lesson_status", "incomplete"); API.LMSCommit(""); }
        }
        function finishSCORM() {
            if (API) { API.LMSSetValue("cmi.core.lesson_status", "completed"); API.LMSCommit(""); API.LMSFinish(""); }
        }
        window.onload = initSCORM;
        window.onunload = finishSCORM;

        // INTERACTION LOGIC
        function toggleAccordion(header) {
            header.parentElement.classList.toggle('active');
        }
        function flipCard(card) {
            card.classList.toggle('flipped');
        }
        function checkQuiz(id, correctIdx) {
            const selected = document.querySelector('input[name="q-'+id+'"]:checked');
            const fb = document.getElementById('fb-'+id);
            if (!selected) return;
            if (parseInt(selected.value) === correctIdx) {
                fb.innerHTML = "¡Correcto!"; fb.className = "feedback correct";
            } else {
                fb.innerHTML = "Incorrecto"; fb.className = "feedback incorrect";
            }
            fb.style.display = 'block';
        }
    </script>
</head>
<body>
    <div class="module-header">
        <h1>$safeTitle</h1>
    </div>
''');

    for (var block in module.blocks) {
      if (block.type == BlockType.textPlain || block.type == BlockType.essay) {
        // Soporte para HTML renderizado (WYSIWYG)
        final text = block.content['text'] ?? block.content['question'] ?? '';
        buffer.writeln('<div class="block block-text">$text</div>');
        
      } else if ([BlockType.imageHotspot, BlockType.findHotspot, BlockType.dragAndDrop].contains(block.type)) {
        // HOTSPOTS & VISUALS
        final url = block.content['url'] ?? '';
        final title = const HtmlEscape().convert(block.content['title'] ?? '');
        final zones = block.content['zones'] as List? ?? [];
        
        buffer.writeln('<div class="block block-visual"><h3>$title</h3><div class="hotspot-container">');
        buffer.writeln('<img src="$url" class="hotspot-img" alt="Interactive Image">');
        
        for (var zone in zones) {
           final x = zone['x'] ?? 0;
           final y = zone['y'] ?? 0;
           final label = const HtmlEscape().convert(zone['label'] ?? 'Info');
           buffer.writeln('<div class="hotspot-point" style="left: $x%; top: $y%;"><div class="hotspot-tooltip">$label</div></div>');
        }
        buffer.writeln('</div></div>');
        
      } else if ([BlockType.singleChoice, BlockType.multipleChoice, BlockType.trueFalse].contains(block.type)) {
        // QUIZZES
        final question = const HtmlEscape().convert(block.content['question'] ?? 'Pregunta');
        final options = block.content['options'] as List? ?? []; 
        final correctIdx = block.content['correctIndex'] ?? 0; 
        
        buffer.writeln('<div class="block block-quiz"><h3>$question</h3><div class="options">');
        
        List<Map<String, dynamic>> optsNorm = [];
        if (options.isNotEmpty && options.first is String) {
           for(int i=0; i<options.length; i++) {
             optsNorm.add({'text': options[i], 'correct': i == correctIdx});
           }
        } else {
           optsNorm = List<Map<String, dynamic>>.from(options.map((e) => Map<String, dynamic>.from(e)));
        }

        int correctIndexFound = -1;
        for (int i = 0; i < optsNorm.length; i++) {
           final optText = const HtmlEscape().convert(optsNorm[i]['text']);
           if (optsNorm[i]['correct'] == true) correctIndexFound = i;
           buffer.writeln('<label style="display:block; margin: 8px 0;"><input type="radio" name="q-${block.id}" value="$i"> $optText</label>');
        }
        
        buffer.writeln('</div><button class="btn-check" onclick="checkQuiz(\'${block.id}\', $correctIndexFound)">Comprobar</button>');
        buffer.writeln('<div id="fb-${block.id}" class="feedback"></div></div>');

      } else if ([BlockType.accordion, BlockType.flashcards].contains(block.type)) {
        // ACCORDION & LISTS
        final items = block.content['items'] as List? ?? [];
        buffer.writeln('<div class="block"><h3>${const HtmlEscape().convert(block.content['title']??"Lista")}</h3>');
        
        if (block.type == BlockType.accordion) {
            for (var item in items) {
                buffer.writeln('<div class="accordion-item"><div class="accordion-header" onclick="toggleAccordion(this)">${item['front']} <span>▼</span></div><div class="accordion-content">${item['back']}</div></div>');
            }
        } else {
            buffer.writeln('<div class="card-grid">');
            for (var item in items) {
                buffer.writeln('<div class="flip-card" onclick="flipCard(this)"><div class="front">${item['front']}</div></div>');
            }
            buffer.writeln('</div>'); 
        }
        buffer.writeln('</div>');

      } else if (block.type == BlockType.video) {
        // VIDEO SUPPORT
        final url = block.content['url'] ?? '';
        final title = const HtmlEscape().convert(block.content['title'] ?? 'Video');
        buffer.writeln('<div class="block block-video"><h3>$title</h3>');
        if (url.startsWith('https://')) {
          if (url.contains('youtube') || url.contains('vimeo')) {
             buffer.writeln('<p><a href="$url" target="_blank">Ver Video Externo</a></p>');
          } else {
             buffer.writeln('<video controls width="100%" src="$url">Tu navegador no soporta video.</video>');
          }
        } else if (url.startsWith('data:video')) {
          buffer.writeln('<video controls width="100%" src="$url">Tu navegador no soporta video.</video>');
        }
        buffer.writeln('</div>');
      } else {
        buffer.writeln('<div class="block"><p><em>Bloque tipo ${block.type.name} no visualizable en preview simple.</em></p></div>');
      }
    }

    buffer.writeln('<div style="text-align: center; margin: 40px 0;"><button onclick="finishSCORM()" class="btn-check" style="background: #333;">Finalizar Módulo</button></div></body></html>');
    return buffer.toString();
  }
}

// ==========================================
// CLASE 2: GENERADOR DE MANIFIESTO (XML)
// ==========================================
class ManifestGenerator {
  
  String _sanitize(String input) {
    if (input.isEmpty) return "GENERIC_ID";
    return input
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '_'); 
  }

  String generateManifest(CourseModel course) {
    final safeCourseId = _sanitize(course.id.isNotEmpty ? course.id : 'COURSE_1');
    final safeOrgId = 'ORG_$safeCourseId';
    final courseTitle = const HtmlEscape().convert(course.title.isNotEmpty ? course.title : 'Curso SCORM');

    StringBuffer itemsBuffer = StringBuffer();
    StringBuffer resourcesBuffer = StringBuffer();

    for (int i = 0; i < course.modules.length; i++) {
      final modId = 'MODULE_${i + 1}';
      final fileName = 'module_$i.html';
      final modTitle = const HtmlEscape().convert(course.modules[i].title);

      itemsBuffer.writeln('''
      <item identifier="ITEM-$modId" identifierref="RES-$modId">
        <title>$modTitle</title>
      </item>''');

      resourcesBuffer.writeln('''
      <resource identifier="RES-$modId" type="webcontent" adlcp:scormtype="sco" href="$fileName">
        <file href="$fileName"/>
      </resource>''');
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<manifest identifier="MANIFEST-$safeCourseId" version="1.2"
          xmlns="http://www.imsproject.org/xsd/imscp_rootv1p1p2"
          xmlns:adlcp="http://www.adlnet.org/xsd/adlcp_rootv1p2"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://www.imsproject.org/xsd/imscp_rootv1p1p2 imscp_rootv1p1p2.xsd
                              http://www.imsproject.org/xsd/imsmd_rootv1p2p1 imsmd_rootv1p2p1.xsd
                              http://www.adlnet.org/xsd/adlcp_rootv1p2 adlcp_rootv1p2.xsd">
  <metadata>
    <schema>ADL SCORM</schema>
    <schemaversion>1.2</schemaversion>
  </metadata>
  <organizations default="$safeOrgId">
    <organization identifier="$safeOrgId">
      <title>$courseTitle</title>
      $itemsBuffer
    </organization>
  </organizations>
  <resources>
    $resourcesBuffer
  </resources>
</manifest>''';
  }
}

// ==========================================
// CLASE 3: SERVICIO DE EXPORTACIÓN (LINUX)
// ==========================================
class ScormExportService {
  final HtmlGenerator _htmlGen = HtmlGenerator();
  final ManifestGenerator _manifestGen = ManifestGenerator();

  // Cambiado: Devuelve Future<String> con la ruta del archivo generado
  Future<String> exportCourse(CourseModel course) async {
    final archive = Archive();

    // 1. GENERAR MANIFIESTO
    final manifestString = _manifestGen.generateManifest(course);
    final manifestBytes = utf8.encode(manifestString); 
    // Corregido length vs bytes
    archive.addFile(ArchiveFile('imsmanifest.xml', manifestBytes.length, manifestBytes));

    // 2. GENERAR MÓDULOS HTML
    for (int i = 0; i < course.modules.length; i++) {
      final htmlString = _htmlGen.generateModuleHtml(course.modules[i]);
      final htmlBytes = utf8.encode(htmlString);
      archive.addFile(ArchiveFile('module_$i.html', htmlBytes.length, htmlBytes));
    }

    // 3. COMPRIMIR A ZIP EN MEMORIA
    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);

    if (zipData == null) {
      throw Exception("Error crítico: No se pudo generar el archivo ZIP.");
    }

    // 4. GUARDAR EN DISCO DURO (LÓGICA LINUX/DESKTOP)
    try {
      // Obtenemos la ruta de Documentos del usuario en Linux
      // Esto devuelve algo como /home/tu_usuario/Documents
      final directory = await getApplicationDocumentsDirectory();
      
      // Limpiamos el nombre del archivo
      String safeTitle = course.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
      String fileName = 'scorm_$safeTitle.zip';
      
      // Construimos la ruta completa
      final File file = File(p.join(directory.path, fileName));
      
      // Escribimos los datos
      await file.writeAsBytes(zipData);
      
      print('✅ Archivo SCORM generado exitosamente en: ${file.path}');
      return file.path; // Retornamos la ruta para mostrarla en la UI

    } catch (e) {
      print('❌ Error guardando archivo en disco: $e');
      throw Exception("No se pudo guardar el archivo en Linux: $e");
    }
  }
}