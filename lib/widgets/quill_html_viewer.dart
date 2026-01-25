import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'dart:convert';
import 'dart:typed_data';

class QuillHtmlViewer extends StatelessWidget {
  final String htmlContent;

  const QuillHtmlViewer({super.key, required this.htmlContent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: HtmlWidget(
        htmlContent.isEmpty ? '<p style="color:grey">Sin contenido</p>' : htmlContent,
        textStyle: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
        
        customStylesBuilder: (element) {
          if (element.localName == 'h1') return {'font-weight': 'bold', 'font-size': '24px', 'margin-bottom': '10px'};
          if (element.localName == 'h2') return {'font-weight': 'bold', 'font-size': '20px', 'margin-top': '15px'};
          if (element.localName == 'li') return {'margin-left': '20px'};
          // Evitar que la imagen se salga del ancho
          if (element.localName == 'img') return {'max-width': '100%', 'height': 'auto', 'display': 'block'};
          return null;
        },

        customWidgetBuilder: (element) {
          if (element.localName == 'img') {
            var src = element.attributes['src'];
            if (src != null) {
              
              // CASO A: Imagen en Base64 (data:image/png;base64,...)
              if (src.startsWith('data:image')) {
                try {
                  final base64String = src.split(',').last;
                  final Uint8List bytes = base64Decode(base64String);
                  return Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    // 🔥 TRUCO: Reducimos calidad visual para salvar RAM
                    cacheWidth: 600, 
                  );
                } catch (e) {
                  return const Text("Error img base64");
                }
              }
              
              // CASO B: Imagen de Internet (URL)
              return Image.network(
                src,
                fit: BoxFit.contain,
                // 🔥 EL SALVAVIDAS: Esto limita el uso de RAM drásticamente
                // Le dice a Flutter: "No uses más de 600px de ancho en memoria"
                cacheWidth: 600, 
                
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.grey.shade100,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("Img no disponible", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                },
              );
            }
          }
          return null;
        },
      ),
    );
  }
}