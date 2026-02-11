import 'dart:convert';

import '../../models/course_model.dart';

class ManifestGenerator {
  const ManifestGenerator();
  static const esc = HtmlEscape();

  String generateManifest(
    CourseModel course, {
    Set<String>? enabledStaticSections,
    List<String>? assetFiles,
  }) {
    final safeId = 'COURSE_${DateTime.now().millisecondsSinceEpoch}';
    final safeTitle = esc.convert(course.title);
    bool isEnabled(String sectionId) {
      return enabledStaticSections == null ||
          enabledStaticSections.contains(sectionId);
    }

    final introMetadata =
        isEnabled('intro') ? _stripTags(course.introText) : '';
    final objectivesMetadata = isEnabled('objectives')
        ? course.objectives
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .join('; ')
        : '';

    final metadataExtra = StringBuffer();
    if (introMetadata.isNotEmpty) {
      metadataExtra
          .writeln('<description>${esc.convert(introMetadata)}</description>');
    }
    if (objectivesMetadata.isNotEmpty) {
      metadataExtra
          .writeln('<keywords>${esc.convert(objectivesMetadata)}</keywords>');
    }

    StringBuffer modulesItems = StringBuffer();
    StringBuffer guideItems = StringBuffer();
    StringBuffer resourcesItems = StringBuffer();
    StringBuffer resourcesDefs = StringBuffer();

    for (int i = 0; i < course.modules.length; i++) {
      final modId = 'MOD_$i';
      final file = 'module_$i.html';
      final title = esc.convert(course.modules[i].title);
      modulesItems.writeln(
          '<item identifier="ITEM-$modId" identifierref="RES-$modId"><title>Módulo ${i + 1}: $title</title></item>');
      resourcesDefs.writeln(
          '<resource identifier="RES-$modId" type="webcontent" adlcp:scormtype="sco" href="$file"><file href="$file"/></resource>');
    }

    void addGuideItem({
      required String sectionId,
      required String itemId,
      required String resourceId,
      required String title,
      required String file,
    }) {
      if (!isEnabled(sectionId)) return;
      guideItems.writeln(
          '<item identifier="$itemId" identifierref="$resourceId"><title>$title</title></item>');
      resourcesDefs.writeln(
          '<resource identifier="$resourceId" type="webcontent" adlcp:scormtype="asset" href="$file"><file href="$file"/></resource>');
    }

    void addResourceItem({
      required String sectionId,
      required String itemId,
      required String resourceId,
      required String title,
      required String file,
    }) {
      if (!isEnabled(sectionId)) return;
      resourcesItems.writeln(
          '<item identifier="$itemId" identifierref="$resourceId"><title>$title</title></item>');
      resourcesDefs.writeln(
          '<resource identifier="$resourceId" type="webcontent" adlcp:scormtype="asset" href="$file"><file href="$file"/></resource>');
    }

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
    addGuideItem(
      sectionId: 'manuscript',
      itemId: 'ITEM-MANU',
      resourceId: 'RES-MANU',
      title: '1.5 Manuscrito Maestro',
      file: 'manuscrito.html',
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

    if (assetFiles != null && assetFiles.isNotEmpty) {
      for (int i = 0; i < assetFiles.length; i++) {
        final assetPath = assetFiles[i].trim();
        if (assetPath.isEmpty) continue;
        final safePath = esc.convert(assetPath);
        resourcesDefs.writeln(
            '<resource identifier="RES-ASSET-$i" type="webcontent" adlcp:scormtype="asset" href="$safePath"><file href="$safePath"/></resource>');
      }
    }

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
