import 'dart:convert';
import 'dart:math';

import '../../models/course_model.dart';
import '../../models/module_model.dart';
import '../../models/interactive_block.dart';
import 'scorm_ui_architect.dart';

class HtmlGenerator {
  const HtmlGenerator();
  static const esc = HtmlEscape();

  String generateModulePage(
    CourseModel course,
    int idx, {
    Map<String, String>? assetMap,
  }) {
    final module = course.modules[idx];
    final title = esc.convert(module.title);
    final progress = ((idx + 1) / max(1, course.modules.length) * 100).toInt();
    final heroHtml = _buildHero(module, idx);
    final blocksHtml = renderBlocks(
      module.blocks,
      assetMap: assetMap,
      heroOverlap: true,
    );
    final nav = '''
      <div class="nav-area">
        ${idx > 0 ? '<a href="module_${idx - 1}.html" class="btn-nav sec magnetic" onclick="return navigateModule(\'module_${idx - 1}.html\')">← Anterior</a>' : '<span></span>'}

        ${idx < course.modules.length - 1 ? '<a href="module_${idx + 1}.html" class="btn-nav pri magnetic" onclick="return navigateModule(\'module_${idx + 1}.html\')">Siguiente →</a>' : '<button class="btn-nav success magnetic" onclick="launchConfetti(80); alert(\'¡Módulo Finalizado! Puedes repasar o ir al panel.\')">Finalizar Módulo 🎉</button>'}
      </div>''';
    final footer = _buildReferenceFooter(course.referenceModule);
    final modal = _buildReferenceModal(course.referenceModule);
    final body = '''
      <section class="module-shell" style="--hero-gradient:${_heroGradient(idx)};">
        $heroHtml
        <div class="module-body">
          $blocksHtml
          $nav
          $footer
        </div>
      </section>
      $modal
    ''';
    return ScormUiArchitect.buildPage(
        title: title, bodyContent: body, progress: progress);
  }

  String generateStaticPage(
    CourseModel course,
    String title,
    String contentHtml,
  ) {
    final body = '''
      <h1 class="page-title">$title</h1>
      <hr class="divider">
      <div class="block text-block">$contentHtml</div>
    ''';
    return ScormUiArchitect.buildPage(
        title: title, bodyContent: body, progress: 0);
  }

  String renderBlocks(List<InteractiveBlock> blocks,
      {Map<String, String>? assetMap, bool heroOverlap = false}) {
    if (blocks.isEmpty) return '<div class="empty-state">Sin contenido.</div>';

    final buf = StringBuffer();
    var blockIndex = 0;

    var overlapApplied = false;

    for (var block in blocks) {
      final type = block.type;
      final content = block.content;
      final id = block.id;
      final rawId = id.isNotEmpty ? id : 'auto-${blockIndex + 1}';
      final safeId = _safeIdFrom(rawId);
      final label = _labelForBlock(type, content);
      final kind = _haloKindForBlock(type);
      buf.writeln(
          '<section class="block-wrap staggered" id="block-$safeId" data-block-label="$label" data-block-index="$blockIndex" data-block-kind="$kind"><div class="card-educativa">');

      final shouldOverlap =
          heroOverlap && !overlapApplied && _isTextBlock(type);
      final htmlBlock = _renderBlockHtml(
        type: type,
        content: content,
        safeId: safeId,
        assetMap: assetMap,
        heroOverlap: shouldOverlap,
      );
      if (shouldOverlap && htmlBlock.trim().isNotEmpty) {
        overlapApplied = true;
      }

      if (htmlBlock.trim().isEmpty && _hasMeaningfulContent(content)) {}

      if (htmlBlock.trim().isNotEmpty) {
        buf.writeln(htmlBlock);
      } else if (_hasMeaningfulContent(content)) {
        buf.writeln(
            '<div class="block generic">[Error de Renderizado en bloque ${type.name}]</div>');
      } else {
        buf.writeln('<div class="block generic">Bloque: ${type.name}</div>');
      }

      buf.writeln('</div></section>');
      blockIndex++;
    }

    return buf.toString();
  }

  String _renderBlockHtml({
    required BlockType type,
    required Map<String, dynamic> content,
    required String safeId,
    Map<String, String>? assetMap,
    bool heroOverlap = false,
  }) {
    if (type == BlockType.textPlain ||
        type == BlockType.textRich ||
        type == BlockType.essay) {
      final text = _extractTextValue(content);
      final safeText = (text ?? '').trim().isNotEmpty ? text! : ' ';
      final classes = ['block', 'text-block'];
      if (heroOverlap) {
        classes.add('hero-overlap');
      }
      return '<div class="${classes.join(' ')}">$safeText</div>';
    } else if (type == BlockType.image || type == BlockType.imageHotspot) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final url = _resolveAsset(
          _stringFrom(content,
                  const ['url', 'imageUrl', 'imagePath', 'path', 'src']) ??
              '',
          assetMap);
      final caption =
          _stringFrom(content, const ['caption', 'title', 'alt']) ?? '';
      final imageHtml = url.isNotEmpty ? '<img src="$url" alt="Imagen">' : '';
      final captionHtml =
          caption.isNotEmpty ? '<p class="caption">$caption</p>' : '';
      final hotspots =
          _listFrom(content, const ['hotspots', 'points', 'areas']);
      final hotspotHtml = _hotspotListHtml(hotspots);
      return '<div class="block media-block center">$imageHtml$captionHtml$hotspotHtml</div>';
    } else if (type == BlockType.video) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final url = _resolveAsset(
          _stringFrom(content,
                  const ['url', 'videoUrl', 'videoPath', 'path', 'src']) ??
              '',
          assetMap);
      if (url.contains('youtube') || url.contains('vimeo')) {
        return '<div class="block video-block"><iframe src="$url" frameborder="0" allowfullscreen></iframe></div>';
      }
      return '<div class="block video-block"><video controls src="$url"></video></div>';
    } else if (type == BlockType.audio) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final url = _resolveAsset(
          _stringFrom(content,
                  const ['url', 'audioUrl', 'audioPath', 'path', 'src']) ??
              '',
          assetMap);
      final title =
          _stringFrom(content, const ['title', 'label', 'name']) ?? 'Audio';
      return '<div class="block audio-block"><h4>$title</h4><audio controls src="$url" style="width:100%"></audio></div>';
    } else if (type == BlockType.pdf) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final url = _resolveAsset(
          _stringFrom(
                  content, const ['url', 'pdfUrl', 'pdfPath', 'path', 'src']) ??
              '',
          assetMap);
      return '<div class="block pdf-block"><a href="$url" target="_blank" class="btn-primary">📄 Ver Documento PDF</a></div>';
    } else if (type == BlockType.urlResource) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final url =
          _stringFrom(content, const ['url', 'link', 'href', 'src']) ?? '';
      final label = _stringFrom(content, const ['label', 'title', 'text']) ??
          'Abrir recurso';
      return '<div class="block pdf-block"><a href="$url" target="_blank" class="btn-primary">🔗 $label</a></div>';
    } else if (type == BlockType.embed) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final code = _stringFrom(content,
              const ['code', 'embed', 'embedCode', 'html', 'iframe']) ??
          '';
      return '<div class="block embed-block">$code</div>';
    } else if (type == BlockType.quote) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final text = _stringFrom(
              content, const ['text', 'quote', 'content', 'description']) ??
          '';
      final author =
          _stringFrom(content, const ['author', 'by', 'source']) ?? '';
      return '<div class="block quote-block"><blockquote>"$text"</blockquote><cite>- $author</cite></div>';
    } else if (type == BlockType.timeline) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final events = _listFrom(content, const ['events', 'items', 'steps']);
      final buf = StringBuffer(
          '<div class="block timeline-block"><h3>Línea de Tiempo</h3><div class="timeline-container">');
      for (final e in events) {
        final map =
            (e is Map) ? e.cast<String, dynamic>() : <String, dynamic>{};
        final label = (map['date'] ?? map['label'] ?? '').toString();
        final title = (map['title'] ?? 'Evento').toString();
        final desc = (map['desc'] ?? map['description'] ?? '').toString();
        buf.writeln(
            '<div class="timeline-item"><div class="tl-date">$label</div><div class="tl-content"><h4>$title</h4><p>$desc</p></div></div>');
      }
      buf.writeln('</div></div>');
      return buf.toString();
    } else if (type == BlockType.process) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final steps = _listFrom(content, const ['steps', 'items', 'process']);
      final buf = StringBuffer(
          '<div class="block process-block"><h3>Proceso Paso a Paso</h3><div class="process-list">');
      int idx = 1;
      for (final s in steps) {
        final map =
            (s is Map) ? s.cast<String, dynamic>() : <String, dynamic>{};
        final title = (map['title'] ?? 'Paso $idx').toString();
        final desc = (map['desc'] ?? map['description'] ?? '').toString();
        buf.writeln(
            '<div class="process-step"><div class="step-num">$idx</div><div class="step-text"><h4>$title</h4><p>$desc</p></div></div>');
        idx++;
      }
      buf.writeln('</div></div>');
      return buf.toString();
    } else if (type == BlockType.accordion) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final items =
          _listFrom(content, const ['items', 'sections', 'accordionItems']);
      final buf = StringBuffer('<div class="block accordion-block">');
      for (final item in items) {
        final map =
            (item is Map) ? item.cast<String, dynamic>() : <String, dynamic>{};
        final title = (map['title'] ?? map['label'] ?? '').toString();
        final body = (map['content'] ?? map['body'] ?? map['description'] ?? '')
            .toString();
        buf.writeln(
            '<details><summary>$title</summary><div class="details-content">$body</div></details>');
      }
      buf.writeln('</div>');
      return buf.toString();
    } else if (type == BlockType.tabs) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final tabs = _listFrom(content, const ['tabs', 'items', 'sections']);
      final buf = StringBuffer(
          '<div class="block tabs-block"><div class="tabs-header">');
      for (int i = 0; i < tabs.length; i++) {
        final map = (tabs[i] is Map)
            ? (tabs[i] as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        final title =
            (map['title'] ?? map['label'] ?? 'Pestaña ${i + 1}').toString();
        buf.writeln(
            '<button class="tab-btn" onclick="openTab(\'$safeId\', $i)">$title</button>');
      }
      buf.writeln('</div>');
      for (int i = 0; i < tabs.length; i++) {
        final map = (tabs[i] is Map)
            ? (tabs[i] as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        final body = (map['content'] ?? map['body'] ?? map['description'] ?? '')
            .toString();
        buf.writeln(
            '<div id="tab-$safeId-$i" class="tab-content" style="display:${i == 0 ? "block" : "none"}">$body</div>');
      }
      buf.writeln('</div>');
      return buf.toString();
    } else if (type == BlockType.sorting) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final items = _listFrom(content, const ['items', 'options', 'choices']);
      final instruction =
          _stringFrom(content, const ['instruction', 'prompt', 'title']) ??
              'Ordena los elementos';
      final buf = StringBuffer(
          '<div class="block sorting-block"><h3>$instruction</h3><ul id="sort-$safeId" class="sortable-list">');
      for (final item in items) {
        final map =
            (item is Map) ? item.cast<String, dynamic>() : <String, dynamic>{};
        final text = (map['text'] ?? map['label'] ?? item).toString();
        buf.writeln('<li class="sort-item" draggable="true">$text</li>');
      }
      buf.writeln('</ul></div>');
      return buf.toString();
    } else if (type == BlockType.fillBlanks) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final rawText =
          (_stringFrom(content, const ['text', 'statement', 'prompt']) ?? '')
              .toString();
      final filled = _renderFillBlanksText(rawText, blockId: safeId);
      return '<div class="block fillblanks-block" id="fill-$safeId"><h3>Rellenar Huecos</h3><div class="fillblanks-text">$filled</div><button class="btn-primary" onclick="checkFillBlanks(\'$safeId\')">Comprobar</button><div id="fb-$safeId" class="feedback"></div></div>';
    } else if (type == BlockType.matching) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      var leftItems = _listFrom(content, const ['leftItems', 'left']);
      var rightItems = _listFrom(content, const ['rightItems', 'right']);
      if (leftItems.isEmpty || rightItems.isEmpty) {
        final pairs = _listFrom(content, const ['pairs', 'items']);
        if (pairs.isNotEmpty) {
          leftItems = [];
          rightItems = [];
          for (var i = 0; i < pairs.length; i++) {
            final pair = (pairs[i] is Map)
                ? (pairs[i] as Map).cast<String, dynamic>()
                : <String, dynamic>{};
            leftItems.add({
              'id': 'l$i',
              'text': pair['left'] ?? pair['a'] ?? pair['term'] ?? ''
            });
            rightItems.add({
              'id': 'r$i',
              'text': pair['right'] ?? pair['b'] ?? pair['definition'] ?? ''
            });
          }
        }
      }
      final buf = StringBuffer(
          '<div class="block matching-block" id="match-$safeId"><h3>Relacionar conceptos</h3><div class="matching-list">');
      var matchRowIndex = 0;
      for (final left in leftItems) {
        final leftMap =
            (left is Map) ? left.cast<String, dynamic>() : <String, dynamic>{};
        final leftId = leftMap['id'] ?? '';
        final leftText = esc.convert(leftMap['text']?.toString() ?? '');
        final selectId = 'input-$safeId-$matchRowIndex';
        buf.writeln(
            '<div class="matching-row"><span class="match-label">$leftText</span><select id="$selectId" name="input-$safeId-$matchRowIndex" data-correct="$leftId"><option value="">Selecciona...</option>');
        for (final right in rightItems) {
          final rightMap = (right is Map)
              ? right.cast<String, dynamic>()
              : <String, dynamic>{};
          final rightId = rightMap['id'] ?? '';
          final rightText = esc.convert(rightMap['text']?.toString() ?? '');
          buf.writeln('<option value="$rightId">$rightText</option>');
        }
        buf.writeln('</select></div>');
        matchRowIndex++;
      }
      buf.writeln(
          '</div><button class="btn-primary" onclick="checkMatching(\'$safeId\')">Comprobar</button><div id="fb-$safeId" class="feedback"></div></div>');
      return buf.toString();
    } else if (type == BlockType.flashcards) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final cards = _listFrom(content, const ['cards', 'flashcards', 'items']);
      if (cards.isNotEmpty) {
        final firstCard = (cards.first is Map)
            ? (cards.first as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        final front = esc.convert((firstCard['frontText'] ??
                firstCard['question'] ??
                firstCard['front'] ??
                '')
            .toString());
        final back = esc.convert((firstCard['backText'] ??
                firstCard['answer'] ??
                firstCard['back'] ??
                '')
            .toString());
        return '<div class="block flashcard-block" onclick="this.classList.toggle(\'flipped\')"><div class="card-inner"><div class="card-front">$front</div><div class="card-back">$back</div></div><p class="hint">Clic para girar (Carta 1/${cards.length})</p></div>';
      }
      return '';
    } else if (type == BlockType.flipCard) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final front =
          _stringFrom(content, const ['front', 'frontText', 'question']) ?? '';
      final back =
          _stringFrom(content, const ['back', 'backText', 'answer']) ?? '';
      return '<div class="block flashcard-block" onclick="this.classList.toggle(\'flipped\')"><div class="card-inner"><div class="card-front">$front</div><div class="card-back">$back</div></div></div>';
    } else if (type == BlockType.stats) {
      return '''
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
                <div style="font-size:36px; font-weight:800; color:#2563EB; margin:10px 0" id="sync-prog-$safeId">--%</div>
                <div style="height:6px; background:#cbd5e1; border-radius:3px; overflow:hidden">
                   <div id="sync-bar-$safeId" style="height:100%; background:#2563EB; width:0%; transition:width 1s"></div>
                </div>
              </div>
              
              <div style="background:#f8fafc; padding:20px; border-radius:12px; border:1px solid #e2e8f0; text-align:center">
                <div style="font-size:12px; font-weight:bold; color:#64748b; text-transform:uppercase">Días de Estudio</div>
                <div style="font-size:36px; font-weight:800; color:#10b981; margin:10px 0" id="sync-days-$safeId">0</div>
                <div style="font-size:12px; color:#64748b">Días activos en calendario</div>
              </div>
            </div>
            
            <script>
              setTimeout(function() {
                try {
                  var sideProg = document.querySelector('.dash-header .progress-card strong');
                  if(sideProg) {
                    var txt = sideProg.innerText;
                    document.getElementById('sync-prog-$safeId').innerText = txt;
                    document.getElementById('sync-bar-$safeId').style.width = txt;
                  }
                  
                  var days = JSON.parse(localStorage.getItem('scorm_calendar') || '[]');
                  document.getElementById('sync-days-$safeId').innerText = days.length;
                } catch(e) { console.log('Error Sync Stats:', e); }
              }, 800);
            </script>
          </div>
        ''';
    } else if ([
      BlockType.singleChoice,
      BlockType.multipleChoice,
      BlockType.trueFalse,
      BlockType.questionSet
    ].contains(type)) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final question = esc.convert(
          _stringFrom(content, const ['question', 'prompt', 'title']) ??
              'Pregunta');
      final options =
          _listFrom(content, const ['options', 'choices', 'answers']);
      final correctIndices = List.from(content['correctIndices'] ??
          (content['correctIndex'] != null
              ? [content['correctIndex']]
              : (content['correctAnswer'] != null
                  ? [content['correctAnswer']]
                  : [])));
      final jsArray = jsonEncode(
          correctIndices.map((e) => int.tryParse(e.toString()) ?? 0).toList());
      final inputType =
          (type == BlockType.multipleChoice) ? 'checkbox' : 'radio';
      final buf = StringBuffer(
          '<div class="block quiz-block"><h3>$question</h3><div class="options">');
      for (int i = 0; i < options.length; i++) {
        buf.writeln(
            '<label><input type="$inputType" id="input-$safeId-$i" name="input-$safeId-$i" value="$i"> ${esc.convert(options[i].toString())}</label>');
      }
      buf.writeln(
          '</div><button class="btn-primary" onclick=\'checkQuiz("$safeId", $jsArray)\'>Comprobar</button><div id="fb-$safeId" class="feedback"></div></div>');
      return buf.toString();
    } else if (type == BlockType.scenario) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final introText = esc.convert(_stringFrom(
              content, const ['introText', 'prompt', 'description', 'text']) ??
          'Situacion a resolver');
      final imagePath = _resolveAsset(
          _stringFrom(content, const ['imagePath', 'path', 'url', 'src']) ?? '',
          assetMap);
      final options =
          _listFrom(content, const ['options', 'choices', 'answers']);
      final buf = StringBuffer(
          '<div class="block scenario-block" id="scenario-$safeId"><h3>Escenario</h3><p>$introText</p>');
      if (imagePath.isNotEmpty) {
        buf.writeln(
            '<div class="media-block center"><img src="$imagePath" alt="Escenario"></div>');
      }
      buf.writeln('<div class="scenario-options">');
      for (final option in options) {
        final optMap = (option is Map)
            ? option.cast<String, dynamic>()
            : <String, dynamic>{};
        final text = esc.convert(optMap['text']?.toString() ?? 'Opcion');
        final feedback = jsonEncode(optMap['feedback']?.toString() ?? '');
        final isCorrect = optMap['isCorrect'] == true;
        buf.writeln(
            '<button class="btn-primary" onclick="selectScenario(\'$safeId\', ${isCorrect ? 'true' : 'false'}, $feedback)">$text</button>');
      }
      buf.writeln(
          '</div><div id="scenario-fb-$safeId" class="feedback"></div></div>');
      return buf.toString();
    } else if (type == BlockType.carousel) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final items = _listFrom(content, const ['items', 'images', 'slides']);
      if (items.isEmpty) return '';
      final buf = StringBuffer(
          '<div class="block media-block center"><div class="carousel">');
      for (final item in items) {
        final map =
            (item is Map) ? item.cast<String, dynamic>() : <String, dynamic>{};
        final url = _resolveAsset(
            (map['url'] ?? map['image'] ?? map['src'] ?? '').toString(),
            assetMap);
        if (url.isEmpty) continue;
        buf.writeln('<img src="$url" alt="Slide">');
      }
      buf.writeln('</div></div>');
      return buf.toString();
    } else if (type == BlockType.comparison) {
      final hasContent = _hasMeaningfulContent(content);
      if (!hasContent) {
        return '<div class="block text-block">Contenido pendiente para ${type.name}.</div>';
      }
      final itemA = _mapFrom(content, const ['itemA', 'left', 'a']);
      final itemB = _mapFrom(content, const ['itemB', 'right', 'b']);
      final titleA = (itemA['title'] ?? itemA['label'] ?? 'Item A').toString();
      final titleB = (itemB['title'] ?? itemB['label'] ?? 'Item B').toString();
      final descA =
          (itemA['description'] ?? itemA['desc'] ?? itemA['content'] ?? '')
              .toString();
      final descB =
          (itemB['description'] ?? itemB['desc'] ?? itemB['content'] ?? '')
              .toString();
      return '<div class="block comparison-block"><div class="comparison-col"><h4>$titleA</h4><p>$descA</p></div><div class="comparison-col"><h4>$titleB</h4><p>$descB</p></div></div>';
    }

    return '';
  }

  String? _stringFrom(Map<String, dynamic> content, List<String> keys) {
    for (final key in keys) {
      final value = content[key];
      if (value == null) continue;
      final str = value.toString();
      if (str.trim().isNotEmpty) return str;
    }
    return null;
  }

  List<dynamic> _listFrom(Map<String, dynamic> content, List<String> keys) {
    for (final key in keys) {
      final value = content[key];
      if (value is List) return value;
    }
    return <dynamic>[];
  }

  Map<String, dynamic> _mapFrom(
      Map<String, dynamic> content, List<String> keys) {
    for (final key in keys) {
      final value = content[key];
      if (value is Map) return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  String _hotspotListHtml(List<dynamic> hotspots) {
    if (hotspots.isEmpty) return '';
    final buf = StringBuffer('<div class="hotspot-list"><ul>');
    for (final spot in hotspots) {
      final map =
          (spot is Map) ? spot.cast<String, dynamic>() : <String, dynamic>{};
      final label =
          (map['label'] ?? map['title'] ?? map['text'] ?? '').toString();
      if (label.isEmpty) continue;
      buf.writeln('<li>$label</li>');
    }
    buf.writeln('</ul></div>');
    return buf.toString();
  }

  bool _hasMeaningfulContent(Map<String, dynamic> content) {
    if (content.isEmpty) return false;
    for (final value in content.values) {
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      if (value is List && value.isEmpty) continue;
      if (value is Map && value.isEmpty) continue;
      return true;
    }
    return false;
  }

  String _resolveAsset(String url, Map<String, String>? assetMap) {
    if (url.isEmpty || assetMap == null) return url;
    return assetMap[url] ?? url;
  }

  String? _extractTextValue(Map<String, dynamic> content) {
    final direct =
        _stringFrom(content, const ['text', 'content', 'html', 'description']);
    if (direct != null && direct.trim().isNotEmpty) return direct;
    for (final value in content.values) {
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _safeIdFrom(String rawId) {
    final sanitized = rawId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    if (sanitized.length <= 32) return sanitized;
    var hash = 2166136261;
    for (final codeUnit in sanitized.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    final shortHash = hash.toUnsigned(32).toRadixString(36);
    return 'h$shortHash';
  }

  String _renderFillBlanksText(String rawText, {required String blockId}) {
    final String safeId = blockId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    if (rawText.trim().isEmpty) {
      return esc.convert('Escribe la frase con *palabras* a completar.');
    }
    final buffer = StringBuffer();
    var blankIndex = 0;
    final regex = RegExp(r'\\*([^*]+)\\*');
    var lastIndex = 0;
    for (final match in regex.allMatches(rawText)) {
      final start = match.start;
      final end = match.end;
      if (start > lastIndex) {
        buffer.write(esc.convert(rawText.substring(lastIndex, start)));
      }
      final answer = match.group(1) ?? '';
      final safeAnswer = esc.convert(answer);
      buffer.write(
          '<input type="text" id="input-$safeId-$blankIndex" name="input-$safeId-$blankIndex" class="blank-input" data-answer="$safeAnswer">');
      blankIndex++;
      lastIndex = end;
    }
    if (lastIndex < rawText.length) {
      buffer.write(esc.convert(rawText.substring(lastIndex)));
    }
    return buffer.toString();
  }

  String _labelForBlock(BlockType type, Map<String, dynamic> content) {
    switch (type) {
      case BlockType.textPlain:
      case BlockType.textRich:
        return 'Texto';
      case BlockType.image:
        return 'Imagen';
      case BlockType.video:
        return 'Video';
      case BlockType.audio:
        return 'Audio';
      case BlockType.pdf:
        return 'PDF';
      case BlockType.timeline:
        return 'Linea de tiempo';
      case BlockType.process:
        return 'Proceso';
      case BlockType.accordion:
        return 'Acordeon';
      case BlockType.tabs:
        return 'Pestanas';
      case BlockType.flashcards:
        return 'Flashcards';
      case BlockType.sorting:
        return 'Ordenar';
      case BlockType.matching:
        return 'Relacionar';
      case BlockType.fillBlanks:
        return 'Rellenar huecos';
      case BlockType.singleChoice:
      case BlockType.multipleChoice:
      case BlockType.trueFalse:
      case BlockType.questionSet:
        return 'Quiz';
      case BlockType.scenario:
        return 'Escenario';
      default:
        return type.name;
    }
  }

  String _haloKindForBlock(BlockType type) {
    switch (type) {
      case BlockType.textPlain:
      case BlockType.textRich:
      case BlockType.image:
      case BlockType.accordion:
      case BlockType.quote:
      case BlockType.embed:
      case BlockType.pdf:
        return 'info';
      case BlockType.video:
      case BlockType.audio:
      case BlockType.carousel:
        return 'media';
      case BlockType.singleChoice:
      case BlockType.multipleChoice:
      case BlockType.trueFalse:
      case BlockType.questionSet:
      case BlockType.matching:
      case BlockType.flashcards:
      case BlockType.fillBlanks:
        return 'quiz';
      case BlockType.timeline:
      case BlockType.process:
        return 'process';
      default:
        return 'info';
    }
  }

  bool _isTextBlock(BlockType type) {
    return type == BlockType.textPlain ||
        type == BlockType.textRich ||
        type == BlockType.essay;
  }

  String _buildHero(ModuleModel module, int index) {
    final title = esc.convert(module.title);
    final duration = _estimateDuration(module);
    return '''
      <div class="module-hero">
        <span class="hero-pill">Lección ${index + 1}</span>
        <h1>$title</h1>
        <div class="hero-meta">
          <span class="hero-time">⏱ $duration min aprox.</span>
        </div>
      </div>
    ''';
  }

  String _heroGradient(int index) {
    const gradients = [
      'linear-gradient(135deg,#2563EB,#7C3AED)',
      'linear-gradient(135deg,#0EA5E9,#22D3EE)',
      'linear-gradient(135deg,#9333EA,#F472B6)',
      'linear-gradient(135deg,#4C1D95,#F59E0B)',
      'linear-gradient(135deg,#10B981,#059669)',
      'linear-gradient(135deg,#14B8A6,#06B6D4)',
    ];
    return gradients[index % gradients.length];
  }

  int _estimateDuration(ModuleModel module) {
    final base = module.blocks.length * 3 + 5;
    return max(8, min(base, 45));
  }

  String _buildReferenceFooter(ModuleModel? referenceModule) {
    if (referenceModule == null) return '';
    return '''
      <footer class="reference-footer">
        <a href="#" class="reference-link" onclick="openReferenceModal(event)">Ver material original</a>
      </footer>
    ''';
  }

  String _buildReferenceModal(ModuleModel? referenceModule) {
    if (referenceModule == null) return '';
    final display = referenceModule.content.trim().isEmpty
        ? 'El manuscrito original está archivado aquí para consulta.'
        : referenceModule.content;
    final safeBody = esc.convert(display);
    final safeTitle = esc.convert(referenceModule.title);
    return '''
      <div id="referenceModal" class="reference-modal">
        <div class="reference-card">
          <button class="modal-close" onclick="closeReferenceModal(event)">×</button>
          <h3>$safeTitle</h3>
          <div class="reference-body"><pre>$safeBody</pre></div>
        </div>
      </div>
      <script>
        function openReferenceModal(event) {
          event.preventDefault();
          document.getElementById('referenceModal')?.classList.add('visible');
        }
        function closeReferenceModal(event) {
          event?.preventDefault();
          document.getElementById('referenceModal')?.classList.remove('visible');
        }
      </script>
    ''';
  }
}
