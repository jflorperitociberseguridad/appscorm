import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:uuid/uuid.dart';

class WebImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const WebImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    // Generamos un ID único para registrar esta vista
    final String viewId = 'web-image-${const Uuid().v4()}';

    // Registramos el factory para crear el elemento <img>
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
      final img = html.ImageElement()
        ..src = imageUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _mapBoxFit(fit)
        ..style.borderRadius = '8px'; // Border radius similar al diseño
        
      
      // Manejo de errores básico
      img.onError.listen((event) {
        img.src = 'https://picsum.photos/seed/error/600/400'; // Fallback visual
      });

      return img;
    });

    return SizedBox(
      width: width,
      height: height,
      child: HtmlElementView(viewType: viewId),
    );
  }

  String _mapBoxFit(BoxFit? fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
      default:
        return 'cover';
    }
  }
}
