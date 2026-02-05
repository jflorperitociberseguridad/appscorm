part of '../dashboard_editor.dart';

const double _toolbarReservedHeight = 340;
const double _toolbarTopSpacing = 18;

extension _DashboardEditorUi on _DashboardEditorState {

  Widget _buildTopBar() {
    return RepaintBoundary(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 60,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 360;
                final titleField = TextFormField(
                  controller: _titleController,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis),
                  decoration: const InputDecoration(border: InputBorder.none, hintText: "Título del curso..."),
                  onChanged: (v) => _scheduleDebouncedCourseUpdate('course_title', () {
                    widget.course.title = v;
                  }),
                );
            final actionsRow = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(widget.isRightPanelVisible ? Icons.grid_view_rounded : Icons.grid_view_outlined, color: Colors.grey),
                  onPressed: widget.onToggleRightPanel,
                  tooltip: "Mostrar/Ocultar Panel Alumno",
                ),
                IconButton(
                  icon: const Icon(Icons.download_for_offline_outlined, color: Colors.teal),
                  tooltip: "Descargar Copia JSON (Backup)",
                  onPressed: _exportarJSON,
                ),
                const VerticalDivider(width: 30, indent: 15, endIndent: 15),
                TextButton.icon(
                  onPressed: _guardarProgreso,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text("GUARDAR"),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                  child: ElevatedButton.icon(
                    onPressed: _exportScorm,
                    icon: const Icon(Icons.archive_outlined, size: 16),
                    label: const Text("EXPORTAR SCORM"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade900, foregroundColor: Colors.white),
                  ),
                ),
              ],
            );

                if (isNarrow) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.dashboard_customize, color: Colors.indigo),
                          onPressed: () => context.go('/'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.bug_report, color: Colors.deepOrange),
                          tooltip: 'Stress Test Golden Course',
                          visualDensity: VisualDensity.compact,
                          onPressed: _confirmGoldenMockLoad,
                        ),
                        SizedBox(width: 200, child: titleField),
                        actionsRow,
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.dashboard_customize, color: Colors.indigo),
                      onPressed: () => context.go('/'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.bug_report, color: Colors.deepOrange),
                      tooltip: 'Stress Test Golden Course',
                      visualDensity: VisualDensity.compact,
                      onPressed: _confirmGoldenMockLoad,
                    ),
                    Expanded(child: titleField),
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: actionsRow,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

Widget _buildMainContentArea(String selectedSection) {
  return Expanded(
    child: RepaintBoundary(
      child: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 30),
            decoration: const BoxDecoration(
              color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _getSectionTitle(selectedSection).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo, letterSpacing: 1.1),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (selectedSection != 'index' && selectedSection != 'stats')
                        ElevatedButton.icon(
                          onPressed: _isGeneratingSection ? null : () => generateCurrentSectionContent(selectedSection),
                          icon: _isGeneratingSection
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome, size: 16),
                          label: const Text("GENERAR IA"),
                        ),
                      const SizedBox(width: 12),
                      if (selectedSection == 'modules_root')
                        ElevatedButton.icon(
                          onPressed: widget.onAddModule,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("NUEVO TEMA"),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade100, Colors.grey.shade200],
                  begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: GridPaper(
              color: Colors.transparent,
              divisions: 4,
              interval: 150,
              subdivisions: 5,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 40,
                              spreadRadius: 2,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: _toolbarReservedHeight + _toolbarTopSpacing),
                          child: _buildSectionEditor(selectedSection),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: _toolbarTopSpacing + 8,
                    left: 40,
                    right: 40,
                    child: _BlockToolbar(
                      sectionId: selectedSection,
                      onBlockSelected: (type, initialContent) => _addBlockToSection(
                        selectedSection,
                        type,
                        initialContent: initialContent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildInitialPanelConfigCard() {
  return _buildSimpleCard(
    title: "Panel Inicial · Configuración IA",
    child: Column(
      children: [
        TextFormField(
          initialValue: _panelAudience,
          decoration: const InputDecoration(
            labelText: "Público",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _scheduleDebouncedCourseUpdate('panel_audience', () {
            _panelAudience = value;
          }),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _panelTone,
          decoration: const InputDecoration(
            labelText: "Tono",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _scheduleDebouncedCourseUpdate('panel_tone', () {
            _panelTone = value;
          }),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: _panelMethodology,
          decoration: const InputDecoration(
            labelText: "Metodología",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _scheduleDebouncedCourseUpdate('panel_methodology', () {
            _panelMethodology = value;
          }),
        ),
      ],
    ),
  );
}

Widget _buildGeneratedContentCard(String sectionId, String title) {
  final content = _generatedSectionContent[sectionId] ?? '';
  if (content.isEmpty) {
    return _buildSimpleCard(
      title: title,
      child: const Text(
        "Aún no hay contenido generado para esta sección.",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
  final format = _generatedSectionFormat[sectionId] ?? 'text';
  final isJson = format == 'json';
  return _buildSimpleCard(
    title: title,
    child: SelectableText(
      content,
      style: TextStyle(
        fontSize: 12,
        height: 1.4,
        color: Colors.grey.shade800,
        fontFamily: isJson ? 'monospace' : null,
      ),
    ),
  );
}

Widget _buildSimpleCard({required String title, required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 30),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.indigo.withValues(alpha: 0.08)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.indigo)),
        const SizedBox(height: 15),
        child,
      ],
    ),
  );
}

Widget _buildGeneralHeader() {
  return Container(
    margin: const EdgeInsets.only(bottom: 30),
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("CONFIGURACIÓN DE RECURSOS OPERATIVOS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
        const SizedBox(height: 25),
        _fileRow("Video Tutorial del Curso", widget.course.general.videoTutorialUrl, Icons.play_circle_fill, () => _pickFileForGeneral('video')),
        const Divider(height: 30),
        _fileRow("Manual de la Plataforma", widget.course.general.platformManualUrl, Icons.picture_as_pdf, () => _pickFileForGeneral('manual')),
        const Divider(height: 30),
        _fileRow("Guía Didáctica Alumno", widget.course.general.studentGuideUrl, Icons.description, () => _pickFileForGeneral('guide')),
      ],
    ),
  );
}

Widget _fileRow(String label, String value, IconData icon, VoidCallback onPick) {
  bool hasFile = value.isNotEmpty;
  return LayoutBuilder(
    builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 520;
      final infoColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(
            hasFile ? value : "Pendiente de cargar...",
            style: TextStyle(color: hasFile ? Colors.black54 : Colors.red.shade300, fontSize: 11),
          ),
        ],
      );
      final actionButton = ElevatedButton(
        onPressed: onPick,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade100, elevation: 0, foregroundColor: Colors.indigo),
        child: Text(hasFile ? "CAMBIAR" : "CARGAR"),
      );
      if (isNarrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: hasFile ? Colors.green : Colors.grey, size: 24),
                const SizedBox(width: 16),
                Expanded(child: infoColumn),
              ],
            ),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: actionButton),
          ],
        );
      }
      return Row(
        children: [
          Icon(icon, color: hasFile ? Colors.green : Colors.grey, size: 24),
          const SizedBox(width: 20),
          Expanded(child: infoColumn),
          actionButton,
        ],
      );
    },
  );
}

Widget _buildStatsHeader() {
  return _buildSimpleCard(
    title: "Indicadores del curso",
    child: Column(
      children: [
        _statRow("Nota promedio (%)", widget.course.stats.averageScore.toStringAsFixed(1)),
        const SizedBox(height: 12),
        _statRow("Tiempo promedio (min)", widget.course.stats.averageTimeMinutes.toString()),
      ],
    ),
  );
}

Widget _statRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569))),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
    ],
  );
}

Widget _buildContentBankHeader() {
  final files = widget.course.contentBank.files;
  return _buildSimpleCard(
    title: "Banco de Contenidos Multimodal",
    child: Column(
      children: [
        if (files.isEmpty)
          const Text(
            "No hay archivos registrados en este curso.",
            style: TextStyle(color: Colors.grey),
          ),
        for (final file in files)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _iconForContentBankType(file['type'] ?? ''),
              color: Colors.indigo,
            ),
            title: Text(file['name'] ?? 'Archivo'),
            subtitle: Text((file['type'] ?? 'desconocido').toUpperCase()),
          ),
      ],
    ),
  );
}

IconData _iconForContentBankType(String type) {
  switch (type) {
    case 'audio':
      return Icons.audiotrack;
    case 'video':
      return Icons.videocam;
    case 'image':
      return Icons.image;
    case 'document':
      return Icons.description;
    default:
      return Icons.insert_drive_file;
  }
}

String _getSectionTitle(String selectedSection) {
  switch (selectedSection) {
    case 'general':
      return "Configuración · General";
    case 'intro':
      return "Configuración · Introducción";
    case 'objectives':
      return "Configuración · Objetivos";
    case 'map':
      return "Configuración · Mapa Conceptual";
    case 'index':
      return "Temario · Índice del curso";
    case 'modules_root':
      return "Temario · Gestión de Temas";
    case 'resources':
      return "Recursos y Cierre · Recursos";
    case 'glossary':
      return "Recursos y Cierre · Glosario";
    case 'faq':
      return "Recursos y Cierre · Preguntas Frecuentes";
    case 'eval':
      return "Recursos y Cierre · Evaluación Final";
    case 'stats':
      return "Recursos y Cierre · Estadísticas";
    case 'bank':
      return "Banco de Contenidos · Multimodal";
    default:
      return "Editor de Contenidos";
  }
}

}
