import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

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
        
        // Estilos personalizados
        customStylesBuilder: (element) {
          if (element.localName == 'h1') {
            return {'font-weight': 'bold', 'font-size': '24px', 'margin-bottom': '10px'};
          }
          if (element.localName == 'h2') {
            return {'font-weight': 'bold', 'font-size': '20px', 'margin-top': '15px'};
          }
          if (element.localName == 'li') {
            return {'margin-left': '20px'};
          }
          return null;
        },
        
        // Manejo de errores de imagen
        onErrorBuilder: (context, element, error) => Text('Error cargando imagen: $error'),
        
        // NOTA: Hemos quitado loadingBuilder porque no existe en la v0.15.3
        // La librería ya muestra un placeholder por defecto o carga rápido.
      ),
    );
  }
}