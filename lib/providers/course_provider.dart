import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Asegúrate de tener uuid importado
import '../debug/golden_mock_course.dart';
import '../models/course_model.dart';
import '../models/module_model.dart';
import '../models/interactive_block.dart';
import '../services/storage_service.dart';

class CourseNotifier extends StateNotifier<CourseModel?> {
  CourseNotifier() : super(null);

  void setCourse(CourseModel course) {
    state = course;
  }

  void updateFullCourse(CourseModel course) {
    state = CourseModel.fromMap(course.toMap());
  }

  void updateCourse(CourseModel course) {
    state = course;
  }

  Future<void> saveCourse() async {
    final current = state;
    if (current == null) return;
    await StorageService().saveCourse(current.toMap());
  }

  void clearModules() {
    if (state == null) return;
    final map = state!.toMap();
    map['modules'] = [];
    state = CourseModel.fromMap(map);
  }

  // Debug: Inyecta un curso con todos los bloques para stress test.
  void loadGoldenMockCourse() {
    state = buildGoldenMockCourse();
  }

  void updateTitle(String newTitle) {
    if (state == null) return;
    state = CourseModel(
        id: state!.id, title: newTitle, description: state!.description, modules: state!.modules,
        userId: state!.userId, createdAt: state!.createdAt);
  }

  // --- PODERES DE CREACIÓN (NUEVO) ---

  // 1. AÑADIR MÓDULO NUEVO
  void addModule() {
    if (state == null) return;
    final newModule = ModuleModel(
      id: const Uuid().v4(),
      title: "Nuevo Módulo ${state!.modules.length + 1}",
      order: state!.modules.length,
      blocks: [], // Empieza vacío
    );
    
    final updatedModules = [...state!.modules, newModule];
    
    state = CourseModel(
        id: state!.id, title: state!.title, description: state!.description, modules: updatedModules,
        userId: state!.userId, createdAt: state!.createdAt);
  }

  // 2. AÑADIR BLOQUE (DE LOS 20 TIPOS)
  void addBlock(int moduleIndex, BlockType type) {
    if (state == null) return;
    
    // Contenido por defecto
    Map<String, dynamic> defaultContent = {};
    if (type.name.contains('text') || type == BlockType.accordion || type == BlockType.column) {
      defaultContent = {'text': 'Escribe aquí tu contenido...'};
    } else if (type.name.contains('image') || type == BlockType.agamotto || type == BlockType.carousel) {
      defaultContent = {'url': 'https://placehold.co/600x400', 'caption': 'Descripción de la imagen'};
    } else {
      defaultContent = {'question': 'Nueva Pregunta o Actividad', 'options': ['Opción 1', 'Opción 2'], 'correctIndex': 0};
    }

    final newBlock = InteractiveBlock.create(type: type, content: defaultContent);
    addDirectBlock(moduleIndex, newBlock);
  }

  // 2b. AÑADIR BLOQUE DIRECTO (Para cuando ya tenemos la instancia)
  void addDirectBlock(int moduleIndex, InteractiveBlock block) {
    if (state == null) return;
    final updatedModules = List<ModuleModel>.from(state!.modules);
    final targetModule = updatedModules[moduleIndex];
    final updatedBlocks = [...targetModule.blocks, block];

    updatedModules[moduleIndex] = ModuleModel(
      id: targetModule.id, title: targetModule.title, order: targetModule.order, blocks: updatedBlocks
    );

    state = CourseModel(
        id: state!.id, title: state!.title, description: state!.description, modules: updatedModules,
        userId: state!.userId, createdAt: state!.createdAt);
  }

  // --- PODERES DE EDICIÓN Y BORRADO (YA EXISTENTES) ---

  void updateBlock(int moduleIndex, int blockIndex, InteractiveBlock newBlock) {
    if (state == null) return;
    final updatedModules = List<ModuleModel>.from(state!.modules);
    final targetModule = updatedModules[moduleIndex];
    final updatedBlocks = List<InteractiveBlock>.from(targetModule.blocks);
    updatedBlocks[blockIndex] = newBlock;
    updatedModules[moduleIndex] = ModuleModel(
      id: targetModule.id, title: targetModule.title, order: targetModule.order, blocks: updatedBlocks
    );
    state = CourseModel(
        id: state!.id, title: state!.title, description: state!.description, modules: updatedModules,
        userId: state!.userId, createdAt: state!.createdAt);
  }

  void removeBlock(int moduleIndex, int blockIndex) {
    if (state == null) return;
    final updatedModules = List<ModuleModel>.from(state!.modules);
    final targetModule = updatedModules[moduleIndex];
    final updatedBlocks = List<InteractiveBlock>.from(targetModule.blocks);
    updatedBlocks.removeAt(blockIndex);
    updatedModules[moduleIndex] = ModuleModel(
      id: targetModule.id, title: targetModule.title, order: targetModule.order, blocks: updatedBlocks
    );
    state = CourseModel(
        id: state!.id, title: state!.title, description: state!.description, modules: updatedModules,
        userId: state!.userId, createdAt: state!.createdAt);
  }

  void updateBlockProgress(
    String blockId, {
    bool? isCompleted,
    bool? xpEarned,
    int? earnedXp,
  }) {
    if (state == null) return;
    bool updated = false;

    void updateList(List<InteractiveBlock> blocks) {
      for (final block in blocks) {
        if (block.id != blockId) continue;
        if (isCompleted != null) block.content['isCompleted'] = isCompleted;
        if (xpEarned != null) block.content['xpEarned'] = xpEarned;
        if (earnedXp != null) block.content['earnedXp'] = earnedXp;
        updated = true;
        break;
      }
    }

    for (final module in state!.modules) {
      updateList(module.blocks);
    }
    updateList(state!.general.blocks);
    updateList(state!.intro.introBlocks);
    updateList(state!.intro.objectiveBlocks);
    updateList(state!.conceptMap.blocks);
    updateList(state!.resources.blocks);
    updateList(state!.glossary.blocks);
    updateList(state!.faq.blocks);
    updateList(state!.evaluation.blocks);
    updateList(state!.stats.blocks);
    updateList(state!.contentBank.blocks);

    if (updated) {
      state = CourseModel.fromMap(state!.toMap());
    }
  }

  void updateModuleTitle(String moduleId, String newTitle) {
    if (state == null) return;
    final map = state!.toMap();
    final modules = List<Map<String, dynamic>>.from(map['modules'] as List? ?? []);
    var updated = false;
    for (final module in modules) {
      if (module['id'] == moduleId) {
        module['title'] = newTitle;
        updated = true;
        break;
      }
    }
    if (!updated) return;
    map['modules'] = modules;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      state = CourseModel.fromMap(map);
    });
  }
}

final courseProvider = StateNotifierProvider<CourseNotifier, CourseModel?>((ref) {
  return CourseNotifier();
});
