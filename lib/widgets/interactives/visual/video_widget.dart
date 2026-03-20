import 'package:flutter/material.dart';
import '../../../models/interactive_block.dart';

class VideoWidget extends StatelessWidget {
  final InteractiveBlock block;
  const VideoWidget({super.key, required this.block});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
            Text(block.content['title'] ?? 'Video', style: const TextStyle(color: Colors.white))
          ],
        ),
      ),
    );
  }
}