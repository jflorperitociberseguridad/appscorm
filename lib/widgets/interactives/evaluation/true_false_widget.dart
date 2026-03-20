import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class TrueFalseWidget extends StatefulWidget {
  final InteractiveBlock block;
  const TrueFalseWidget({super.key, required this.block});

  @override
  State<TrueFalseWidget> createState() => _TrueFalseWidgetState();
}

class _TrueFalseWidgetState extends State<TrueFalseWidget> {
  bool? _selectedAnswer;
  bool _showFeedback = false;

  @override
  Widget build(BuildContext context) {
    final question = widget.block.content['question'] ?? 'Pregunta...';
    final correctAnswer = widget.block.content['correctValue'] ?? true;

    return Card(
      elevation: 0,
      color: Colors.indigo[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.indigo),
                const SizedBox(width: 10),
                Expanded(child: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedAnswer == true ? Colors.indigo : Colors.white,
                      foregroundColor: _selectedAnswer == true ? Colors.white : Colors.indigo,
                      elevation: 0,
                      side: const BorderSide(color: Colors.indigo)
                    ),
                    onPressed: () => setState(() { _selectedAnswer = true; _showFeedback = false; }),
                    child: const Text("VERDADERO"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedAnswer == false ? Colors.indigo : Colors.white,
                      foregroundColor: _selectedAnswer == false ? Colors.white : Colors.indigo,
                      elevation: 0,
                      side: const BorderSide(color: Colors.indigo)
                    ),
                    onPressed: () => setState(() { _selectedAnswer = false; _showFeedback = false; }),
                    child: const Text("FALSO"),
                  ),
                ),
              ],
            ),
            if (_selectedAnswer != null) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showFeedback = true),
                  icon: const Icon(Icons.check),
                  label: const Text("COMPROBAR RESPUESTA"),
                ),
              )
            ],
            if (_showFeedback)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _selectedAnswer == correctAnswer ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Row(
                  children: [
                    Icon(_selectedAnswer == correctAnswer ? Icons.check_circle : Icons.error, color: _selectedAnswer == correctAnswer ? Colors.green[800] : Colors.red[800]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedAnswer == correctAnswer ? "¡Correcto!" : "Incorrecto, inténtalo de nuevo.",
                        style: TextStyle(
                          color: _selectedAnswer == correctAnswer ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }
}