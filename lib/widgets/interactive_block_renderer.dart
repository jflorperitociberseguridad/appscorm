import 'package:flutter/material.dart';
import '../models/interactive_block.dart';

// =============================================================================
// 1. IMPORTACIONES: VISUAL (Multimedia y Diseño)
// =============================================================================
import 'interactives/visual/text_plain_widget.dart'; 
import 'interactives/visual/image_widget.dart';
import 'interactives/visual/video_widget.dart';
import 'interactives/visual/audio_widget.dart';       
import 'interactives/visual/pdf_widget.dart';         
import 'interactives/visual/carousel_widget.dart';    
import 'interactives/visual/flip_card_widget.dart';   
import 'interactives/visual/quote_widget.dart';       
import 'interactives/visual/embed_widget.dart';       
import 'interactives/visual/image_hotspot_widget.dart';
import 'interactives/visual/estadisticas_widget.dart'; 

// =============================================================================
// 2. IMPORTACIONES: ESTRUCTURA (Organización)
// =============================================================================
import 'interactives/structure/accordion_widget.dart';
import 'interactives/structure/tabs_widget.dart';       
import 'interactives/structure/process_widget.dart';    
import 'interactives/structure/timeline_widget.dart';   
import 'interactives/structure/comparison_widget.dart'; 
import 'interactives/structure/scenario_widget.dart';   

// =============================================================================
// 3. IMPORTACIONES: QUIZ Y EVALUACIÓN
// =============================================================================
import 'interactives/quiz/single_choice_widget.dart';   
import 'interactives/quiz/multiple_choice_widget.dart'; 
import 'interactives/quiz/true_false_widget.dart';      
import 'interactives/quiz/fill_blanks_widget.dart';     
import 'interactives/quiz/sorting_widget.dart';         
import 'interactives/quiz/flashcards_widget.dart';      
import 'interactives/quiz/matching_widget.dart';


// =============================================================================
// RENDERIZADOR MAESTRO DE BLOQUES
// =============================================================================

class InteractiveBlockRenderer extends StatelessWidget {
  final InteractiveBlock block;
  final VoidCallback? onDelete; // ✅ AÑADIDO: Para que funcione el botón de borrar
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;

  const InteractiveBlockRenderer({
    super.key, 
    required this.block,
    this.onDelete,
    this.onEdit,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    // Envolvemos el contenido en el contenedor con barra gris y flechas
    return _BlockContainer(
      blockType: block.type,
      xp: _extractXp(block.content),
      isLocked: _extractIsLocked(block.content),
      onDelete: onDelete,
      onEdit: onEdit,
      onDuplicate: onDuplicate,
      child: _buildContent(context),
    );
  }

  // LÓGICA ORIGINAL (No borrada, solo movida aquí)
  Widget _buildContent(BuildContext context) {
    switch (block.type) {
      // --- GRUPO 1: VISUAL ---
      case BlockType.textPlain:
      case BlockType.textRich: 
        return TextPlainWidget(block: block); 

      case BlockType.image:
        return ImageWidget(block: block);

      case BlockType.video:
        return VideoWidget(block: block);

      case BlockType.audio:
        return AudioWidget(block: block);

      case BlockType.pdf:
        return PdfWidget(block: block);

      case BlockType.carousel:
        return CarouselWidget(block: block);

      case BlockType.flipCard:
        return FlipCardWidget(block: block);

      case BlockType.quote:
        return QuoteWidget(block: block);

      case BlockType.embed:
        return EmbedWidget(block: block);

      case BlockType.imageHotspot:
        return ImageHotspotWidget(block: block);
      
      case BlockType.stats: 
        return EstadisticasWidget(block: block);

      // --- GRUPO 2: ESTRUCTURA ---
      case BlockType.accordion:
        return AccordionWidget(block: block);

      case BlockType.tabs:
        return TabsWidget(block: block);

      case BlockType.process:
        return ProcessWidget(block: block);

      case BlockType.timeline:
        return TimelineWidget(block: block);

      case BlockType.comparison:
        return ComparisonWidget(block: block);

      case BlockType.scenario:
        return ScenarioWidget(block: block);

      // --- GRUPO 3: QUIZ / EVALUACIÓN ---
      case BlockType.singleChoice:
        return SingleChoiceWidget(block: block);

      case BlockType.multipleChoice:
        return MultipleChoiceWidget(block: block);

      case BlockType.trueFalse:
        return TrueFalseWidget(block: block);

      case BlockType.fillBlanks:
        return FillBlanksWidget(block: block);

      case BlockType.sorting:
        return SortingWidget(block: block); 

      case BlockType.flashcards:
        return FlashcardsWidget(block: block);

      case BlockType.matching:
        return MatchingWidget(block: block);

      // --- PLACEHOLDERS ---
      case BlockType.interactiveBook:
      case BlockType.column:
      case BlockType.coursePresentation:
      case BlockType.agamotto:
      case BlockType.dragAndDrop:
      case BlockType.markWords:
      case BlockType.dialogCards:
      case BlockType.findHotspot:
      case BlockType.findMultipleHotspots:
      case BlockType.urlResource:
      case BlockType.essay:
      case BlockType.questionSet:
      case BlockType.unknown:
        return _PlaceholderFeatureBlock(
          icon: _iconForType(block.type),
          title: block.type.name,
        );
    }
  }

  // ===========================================================================
  // MÉTODOS AUXILIARES
  // ===========================================================================

}
// =============================================================================
// CLASE PRIVADA: CONTENEDOR VISUAL (BARRA GRIS Y EXPANSIÓN)
// =============================================================================

class _BlockContainer extends StatefulWidget {
  final BlockType blockType;
  final Widget child;
  final VoidCallback? onDelete; // Callback para borrar
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final int? xp;
  final bool isLocked;

  const _BlockContainer({
    required this.blockType,
    required this.child,
    this.xp,
    this.isLocked = false,
    this.onDelete,
    this.onEdit,
    this.onDuplicate,
  });

  @override
  State<_BlockContainer> createState() => _BlockContainerState();
}

class _BlockContainerState extends State<_BlockContainer> {
  // Controla si el bloque está desplegado o recogido
  bool _isExpanded = true; 

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. BARRA DE TÍTULO (CABECERA GRIS)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                // Icono del tipo de bloque
                Icon(_getIconForType(widget.blockType), size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                
                // Nombre del bloque (en mayúsculas)
                Expanded(
                  child: Text(
                    widget.blockType.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),

                if (widget.xp != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${widget.xp} XP',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),

                if (widget.isLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock, size: 16, color: Colors.red),
                  ),

                // Botones de acción
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.indigo, size: 20),
                      tooltip: widget.onEdit != null ? "Editar bloque" : "Editar (no disponible)",
                      onPressed: widget.onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_all_outlined, color: Colors.teal, size: 20),
                      tooltip: widget.onDuplicate != null ? "Duplicar bloque" : "Duplicar (no disponible)",
                      onPressed: widget.onDuplicate,
                    ),
                    // Botón Expandir/Contraer
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      tooltip: _isExpanded ? "Contraer bloque" : "Expandir bloque",
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                    
                    // Botón Borrar (Solo si se pasa la función onDelete)
                    if (widget.onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        tooltip: "Eliminar bloque",
                        onPressed: widget.onDelete,
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 2. CONTENIDO DEL BLOQUE (VISIBLE SOLO SI ESTÁ EXPANDIDO)
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(12),
              // Aquí va el widget específico (Editor, Imagen, Quiz, etc.)
              child: widget.child, 
            ),
        ],
      ),
    );
  }

  // Helper para iconos bonitos según el tipo
  IconData _getIconForType(BlockType type) {
    switch (type) {
      case BlockType.textPlain: return Icons.text_fields;
      case BlockType.textRich: return Icons.article;
      case BlockType.image: return Icons.image;
      case BlockType.video: return Icons.movie;
      case BlockType.audio: return Icons.audiotrack;
      case BlockType.pdf: return Icons.picture_as_pdf;
      case BlockType.carousel: return Icons.view_carousel;
      case BlockType.flipCard: return Icons.flip;
      case BlockType.quote: return Icons.format_quote;
      case BlockType.embed: return Icons.code;
      case BlockType.imageHotspot: return Icons.ads_click;
      case BlockType.stats: return Icons.bar_chart;
      
      case BlockType.accordion: return Icons.expand;
      case BlockType.tabs: return Icons.tab;
      case BlockType.process: return Icons.linear_scale;
      case BlockType.timeline: return Icons.timeline;
      case BlockType.comparison: return Icons.compare;
      case BlockType.scenario: return Icons.psychology; // Escenario / Simulación
      
      case BlockType.singleChoice: return Icons.radio_button_checked;
      case BlockType.multipleChoice: return Icons.check_box;
      case BlockType.trueFalse: return Icons.thumbs_up_down;
      case BlockType.fillBlanks: return Icons.border_color;
      case BlockType.sorting: return Icons.sort;
      case BlockType.flashcards: return Icons.style;
      case BlockType.interactiveBook: return Icons.menu_book;
      case BlockType.column: return Icons.view_column;
      case BlockType.coursePresentation: return Icons.slideshow;
      case BlockType.agamotto: return Icons.layers;
      case BlockType.dragAndDrop: return Icons.drag_indicator;
      case BlockType.markWords: return Icons.highlight;
      case BlockType.dialogCards: return Icons.chat_bubble_outline;
      case BlockType.findHotspot: return Icons.my_location;
      case BlockType.findMultipleHotspots: return Icons.location_searching;
      case BlockType.urlResource: return Icons.link;
      case BlockType.questionSet: return Icons.quiz;
      case BlockType.essay: return Icons.edit_note;
      case BlockType.unknown: return Icons.extension;

      default: return Icons.extension;
    }
  }
}

int? _extractXp(Map<String, dynamic> content) {
  final raw = content['xp'];
  if (raw is int) return raw;
  if (raw is double) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

bool _extractIsLocked(Map<String, dynamic> content) {
  final raw = content['isLocked'];
  if (raw is bool) return raw;
  if (raw is String) return raw.toLowerCase() == 'true';
  if (raw is int) return raw != 0;
  return false;
}

IconData _iconForType(BlockType type) {
  switch (type) {
    case BlockType.textPlain: return Icons.text_fields;
    case BlockType.textRich: return Icons.article;
    case BlockType.image: return Icons.image;
    case BlockType.video: return Icons.movie;
    case BlockType.audio: return Icons.audiotrack;
    case BlockType.pdf: return Icons.picture_as_pdf;
    case BlockType.carousel: return Icons.view_carousel;
    case BlockType.flipCard: return Icons.flip;
    case BlockType.quote: return Icons.format_quote;
    case BlockType.embed: return Icons.code;
    case BlockType.imageHotspot: return Icons.ads_click;
    case BlockType.stats: return Icons.bar_chart;
    case BlockType.accordion: return Icons.expand;
    case BlockType.tabs: return Icons.tab;
    case BlockType.process: return Icons.linear_scale;
    case BlockType.timeline: return Icons.timeline;
    case BlockType.comparison: return Icons.compare;
    case BlockType.scenario: return Icons.psychology;
    case BlockType.singleChoice: return Icons.radio_button_checked;
    case BlockType.multipleChoice: return Icons.check_box;
    case BlockType.trueFalse: return Icons.thumbs_up_down;
    case BlockType.fillBlanks: return Icons.border_color;
    case BlockType.sorting: return Icons.sort;
    case BlockType.flashcards: return Icons.style;
    case BlockType.matching: return Icons.link;
    case BlockType.interactiveBook: return Icons.menu_book;
    case BlockType.column: return Icons.view_column;
    case BlockType.coursePresentation: return Icons.slideshow;
    case BlockType.agamotto: return Icons.layers;
    case BlockType.dragAndDrop: return Icons.drag_indicator;
    case BlockType.markWords: return Icons.highlight;
    case BlockType.dialogCards: return Icons.chat_bubble_outline;
    case BlockType.findHotspot: return Icons.my_location;
    case BlockType.findMultipleHotspots: return Icons.location_searching;
    case BlockType.urlResource: return Icons.link;
    case BlockType.questionSet: return Icons.quiz;
    case BlockType.essay: return Icons.edit_note;
    case BlockType.unknown: return Icons.extension;
  }
}

class _PlaceholderFeatureBlock extends StatelessWidget {
  final IconData icon;
  final String title;

  const _PlaceholderFeatureBlock({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.blueGrey),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Configuración de interacción disponible para $title',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = Colors.blueGrey.shade200
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    _drawDashedLine(canvas, paint, rect.topLeft, rect.topRight, dashWidth, dashSpace);
    _drawDashedLine(canvas, paint, rect.topRight, rect.bottomRight, dashWidth, dashSpace);
    _drawDashedLine(canvas, paint, rect.bottomRight, rect.bottomLeft, dashWidth, dashSpace);
    _drawDashedLine(canvas, paint, rect.bottomLeft, rect.topLeft, dashWidth, dashSpace);
  }

  void _drawDashedLine(
    Canvas canvas,
    Paint paint,
    Offset start,
    Offset end,
    double dashWidth,
    double dashSpace,
  ) {
    final totalLength = (end - start).distance;
    final direction = (end - start) / totalLength;
    double progress = 0;
    while (progress < totalLength) {
      final current = start + direction * progress;
      final next = start + direction * (progress + dashWidth);
      canvas.drawLine(current, next, paint);
      progress += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
