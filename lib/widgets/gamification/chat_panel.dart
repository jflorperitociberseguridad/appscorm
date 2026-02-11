import 'package:flutter/material.dart';

import 'models.dart';

class GamificationChatPanel extends StatefulWidget {
  const GamificationChatPanel({super.key});

  @override
  GamificationChatPanelState createState() => GamificationChatPanelState();
}

class GamificationChatPanelState extends State<GamificationChatPanel> {
  final List<GamificationChatMessage> _messages = [
    GamificationChatMessage(sender: 'system', text: 'Bienvenido al canal del curso', time: DateTime.now().subtract(const Duration(minutes: 30))),
    GamificationChatMessage(sender: 'tutor', text: 'Recuerda completar el módulo 2', time: DateTime.now().subtract(const Duration(minutes: 20))),
  ];
  final List<GamificationChatMessage> _systemMessages = [
    GamificationChatMessage(sender: 'system', text: 'Actualización: nuevos recursos disponibles en el curso.', time: DateTime.now().subtract(const Duration(hours: 3))),
    GamificationChatMessage(sender: 'system', text: 'Recordatorio: examen final programado para esta semana.', time: DateTime.now().subtract(const Duration(days: 1))),
  ];

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    final msg = GamificationChatMessage(sender: 'me', text: text, time: DateTime.now());
    setState(() {
      _messages.add(msg);
      _chatController.clear();
    });
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(_chatScroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _openMessageCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => MessageCenterSheet(
        internalMessages: _messages,
        systemMessages: _systemMessages,
        onSend: (text) {
          final msg = GamificationChatMessage(sender: 'me', text: text, time: DateTime.now());
          setState(() {
            _messages.add(msg);
          });
        },
      ),
    );
  }

  void openMessageCenter() => _openMessageCenter();

  @override
  void dispose() {
    _chatController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160, maxHeight: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Canal de Mensajes', style: TextStyle(fontWeight: FontWeight.bold))),
              TextButton.icon(
                onPressed: _openMessageCenter,
                icon: const Icon(Icons.inbox, size: 16),
                label: const Text('Bandeja'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ListView.builder(
                controller: _chatScroll,
                itemCount: _messages.length,
                shrinkWrap: true,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final mine = m.sender == 'me';
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!mine)
                          CircleAvatar(radius: 14, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, size: 16, color: Colors.black54)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: mine ? const Color(0xFF2563EB) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.text,
                                  style: TextStyle(color: mine ? Colors.white : Colors.black87),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${m.time.hour.toString().padLeft(2, '0')}:${m.time.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 10, color: mine ? Colors.white70 : Colors.grey),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (mine)
                          CircleAvatar(radius: 14, backgroundColor: Colors.blue.shade50, child: const Icon(Icons.person, size: 16, color: Color(0xFF2563EB))),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sendMessage,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14)),
                child: const Icon(Icons.send, size: 18),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class MessageCenterSheet extends StatefulWidget {
  final List<GamificationChatMessage> internalMessages;
  final List<GamificationChatMessage> systemMessages;
  final ValueChanged<String> onSend;

  const MessageCenterSheet({
    super.key,
    required this.internalMessages,
    required this.systemMessages,
    required this.onSend,
  });

  @override
  State<MessageCenterSheet> createState() => _MessageCenterSheetState();
}

class _MessageCenterSheetState extends State<MessageCenterSheet> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _scheduleSetState(VoidCallback fn) {
    if (mounted) {
      Future.microtask(() => setState(fn));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 460,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2563EB),
              tabs: const [
                Tab(text: 'Internos'),
                Tab(text: 'Sistema'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMessages(widget.internalMessages),
                  _buildMessages(widget.systemMessages),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final text = _inputController.text.trim();
                      if (text.isEmpty) return;
                      widget.onSend(text);
                      _inputController.clear();
                      _scheduleSetState(() {});
                    },
                    child: const Text('Enviar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(List<GamificationChatMessage> messages) {
    if (messages.isEmpty) {
      return const Center(child: Text('Sin mensajes.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(msg.text),
          subtitle: Text('${msg.time.day.toString().padLeft(2, '0')}/${msg.time.month.toString().padLeft(2, '0')} ${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}'),
          leading: Icon(msg.sender == 'system' ? Icons.info_outline : Icons.person_outline),
        );
      },
    );
  }
}
