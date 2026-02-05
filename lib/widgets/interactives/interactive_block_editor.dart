import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/interactive_block.dart';
import 'interactive_block_modes.dart';
import '../interactive_block_renderer.dart';

class ContentMultimediaBlockEditor extends StatefulWidget {
  final InteractiveBlock block;
  final InteractiveBlockMode mode;
  final ValueChanged<BlockContentChanged>? onContentChanged;

  const ContentMultimediaBlockEditor({
    super.key,
    required this.block,
    this.onContentChanged,
    this.mode = InteractiveBlockMode.interactive,
  });

  @override
  State<ContentMultimediaBlockEditor> createState() => _ContentMultimediaBlockEditorState();
}

class _ContentMultimediaBlockEditorState extends State<ContentMultimediaBlockEditor> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _setupControllers();
  }

  @override
  void didUpdateWidget(covariant ContentMultimediaBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content) {
      _setupControllers();
    }
  }

  void _setupControllers() {
    final specs = _fieldSpecsForType(widget.block.type);
    _controllers = {
      for (final spec in specs)
        spec.contentKey: TextEditingController(text: _displayValue(spec)),
    };
  }

  String _displayValue(_FieldSpec spec) {
    if (spec.isJson) {
      final value = widget.block.content[spec.contentKey];
      if (value == null) return '';
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return widget.block.content[spec.contentKey]?.toString() ?? '';
  }

  void _updateField(_FieldSpec spec, String rawValue) {
    if (widget.onContentChanged == null) return;
    final content = Map<String, dynamic>.from(widget.block.content);
    if (spec.isJson) {
      try {
        content[spec.contentKey] = jsonDecode(rawValue);
      } catch (_) {
        return;
      }
    } else {
      content[spec.contentKey] = rawValue;
    }
    widget.onContentChanged!(BlockContentChanged(content));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == InteractiveBlockMode.interactive) {
      return InteractiveBlockRenderer(block: widget.block);
    }
    final specs = _fieldSpecsForType(widget.block.type);
    if (specs.isEmpty) {
      return const Center(child: Text('No hay campos configurables para este bloque.'));
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: specs.map((spec) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
            controller: _controllers[spec.contentKey],
            decoration: InputDecoration(
              labelText: spec.label,
              hintText: spec.hint,
            ),
            keyboardType: spec.keyboardType,
            maxLines: spec.maxLines,
            onChanged: (value) => _updateField(spec, value),
          ),
        );
      }).toList(),
      ),
    );
  }
}

class _FieldSpec {
  final String contentKey;
  final String label;
  final String hint;
  final bool isJson;
  final int maxLines;
  final TextInputType keyboardType;

  const _FieldSpec({
    required this.contentKey,
    required this.label,
    required this.hint,
    this.isJson = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });
}

List<_FieldSpec> _fieldSpecsForType(BlockType type) {
  switch (type) {
    case BlockType.textPlain:
    case BlockType.textRich:
      return const [
        _FieldSpec(contentKey: 'text', label: 'Texto', hint: 'Describe el contenido principal', maxLines: 4),
        _FieldSpec(contentKey: 'xp', label: 'XP', hint: 'Valor numérico de recompensa', keyboardType: TextInputType.number),
      ];
    case BlockType.image:
      return const [
        _FieldSpec(contentKey: 'url', label: 'URL de la imagen', hint: 'https://...'),
        _FieldSpec(contentKey: 'caption', label: 'Pie de foto', hint: 'Explica la imagen'),
        _FieldSpec(contentKey: 'prompt', label: 'Prompt IA', hint: 'Describe el estilo visual'),
      ];
    case BlockType.video:
      return const [
        _FieldSpec(contentKey: 'url', label: 'URL del video', hint: 'Link o id'),
        _FieldSpec(contentKey: 'title', label: 'Título', hint: 'Nombre del clip'),
        _FieldSpec(contentKey: 'prompt', label: 'Prompt IA', hint: 'Describe el estilo visual'),
        _FieldSpec(contentKey: 'xp', label: 'XP', hint: 'Recompensa', keyboardType: TextInputType.number),
      ];
    case BlockType.audio:
      return const [
        _FieldSpec(contentKey: 'url', label: 'URL del audio', hint: 'Link al MP3'),
        _FieldSpec(contentKey: 'title', label: 'Título', hint: 'Cómo se escucha'),
        _FieldSpec(contentKey: 'author', label: 'Autor', hint: 'Persona o equipo'),
        _FieldSpec(contentKey: 'xp', label: 'XP', hint: 'Bonus', keyboardType: TextInputType.number),
      ];
    case BlockType.pdf:
      return const [
        _FieldSpec(contentKey: 'url', label: 'URL del PDF', hint: 'https://.../document.pdf'),
      ];
    case BlockType.carousel:
      return const [
        _FieldSpec(
          contentKey: 'items',
          label: 'Slides (JSON)',
          hint: '[ {"title": "Slide"} ]',
          isJson: true,
          maxLines: 6,
        ),
        _FieldSpec(contentKey: 'xp', label: 'XP', hint: 'Recompensa', keyboardType: TextInputType.number),
      ];
    default:
      return [];
  }
}
