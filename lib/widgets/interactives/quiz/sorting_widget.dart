import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/interactive_block.dart';
import '../../../../providers/course_provider.dart';

class SortingWidget extends StatefulWidget {
  final InteractiveBlock block;
  const SortingWidget({super.key, required this.block});
  @override
  State<SortingWidget> createState() => _SortingWidgetState();
}

class _SortingWidgetState extends State<SortingWidget> {
  late List<Map<String, dynamic>> items;
  bool _verified = false;
  bool _isCorrect = false;
  bool _autoValidate = false;

  @override
  void initState() {
    super.initState();
    items = _normalizeItems(widget.block.content['items']);
    _autoValidate = widget.block.content['autoValidate'] == true;
    _shuffleIfNeeded();
    widget.block.content['items'] = items;
  }

  List<Map<String, dynamic>> _normalizeItems(dynamic raw) {
    if (raw is List && raw.isNotEmpty) {
      return raw.asMap().entries.map((entry) {
        final map = (entry.value is Map) ? (entry.value as Map).cast<String, dynamic>() : <String, dynamic>{};
        final correct = map['indexCorrecto'] ?? map['correctIndex'] ?? entry.key;
        return {
          'text': (map['text'] ?? map['label'] ?? 'Item ${entry.key + 1}').toString(),
          'indexCorrecto': (correct is num) ? correct.toInt() : int.tryParse(correct.toString()) ?? entry.key,
        };
      }).toList();
    }
    return List.generate(4, (i) => {
          'text': 'Paso ${i + 1}',
          'indexCorrecto': i,
        });
  }

  void _shuffleIfNeeded() {
    final shuffled = widget.block.content['shuffled'] == true;
    if (shuffled) return;
    items.shuffle();
    widget.block.content['shuffled'] = true;
  }

  void _shuffleNow() {
    setState(() {
      items.shuffle();
      widget.block.content['items'] = items;
      widget.block.content['shuffled'] = true;
      _verified = false;
      _isCorrect = false;
    });
  }

  void _verifyOrder() {
    final correct = _isOrderCorrect();
    setState(() {
      _verified = true;
      _isCorrect = correct;
    });
    if (correct) {
      widget.block.content['isCompleted'] = true;
      final alreadyEarned = widget.block.content['xpEarned'] == true;
      widget.block.content['xpEarned'] = true;
      final rawXp = widget.block.content['xp'];
      final earned = rawXp is num ? rawXp.toInt() : int.tryParse(rawXp?.toString() ?? '') ?? 0;
      widget.block.content['earnedXp'] = earned;
      if (!alreadyEarned) {
        _notifyProgress(earned);
      }
    }
  }

  bool _isOrderCorrect() {
    for (int i = 0; i < items.length; i++) {
      if ((items[i]['indexCorrecto'] as int?) != i) return false;
    }
    return true;
  }

  void _notifyProgress(int earnedXp) {
    Future.microtask(() {
      if (!mounted) return;
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(courseProvider.notifier).updateBlockProgress(
            widget.block.id,
            isCompleted: true,
            xpEarned: true,
            earnedXp: earnedXp,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _verified
        ? (_isCorrect ? Colors.green.shade400 : Colors.red.shade400)
        : Colors.grey.shade300;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1.4),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.sort), 
              title: Text("Ordenar Elementos"),
              subtitle: Text("Arrastra para definir el orden correcto"),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Instrucción (Ej: Ordena de mayor a menor)'),
              controller: TextEditingController(text: widget.block.content['instruction']),
              onChanged: (v) => widget.block.content['instruction'] = v,
            ),
            const SizedBox(height: 10),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (int index = 0; index < items.length; index++)
                  Card(
                    key: ValueKey('sort_${index}_${items[index]['indexCorrecto']}'),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      key: ValueKey(items[index]),
                    leading: const Icon(Icons.drag_handle),
                    title: TextField(
                      controller: TextEditingController(text: items[index]['text']),
                      onChanged: (v) => items[index]['text'] = v,
                      decoration: InputDecoration(labelText: 'Elemento ${index + 1}'),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => items.removeAt(index)),
                    ),
                    ),
                  ),
              ],
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) newIndex -= 1;
                  final item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                  widget.block.content['items'] = items;
                  _verified = false;
                });
                if (_autoValidate) {
                  _verifyOrder();
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => setState(() {
                    items.add({'text': 'Nuevo Item', 'indexCorrecto': items.length});
                    widget.block.content['items'] = items;
                  }),
                  child: const Text("Añadir Elemento"),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: items.length < 2 ? null : _verifyOrder,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Verificar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: items.length < 2 ? null : _shuffleNow,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Restablecer orden aleatorio'),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Switch(
                      value: _autoValidate,
                      onChanged: (value) => setState(() {
                        _autoValidate = value;
                        widget.block.content['autoValidate'] = value;
                      }),
                    ),
                    const Text('Validar al soltar', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            if (_verified)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _isCorrect ? 'Secuencia correcta ✅' : 'Orden incorrecto. Reintenta.',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isCorrect ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
