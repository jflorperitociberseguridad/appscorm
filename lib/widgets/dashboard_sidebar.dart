import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../models/module_model.dart';

class DashboardSelectionController extends ChangeNotifier {
  static const List<String> dashboardSectionIds = [
    'general',
    'intro',
    'objectives',
    'map',
    'index',
    'modules_root',
    'resources',
    'glossary',
    'faq',
    'eval',
    'stats',
    'bank',
  ];

  final Map<String, bool> _sectionSelection = {};
  String _selectedSection = 'intro';
  String? _selectedModuleId;

  String get selectedSection => _selectedSection;

  bool isSectionSelected(String id) => _sectionSelection[id] ?? true;

  bool isModuleSelected(ModuleModel module) => _sectionSelection[_moduleKey(module)] ?? true;

  String sectionIdForModule(ModuleModel module) => 'module_${module.id}';

  void initialize(CourseModel course) {
    for (final id in dashboardSectionIds) {
      _sectionSelection.putIfAbsent(id, () => true);
    }
    for (final module in course.modules) {
      _sectionSelection.putIfAbsent(_moduleKey(module), () => true);
    }
    if (_selectedModuleId == null && course.modules.isNotEmpty) {
      _selectedModuleId = course.modules.first.id;
    }
  }

  void selectSection(String id) {
    _selectedSection = id;
    if (id.startsWith('module_')) {
      _selectedModuleId = id.substring('module_'.length);
    }
    notifyListeners();
  }

  void selectModule(ModuleModel module) {
    _selectedModuleId = module.id;
    _selectedSection = sectionIdForModule(module);
    notifyListeners();
  }

  int getSelectedModuleIndex(CourseModel course) {
    if (_selectedModuleId == null) return 0;
    final index = course.modules.indexWhere((m) => m.id == _selectedModuleId);
    return index == -1 ? 0 : index;
  }

  ModuleModel? getSelectedModule(CourseModel course) {
    if (_selectedModuleId == null) return null;
    final index = course.modules.indexWhere((m) => m.id == _selectedModuleId);
    if (index == -1) return null;
    return course.modules[index];
  }

  void setSectionSelected(String id, bool selected) {
    _sectionSelection[id] = selected;
    notifyListeners();
  }

  void setModuleSelected(ModuleModel module, bool selected) {
    _sectionSelection[_moduleKey(module)] = selected;
    notifyListeners();
  }

  void onModuleAdded(ModuleModel module, {bool select = true}) {
    _sectionSelection[_moduleKey(module)] = true;
    if (select) {
      selectModule(module);
    } else {
      notifyListeners();
    }
  }

  void onModuleRemoved(ModuleModel module, CourseModel course) {
    _sectionSelection.remove(_moduleKey(module));
    if (_selectedModuleId == module.id) {
      _selectedSection = 'modules_root';
      _selectedModuleId = course.modules.isNotEmpty ? course.modules.first.id : null;
    }
    notifyListeners();
  }

  String _moduleKey(ModuleModel module) => 'module_${module.id}';
}

class DashboardSidebar extends StatefulWidget {
  final CourseModel course;
  final DashboardSelectionController selectionController;
  final VoidCallback onCourseUpdated;
  final VoidCallback onAddModule;

  const DashboardSidebar({
    super.key,
    required this.course,
    required this.selectionController,
    required this.onCourseUpdated,
    required this.onAddModule,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  void _scheduleSetState(VoidCallback fn) {
    Future.microtask(() {
      if (!mounted) return;
      setState(fn);
    });
  }

  void _deleteModule(int index) {
    final module = widget.course.modules[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar módulo?"),
        content: const Text("Esta acción no se puede deshacer y borrará todo el contenido del tema."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () {
              _scheduleSetState(() {
                widget.course.modules.removeAt(index);
                widget.selectionController.onModuleRemoved(module, widget.course);
              });
              widget.onCourseUpdated();
              Navigator.pop(context);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editModuleTitle(ModuleModel module) {
    final controller = TextEditingController(text: module.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar título del tema"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Título del tema",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                _scheduleSetState(() => module.title = value);
                widget.onCourseUpdated();
              }
              Navigator.pop(context);
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.selectionController,
      builder: (context, _) {
        return Container(
          width: 280,
          color: const Color(0xFF1E293B),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildBrandLogo(),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    _navHeader("CONFIGURACIÓN"),
                    _navItem("General", Icons.settings_applications, 'general'),
                    _navItem("Introducción", Icons.auto_awesome_mosaic, 'intro'),
                    _navItem("Objetivos", Icons.flag_circle, 'objectives'),
                    _navItem("Mapa Conceptual", Icons.account_tree_outlined, 'map'),

                    _navHeader("TEMARIO"),
                    _navItem("Índice del curso", Icons.list_alt_outlined, 'index'),
                    _navItem("Gestión de Temas", Icons.library_books, 'modules_root'),
                    _navActionItem("Añadir tema", Icons.add_circle_outline, widget.onAddModule),
                    ...List.generate(
                      widget.course.modules.length,
                      (i) {
                        final module = widget.course.modules[i];
                        return _navModuleItem(module, i);
                      },
                    ),

                    _navHeader("RECURSOS Y CIERRE"),
                    _navItem("Recursos", Icons.folder_open, 'resources'),
                    _navItem("Glosario", Icons.spellcheck, 'glossary'),
                    _navItem("Preguntas Frecuentes", Icons.help_center, 'faq'),
                    _navItem("Evaluación Final", Icons.fact_check_outlined, 'eval'),
                    _navItem("Estadísticas", Icons.bar_chart, 'stats'),

                    _navHeader("BANCO DE CONTENIDOS MULTIMODAL"),
                    _navItem("Banco de Contenidos", Icons.archive_outlined, 'bank', showCheckbox: false),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrandLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: const Row(
        children: [
          CircleAvatar(backgroundColor: Colors.indigoAccent, radius: 15, child: Icon(Icons.bolt, color: Colors.white, size: 18)),
          SizedBox(width: 12),
          Text("SCORM MASTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNavCheckbox({required bool value, required ValueChanged<bool?> onChanged}) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: Colors.white38,
        checkboxTheme: const CheckboxThemeData(
          side: BorderSide(color: Colors.white38),
        ),
      ),
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.indigoAccent,
        checkColor: Colors.white,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _navHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 25, 15, 10),
      child: Text(title, style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }

  Widget _navItem(String title, IconData icon, String id, {bool showCheckbox = true}) {
    bool isSelected = widget.selectionController.selectedSection == id;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon, color: isSelected ? Colors.indigoAccent : Colors.white60, size: 18),
      title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: showCheckbox
          ? _buildNavCheckbox(
              value: widget.selectionController.isSectionSelected(id),
              onChanged: (value) => widget.selectionController.setSectionSelected(id, value ?? true),
            )
          : null,
      onTap: () => widget.selectionController.selectSection(id),
      tileColor: isSelected ? Colors.indigoAccent.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      dense: true,
    );
  }

  Widget _navActionItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon, color: Colors.white30, size: 18),
      title: Text(title, style: const TextStyle(color: Colors.white30, fontSize: 12)),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _navModuleItem(ModuleModel module, int index) {
    final id = widget.selectionController.sectionIdForModule(module);
    bool isSelected = widget.selectionController.selectedSection == id;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 40, right: 8),
      title: Text(module.title, style: TextStyle(color: isSelected ? Colors.indigoAccent : Colors.white30, fontSize: 12)),
      onTap: () => widget.selectionController.selectModule(module),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNavCheckbox(
            value: widget.selectionController.isModuleSelected(module),
            onChanged: (value) => widget.selectionController.setModuleSelected(module, value ?? true),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            color: Colors.white38,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _editModuleTitle(module),
            tooltip: "Editar",
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: Colors.red.shade300,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _deleteModule(index),
            tooltip: "Eliminar",
          ),
        ],
      ),
      dense: true,
    );
  }
}
