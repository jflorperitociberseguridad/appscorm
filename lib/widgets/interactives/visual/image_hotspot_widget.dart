import 'package:flutter/material.dart';
import '../../../../models/interactive_block.dart';

class ImageHotspotWidget extends StatelessWidget {
  final InteractiveBlock block;

  const ImageHotspotWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final url = block.content['url'] ?? 'https://placehold.co/600x400';
    // Recuperamos los hotspots, si existen
    final List hotspots = block.content['hotspots'] ?? [];

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculamos dimensiones para posicionar los puntos relativos
            final width = constraints.maxWidth;
            final height = width * 0.6; // Asumimos un aspecto ratio aproximado o dejamos que la imagen decida

            return Stack(
              children: [
                // 1. LA IMAGEN
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    width: width,
                    fit: BoxFit.cover,
                    errorBuilder: (_,__,___) => Container(height: 200, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                  ),
                ),
                // 2. LOS PUNTOS (HOTSPOTS)
                ...hotspots.map((point) {
                  // Convertimos porcentaje (0-100) a píxeles
                  final double x = (point['x'] is int) ? (point['x'] as int).toDouble() : (point['x'] as double);
                  final double y = (point['y'] is int) ? (point['y'] as int).toDouble() : (point['y'] as double);
                  
                  // Posicionamiento simple basado en porcentaje del ancho del contenedor
                  // Nota: Para precisión perfecta se necesita saber el aspect ratio real de la imagen cargada
                  return Positioned(
                    left: (x / 100) * width, 
                    top: (y / 100) * width * 0.6, // Estimación
                    child: Tooltip(
                      message: point['text'] ?? '',
                      triggerMode: TooltipTriggerMode.tap,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9), 
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)]
                        ),
                        child: const Icon(Icons.add_circle, color: Colors.indigo, size: 24),
                      ),
                    ),
                  );
                }),
              ],
            );
          }
        ),
        if (block.content['caption'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(block.content['caption'], style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          ),
      ],
    );
  }
}