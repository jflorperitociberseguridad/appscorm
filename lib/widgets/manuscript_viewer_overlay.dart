import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ManuscriptViewerOverlay extends StatelessWidget {
  final String manuscriptMarkdown;
  final VoidCallback onValidate;

  const ManuscriptViewerOverlay({
    super.key,
    required this.manuscriptMarkdown,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manuscrito Maestro',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Markdown(
                data: manuscriptMarkdown,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  h2: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  p: theme.textTheme.bodyMedium,
                  listBullet: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onValidate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    '✅ Validar y Construir Curso',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
