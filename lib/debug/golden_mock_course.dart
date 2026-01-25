import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/course_model.dart';
import '../models/interactive_block.dart';
import '../models/module_model.dart';

CourseModel buildGoldenMockCourse() {
  final blocks = <InteractiveBlock>[
    InteractiveBlock.create(
      type: BlockType.textPlain,
      content: {
        'text': 'Texto base para validar el bloque de texto.',
        'xp': 10,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.textRich,
      content: {
        'text': 'Texto enriquecido con **estilo** y _detalle_.',
        'xp': 10,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.image,
      content: {
        'url': 'https://placehold.co/800x450',
        'caption': 'Imagen principal del curso.',
        'prompt': 'Estilo 3D isometrico',
        'xp': 5,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.video,
      content: {
        'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'title': 'Video introductorio',
        'prompt': 'Cinematico',
        'xp': 50,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.audio,
      content: {
        'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        'title': 'Podcast de contexto',
        'author': 'Equipo AppScorm',
        'xp': 40,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.pdf,
      content: {
        'url': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      },
    ),
    InteractiveBlock.create(
      type: BlockType.carousel,
      content: {
        'items': [
          {
            'imageUrl': 'https://placehold.co/900x500',
            'title': 'Slide 1',
            'description': 'Descripcion en **Markdown** del primer recurso.',
          },
          {
            'imageUrl': 'https://placehold.co/900x500?text=Slide+2',
            'title': 'Slide 2',
            'description': 'Segundo recurso con mas detalles.',
          },
        ],
        'xp': 30,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.flipCard,
      content: {
        'front': 'Concepto clave',
        'back': 'Definicion resumida del concepto.',
      },
    ),
    InteractiveBlock.create(
      type: BlockType.quote,
      content: {
        'text': 'Aprender es descubrir lo que ya sabes.',
        'author': 'Richard Bach',
      },
    ),
    InteractiveBlock.create(
      type: BlockType.embed,
      content: {
        'code': '<iframe src="https://example.com" width="600" height="400"></iframe>',
      },
    ),
    InteractiveBlock.create(
      type: BlockType.imageHotspot,
      content: {
        'url': 'https://placehold.co/1200x800',
        'prompt': 'Isometrico',
        'hotspots': [
          {
            'dx': 25,
            'dy': 30,
            'title': 'Zona 1',
            'description': 'Detalle del punto 1.',
            'isVisited': false,
          },
          {
            'dx': 65,
            'dy': 55,
            'title': 'Zona 2',
            'description': 'Detalle del punto 2.',
            'isVisited': false,
          },
        ],
        'xp': 45,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.stats,
      content: {
        'show_charts': true,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.accordion,
      content: {
        'style': 'standard',
        'exclusive': true,
        'items': [
          {
            'title': 'Seccion 1',
            'content': 'Contenido del acordeon en **Markdown**.',
            'icon': Icons.info_outline.codePoint,
          },
          {
            'title': 'Seccion 2',
            'content': 'Segundo bloque de contenido.',
            'icon': Icons.lightbulb_outline.codePoint,
          },
        ],
      },
    ),
    InteractiveBlock.create(
      type: BlockType.tabs,
      content: {
        'style': 'classic',
        'tabs': [
          {
            'title': 'Resumen',
            'content': 'Contenido de la pestana de resumen.',
            'icon': Icons.info_outline.codePoint,
          },
          {
            'title': 'Detalles',
            'content': 'Contenido de la pestana de detalles.',
            'icon': Icons.list_alt_outlined.codePoint,
          },
        ],
        'xp': 25,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.process,
      content: {
        'steps': [
          {
            'title': 'Paso 1',
            'desc': 'Descripcion del paso 1.',
            'icon': Icons.check_circle_outline.codePoint,
          },
          {
            'title': 'Paso 2',
            'desc': 'Descripcion del paso 2.',
            'icon': Icons.flag_outlined.codePoint,
          },
        ],
      },
    ),
    InteractiveBlock.create(
      type: BlockType.timeline,
      content: {
        'style': 'minimal',
        'events': [
          {
            'label': 'Fase 1',
            'title': 'Descubrimiento',
            'description': 'Descripcion del hito inicial.',
            'icon': Icons.flag_outlined.codePoint,
          },
          {
            'label': 'Fase 2',
            'title': 'Implementacion',
            'description': 'Descripcion del segundo hito.',
            'icon': Icons.timeline.codePoint,
          },
        ],
        'xp': 35,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.comparison,
      content: {
        'comparisonStyle': 'versus',
        'itemA': {
          'title': 'Metodo A',
          'subtitle': 'Rapido y directo',
          'image': 'https://placehold.co/500x300?text=A',
          'features': ['Mas simple', 'Menos costo', 'Rapido de ejecutar'],
        },
        'itemB': {
          'title': 'Metodo B',
          'subtitle': 'Mas robusto',
          'image': 'https://placehold.co/500x300?text=B',
          'features': ['Mayor control', 'Escalable', 'Mejor soporte'],
        },
        'xp': 40,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.scenario,
      content: {
        'introText': 'Te encuentras con un riesgo en planta. ?Que haces?',
        'imagePath': 'https://placehold.co/400x400?text=Avatar',
        'options': [
          {
            'text': 'Aplicar protocolo de seguridad',
            'feedback': 'Correcto, reduces el riesgo.',
            'isCorrect': true,
            'bonusXP': 20,
          },
          {
            'text': 'Ignorar el aviso',
            'feedback': 'Incrementa el riesgo operativo.',
            'isCorrect': false,
            'bonusXP': 0,
          },
        ],
        'xp': 30,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.singleChoice,
      content: {
        'question': 'Cual es el objetivo principal?',
        'options': ['Reducir costos', 'Mejorar calidad', 'Aumentar riesgo'],
        'correctIndex': 1,
        'feedbackPositive': 'Bien hecho.',
        'feedbackNegative': 'Revisa la teoria.',
      },
    ),
    InteractiveBlock.create(
      type: BlockType.multipleChoice,
      content: {
        'question': 'Selecciona los beneficios reales.',
        'options': ['Eficiencia', 'Menos errores', 'Riesgos altos'],
        'correctIndices': [0, 1],
        'feedbackPositive': 'Correcto.',
        'feedbackNegative': 'Intenta nuevamente.',
      },
    ),
    InteractiveBlock.create(
      type: BlockType.trueFalse,
      content: {
        'question': 'La metodologia reduce incidentes.',
        'isTrue': true,
        'feedbackPositive': 'Exacto.',
        'feedbackNegative': 'No es correcto.',
      },
    ),
    InteractiveBlock.create(
      type: BlockType.fillBlanks,
      content: {
        'text': 'La capital de Francia es *Paris*.',
      },
    ),
    InteractiveBlock.create(
      type: BlockType.sorting,
      content: {
        'instruction': 'Ordena las fases del proyecto.',
        'items': [
          {'text': 'Analisis', 'indexCorrecto': 0},
          {'text': 'Diseno', 'indexCorrecto': 1},
          {'text': 'Implementacion', 'indexCorrecto': 2},
          {'text': 'Entrega', 'indexCorrecto': 3},
        ],
        'xp': 45,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.flashcards,
      content: {
        'cards': [
          {'frontText': 'KPI', 'backText': 'Indicador clave de rendimiento', 'frontImage': ''},
          {'frontText': 'ROI', 'backText': 'Retorno de inversion', 'frontImage': ''},
        ],
        'xp': 30,
      },
    ),
    InteractiveBlock.create(
      type: BlockType.matching,
      content: {
        'leftItems': [
          {'id': 1, 'text': 'Riesgo'},
          {'id': 2, 'text': 'Mitigacion'},
          {'id': 3, 'text': 'Impacto'},
        ],
        'rightItems': [
          {'id': 1, 'text': 'Probabilidad de incidente'},
          {'id': 2, 'text': 'Accion preventiva'},
          {'id': 3, 'text': 'Consecuencia en el negocio'},
        ],
        'xp': 35,
      },
    ),
  ];

  final module = ModuleModel(
    id: const Uuid().v4(),
    title: 'Modulo Golden Mock',
    order: 0,
    blocks: blocks,
  );

  return CourseModel(
    id: const Uuid().v4(),
    title: 'Golden Mock Course',
    description: 'Curso de prueba para el stress test de bloques.',
    createdAt: DateTime.now(),
    modules: [module],
  );
}
