import 'package:flutter/material.dart';
import '../creation_shared_widgets.dart';

class ContentBankSectionView extends StatelessWidget {
  final InputDecoration Function(String hint) inputStyle;
  final TextEditingController contentBankNotesController;
  final List<Map<String, String>> contentBankFiles;
  final VoidCallback onPickAudio;
  final VoidCallback onPickVideo;
  final VoidCallback onPickImage;
  final VoidCallback onPickDocument;
  final IconData Function(String type) iconForType;
  final ValueChanged<int> onRemoveFile;

  const ContentBankSectionView({
    super.key,
    required this.inputStyle,
    required this.contentBankNotesController,
    required this.contentBankFiles,
    required this.onPickAudio,
    required this.onPickVideo,
    required this.onPickImage,
    required this.onPickDocument,
    required this.iconForType,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ExpansionTile(
            title: const Text("Banco de Contenidos Multimodal"),
            initiallyExpanded: true,
            children: [
              const SectionLabel(text: "Subir materiales"),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: onPickAudio,
                    icon: const Icon(Icons.audiotrack),
                    label: const Text("Audio"),
                  ),
                  ElevatedButton.icon(
                    onPressed: onPickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text("Video"),
                  ),
                  ElevatedButton.icon(
                    onPressed: onPickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Imagen"),
                  ),
                  ElevatedButton.icon(
                    onPressed: onPickDocument,
                    icon: const Icon(Icons.description),
                    label: const Text("PDF/DOCX"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SectionLabel(text: "Notas del Banco (opcional)"),
              TextField(
                controller: contentBankNotesController,
                maxLines: 3,
                decoration: inputStyle("Contexto o resumen de los materiales..."),
              ),
              const SizedBox(height: 20),
              const SectionLabel(text: "Materiales cargados"),
              if (contentBankFiles.isEmpty)
                const Text("Aún no hay archivos cargados.", style: TextStyle(color: Colors.grey)),
              for (int i = 0; i < contentBankFiles.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    iconForType(contentBankFiles[i]['type'] ?? ''),
                    color: Colors.indigo,
                  ),
                  title: Text(contentBankFiles[i]['name'] ?? 'Archivo'),
                  subtitle: Text((contentBankFiles[i]['type'] ?? 'desconocido').toUpperCase()),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => onRemoveFile(i),
                    tooltip: "Quitar",
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
