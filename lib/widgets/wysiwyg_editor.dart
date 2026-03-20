import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';

class WysiwygEditor extends StatefulWidget {
  final String initialContent;
  final String label;
  final Function(String) onChanged;

  const WysiwygEditor({
    super.key,
    this.initialContent = '',
    required this.label,
    required this.onChanged,
  });

  @override
  State<WysiwygEditor> createState() => _WysiwygEditorState();
}

class _WysiwygEditorState extends State<WysiwygEditor> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeEditor();
  }

  @override
  void didUpdateWidget(covariant WysiwygEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialContent != oldWidget.initialContent) {
      _controller.removeListener(_onEditorChanged);
      _initializeEditor();
    }
  }

  void _initializeEditor() {
    if (widget.initialContent.isEmpty) {
      _controller = QuillController.basic();
    } else {
      try {
        final delta = HtmlToDelta().convert(widget.initialContent);
        _controller = QuillController(
          document: Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: false,
        );
      } catch (e) {
        debugPrint('Error converting HTML to Delta: $e');
        _controller = QuillController.basic();
      }
    }
    
    _controller.addListener(_onEditorChanged);
  }

  void _onEditorChanged() {
    final delta = _controller.document.toDelta();
    final converter = QuillDeltaToHtmlConverter(
      delta.toJson(),
      ConverterOptions(
        converterOptions: OpConverterOptions(
          inlineStylesFlag: true,
        ),
      ),
    );
    
    final html = converter.convert();
    widget.onChanged(html);
  }

  @override
  void dispose() {
    _controller.removeListener(_onEditorChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // SINTAXIS V10 (Controller DENTRO)
              QuillToolbar.simple(
                configurations: QuillSimpleToolbarConfigurations(
                  controller: _controller,
                  showFontFamily: false,
                  showFontSize: true,
                  showBoldButton: true,
                  showItalicButton: true,
                  showUnderLineButton: true,
                  showStrikeThrough: true,
                  showColorButton: true,
                  showBackgroundColorButton: true,
                  showClearFormat: true,
                  showHeaderStyle: true,
                  showListNumbers: true,
                  showListBullets: true,
                  showQuote: true,
                  showCodeBlock: true,
                  showLink: true,
                  showUndo: true,
                  showRedo: true,
                  multiRowsDisplay: false,
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              
              // SINTAXIS V10 (Controller DENTRO)
              SizedBox(
                height: 400,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: QuillEditor.basic(
                    configurations: QuillEditorConfigurations(
                      controller: _controller, // <--- AQUÍ DENTRO
                      placeholder: 'Escribe aquí el contenido...',
                      autoFocus: false,
                      expands: false,
                      padding: EdgeInsets.zero,
                      scrollable: true,
                      sharedConfigurations: const QuillSharedConfigurations(
                        locale: Locale('es'),
                      ),
                    ),
                    focusNode: _focusNode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}