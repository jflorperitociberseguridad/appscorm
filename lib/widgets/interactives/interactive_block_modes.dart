enum InteractiveBlockMode { editing, preview, interactive }

class BlockContentChanged {
  final Map<String, dynamic> content;
  BlockContentChanged(this.content);
}
