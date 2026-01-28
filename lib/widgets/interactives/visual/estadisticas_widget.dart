import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class EstadisticasWidget extends StatelessWidget {
  final InteractiveBlock block;

  const EstadisticasWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    // Aseguramos que haya una configuración por defecto
    block.content['show_charts'] ??= true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera del Bloque
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bar_chart, color: Colors.blue),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Panel de Estadísticas del Alumno",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Este bloque mostrará automáticamente el progreso real al alumno.",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),

            // PREVISUALIZACIÓN (MOCKUP)
            // Esto es lo que verá el profesor para saber qué diseño tiene
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text("VISTA PREVIA (Ejemplo)", 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMockStat("Progreso", "75%", Colors.green, Icons.percent),
                      _buildMockStat("Nota Media", "8.5", Colors.blue, Icons.grade),
                      _buildMockStat("Tiempo", "2h 15m", Colors.orange, Icons.timer),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Barra de progreso simulada
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: 0.75,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            // OPCIONES DE CONFIGURACIÓN (Solo interruptores, no texto)
            SwitchListTile(
              title: const Text("Mostrar Gráficos Detallados"),
              subtitle: const Text("Incluye desglose por módulos"),
              value: block.content['show_charts'] == true,
              activeThumbColor: Colors.blue,
              onChanged: (val) {
                // Aquí necesitaríamos un setState si fuera Stateful, 
                // pero como el bloque se actualiza por referencia, 
                // forzamos la reconstrucción desde el padre o lo convertimos a Stateful.
                // Para simplificar, asume que al guardar se actualiza.
                block.content['show_charts'] = val;
                (context as Element).markNeedsBuild(); // Truco para refrescar UI rápido
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockStat(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
