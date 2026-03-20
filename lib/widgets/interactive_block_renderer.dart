import 'package:flutter/material.dart';
import '../models/interactive_block.dart';

// IMPORTS EXACTOS SEGÚN TU ESTRUCTURA DE CARPETAS
import 'interactives/structure/accordion_widget.dart';
import 'interactives/structure/column_widget.dart';
import 'interactives/structure/interactive_book_widget.dart';
import 'interactives/structure/carousel_widget.dart';

import 'interactives/visual/text_plain_widget.dart';
import 'interactives/visual/image_hotspot_widget.dart';
import 'interactives/visual/agamotto_widget.dart';
import 'interactives/visual/video_widget.dart';

import 'interactives/evaluation/true_false_widget.dart';
import 'interactives/evaluation/multiple_choice_widget.dart';
import 'interactives/evaluation/essay_widget.dart';

import 'interactives/practice/fill_blanks_widget.dart';
import 'interactives/practice/drag_drop_widget.dart';

class InteractiveBlockRenderer extends StatelessWidget {
  final InteractiveBlock block;

  const InteractiveBlockRenderer({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      // ESTRUCTURA
      case BlockType.accordion: return AccordionWidget(block: block);
      case BlockType.column: return ColumnWidget(block: block);
      case BlockType.interactiveBook: return InteractiveBookWidget(block: block);
      case BlockType.carousel: 
      case BlockType.coursePresentation: return CarouselWidget(block: block);

      // VISUAL
      case BlockType.textPlain: return TextPlainWidget(block: block);
      case BlockType.imageHotspot: 
      case BlockType.findHotspot: 
      case BlockType.findMultipleHotspots: return ImageHotspotWidget(block: block);
      case BlockType.agamotto: return AgamottoWidget(block: block);
      case BlockType.video: return VideoWidget(block: block);

      // EVALUACIÓN
      case BlockType.trueFalse: return TrueFalseWidget(block: block);
      case BlockType.multipleChoice: 
      case BlockType.singleChoice: 
      case BlockType.questionSet: return MultipleChoiceWidget(block: block);
      case BlockType.essay: return EssayWidget(block: block);

      // PRÁCTICA
      case BlockType.fillBlanks: 
      case BlockType.markWords: return FillBlanksWidget(block: block);
      case BlockType.dragAndDrop: return DragDropWidget(block: block);

      default:
        return Container(
          padding: const EdgeInsets.all(20),
          color: Colors.grey[200],
          child: Text("Bloque: ${block.type.name}"),
        );
    }
  }
}