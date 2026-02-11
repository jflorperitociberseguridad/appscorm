import 'package:flutter/material.dart';

import '../../models/course_model.dart';
import '../../services/ai_service.dart';

class SupportScreen extends StatefulWidget {
  final CourseModel? course;

  const SupportScreen({super.key, required this.course});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _issueController = TextEditingController();
  String? _aiResponse;
  bool _isConsulting = false;
  late final Future<AiService> _aiServiceFuture;

  void _scheduleSetState(VoidCallback fn) {
    if (mounted) {
      Future.microtask(() => setState(fn));
    }
  }

  @override
  void initState() {
    super.initState();
    _aiServiceFuture = AiService.create();
  }

  @override
  void dispose() {
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _consultAi() async {
    final issue = _issueController.text.trim();
    if (issue.isEmpty) return;
    _scheduleSetState(() {
      _isConsulting = true;
      _aiResponse = null;
    });
    final aiService = await _aiServiceFuture;
    const guide = 'Guia rapida AppScorm: revisar contenido, exportacion SCORM, y sincronizacion de modulos.';
    final response = await aiService.analyzeDocument('Consulta: $issue\n$guide');
    if (!mounted) return;
    _scheduleSetState(() {
      _aiResponse = response;
      _isConsulting = false;
    });
  }

  void _sendTicket() {
    final issue = _issueController.text.trim();
    if (issue.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket enviado a soporte.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicio Tecnico'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Describe tu problema', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _issueController,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ej: Fallo al exportar SCORM...',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isConsulting ? null : _consultAi,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_isConsulting ? 'Consultando...' : 'Consultar a la IA'),
            ),
            if (_aiResponse != null) ...[
              const SizedBox(height: 16),
              const Text('Respuesta IA', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_aiResponse!),
                ),
              ),
            ] else
              const Spacer(),
            ElevatedButton(
              onPressed: _sendTicket,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text('Enviar ticket', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
