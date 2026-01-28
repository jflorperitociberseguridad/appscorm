import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../models/interactive_block.dart';
import '../../../providers/course_provider.dart';

class VideoWidget extends StatefulWidget {
  final InteractiveBlock block;
  const VideoWidget({super.key, required this.block});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController? _controller;
  YoutubePlayerController? _ytController;
  StreamSubscription<YoutubeVideoState>? _ytStateSub;
  StreamSubscription<YoutubePlayerValue>? _ytValueSub;
  WebViewController? _vimeoController;
  bool _isReady = false;
  bool _showControls = true;
  bool _earned = false;
  Duration _ytDuration = Duration.zero;
  Duration _ytPosition = Duration.zero;
  Duration _vimeoDuration = Duration.zero;
  Duration _vimeoPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _ytStateSub?.cancel();
    _ytValueSub?.cancel();
    _ytController?.close();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    final url = (widget.block.content['url'] ?? '').toString().trim();
    if (url.isEmpty) return;
    final source = _detectSource(url);
    if (source == _VideoSource.youtube) {
      final id = _extractYoutubeId(url);
      if (id == null) return;
      final ytController = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          loop: false,
        ),
      );
      ytController.loadVideoById(videoId: id);
      _ytValueSub = ytController.stream.listen((value) {
        if (!mounted) return;
        _ytDuration = value.metaData.duration;
        _checkProgress(_ytPosition, _ytDuration);
        setState(() {});
      });
      _ytStateSub = ytController.videoStateStream.listen((state) {
        if (!mounted) return;
        _ytPosition = state.position;
        _checkProgress(_ytPosition, _ytDuration);
        setState(() {});
      });
      setState(() {
        _ytController = ytController;
        _isReady = true;
      });
      return;
    }

    if (source == _VideoSource.vimeo) {
      final id = _extractVimeoId(url);
      if (id == null) return;
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          'VimeoProgress',
          onMessageReceived: (message) {
            final data = _parseVimeoMessage(message.message);
            if (data == null) return;
            _vimeoPosition = Duration(milliseconds: (data['current']! * 1000).toInt());
            _vimeoDuration = Duration(milliseconds: (data['duration']! * 1000).toInt());
            _checkProgress(_vimeoPosition, _vimeoDuration);
            if (mounted) setState(() {});
          },
        )
        ..loadHtmlString(_vimeoHtml(id));
      setState(() {
        _vimeoController = controller;
        _isReady = true;
      });
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    await controller.initialize();
    controller.addListener(_onTick);
    setState(() {
      _controller = controller;
      _isReady = true;
    });
  }

  void _onTick() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;
    if (!value.isInitialized || value.duration.inMilliseconds == 0) return;
    _checkProgress(value.position, value.duration);
    setState(() {});
  }

  void _checkProgress(Duration position, Duration duration) {
    if (duration.inMilliseconds == 0) return;
    final progress = position.inMilliseconds / duration.inMilliseconds;
    if (progress >= 0.9 && !_earned) {
      _earned = true;
      _markCompleted();
    }
  }

  void _markCompleted() {
    widget.block.content['isCompleted'] = true;
    widget.block.content['xpEarned'] = true;
    final rawXp = widget.block.content['xp'];
    final earned = rawXp is num ? rawXp.toInt() : int.tryParse(rawXp?.toString() ?? '') ?? 0;
    widget.block.content['earnedXp'] = earned;
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(courseProvider.notifier).updateBlockProgress(
          widget.block.id,
          isCompleted: true,
          xpEarned: true,
          earnedXp: earned,
        );
  }

  void _togglePlay() {
    if (_controller != null) {
      final playing = _controller!.value.isPlaying;
      if (playing) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
      setState(() {});
      return;
    }
    if (_ytController != null) {
      final playing = _ytController!.value.playerState == PlayerState.playing;
      if (playing) {
        _ytController!.pauseVideo();
      } else {
        _ytController!.playVideo();
      }
      setState(() {});
    }
  }

  void _toggleFullscreen() {
    if (_controller != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _VideoFullscreen(controller: _controller!),
        ),
      );
      return;
    }
    if (_ytController != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _YoutubeFullscreen(controller: _ytController!),
        ),
      );
    }
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final prompt = widget.block.content['prompt'] ?? widget.block.content['style'];
    final title = widget.block.content['title'] ?? 'Video';
    if (!_isReady || _controller == null) {
      if (_ytController != null) {
        return _YoutubePlayerShell(
          controller: _ytController!,
          title: title.toString(),
          prompt: prompt?.toString(),
          onTogglePlay: _togglePlay,
          onToggleFullscreen: _toggleFullscreen,
          showControls: _showControls,
          onToggleControls: () => setState(() => _showControls = !_showControls),
          position: _ytPosition,
          duration: _ytDuration,
        );
      }
      if (_vimeoController != null) {
        return _VimeoPlayerShell(
          controller: _vimeoController!,
          title: title.toString(),
          prompt: prompt?.toString(),
          showControls: _showControls,
          onToggleControls: () => setState(() => _showControls = !_showControls),
          position: _vimeoPosition,
          duration: _vimeoDuration,
        );
      }
      return _VideoShell(title: title, prompt: prompt?.toString());
    }

    final value = _controller!.value;
    final remaining = value.duration - value.position;
    final progress = value.duration.inMilliseconds == 0
        ? 0.0
        : value.position.inMilliseconds / value.duration.inMilliseconds;
    final accent = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: AspectRatio(
        aspectRatio: value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: VideoPlayer(_controller!),
            ),
            if (_showControls)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            if (_showControls)
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  iconSize: 56,
                  icon: Icon(
                    value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.white,
                  ),
                  onPressed: _togglePlay,
                ),
              ),
            if (_showControls)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    if (prompt != null && prompt.toString().trim().isNotEmpty)
                      Text(
                        'Prompt sugerido: ${prompt.toString()}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    Row(
                      children: [
                        Text(
                          _format(remaining),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            activeColor: accent,
                            inactiveColor: Colors.white24,
                            onChanged: (v) {
                              final seek = value.duration * v;
                              _controller!.seekTo(seek);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.fullscreen, color: Colors.white),
                          onPressed: _toggleFullscreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _VideoSource { mp4, youtube, vimeo }

_VideoSource _detectSource(String url) {
  final lower = url.toLowerCase();
  if (lower.contains('youtube.com') || lower.contains('youtu.be')) return _VideoSource.youtube;
  if (lower.contains('vimeo.com')) return _VideoSource.vimeo;
  return _VideoSource.mp4;
}

String? _extractYoutubeId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
  }
  return uri.queryParameters['v'] ?? (uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null);
}

String? _extractVimeoId(String url) {
  final match = RegExp(r'vimeo\\.com\\/(?:video\\/)?(\\d+)').firstMatch(url);
  return match?.group(1);
}

Map<String, double>? _parseVimeoMessage(String message) {
  try {
    final data = jsonDecode(message);
    if (data is Map) {
      final current = (data['current'] as num?)?.toDouble();
      final duration = (data['duration'] as num?)?.toDouble();
      if (current != null && duration != null) {
        return {'current': current, 'duration': duration};
      }
    }
  } catch (_) {}
  return null;
}

String _vimeoHtml(String id) {
  return '''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://player.vimeo.com/api/player.js"></script>
    <style>
      html, body { margin:0; padding:0; height:100%; background:#000; }
      #player { width:100%; height:100%; }
    </style>
  </head>
  <body>
    <div id="player"></div>
    <script>
      const player = new Vimeo.Player('player', { id: $id, responsive: true });
      function sendProgress() {
        Promise.all([player.getCurrentTime(), player.getDuration()]).then(function(values) {
          VimeoProgress.postMessage(JSON.stringify({ current: values[0], duration: values[1] }));
        });
      }
      player.on('timeupdate', sendProgress);
    </script>
  </body>
</html>
''';
}

class _YoutubeFullscreen extends StatelessWidget {
  final YoutubePlayerController controller;
  const _YoutubeFullscreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            YoutubePlayer(controller: controller),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YoutubePlayerShell extends StatelessWidget {
  final YoutubePlayerController controller;
  final String title;
  final String? prompt;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleFullscreen;
  final bool showControls;
  final VoidCallback onToggleControls;
  final Duration position;
  final Duration duration;

  const _YoutubePlayerShell({
    required this.controller,
    required this.title,
    required this.prompt,
    required this.onTogglePlay,
    required this.onToggleFullscreen,
    required this.showControls,
    required this.onToggleControls,
    required this.position,
    required this.duration,
  });

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final remaining = duration - position;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;

    return GestureDetector(
      onTap: onToggleControls,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: YoutubePlayer(controller: controller),
            ),
            if (showControls)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            if (showControls)
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  iconSize: 56,
                  icon: Icon(
                    controller.value.playerState == PlayerState.playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                  ),
                  onPressed: onTogglePlay,
                ),
              ),
            if (showControls)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    if (prompt != null && prompt!.trim().isNotEmpty)
                      Text(
                        'Prompt sugerido: $prompt',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    Row(
                      children: [
                        Text(
                          _format(remaining),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            activeColor: accent,
                            inactiveColor: Colors.white24,
                            onChanged: (v) {
                              controller.seekTo(seconds: duration.inMilliseconds * v / 1000);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.fullscreen, color: Colors.white),
                          onPressed: onToggleFullscreen,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VimeoPlayerShell extends StatelessWidget {
  final WebViewController controller;
  final String title;
  final String? prompt;
  final bool showControls;
  final VoidCallback onToggleControls;
  final Duration position;
  final Duration duration;

  const _VimeoPlayerShell({
    required this.controller,
    required this.title,
    required this.prompt,
    required this.showControls,
    required this.onToggleControls,
    required this.position,
    required this.duration,
  });

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final remaining = duration - position;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;
    return GestureDetector(
      onTap: onToggleControls,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: WebViewWidget(controller: controller),
            ),
            if (showControls)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    if (prompt != null && prompt!.trim().isNotEmpty)
                      Text(
                        'Prompt sugerido: $prompt',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    Row(
                      children: [
                        Text(
                          _format(remaining),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            color: accent,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoShell extends StatelessWidget {
  final String title;
  final String? prompt;

  const _VideoShell({required this.title, this.prompt});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
            Text(title, style: const TextStyle(color: Colors.white)),
            if (prompt != null && prompt!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Prompt sugerido: $prompt',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VideoFullscreen extends StatelessWidget {
  final VideoPlayerController controller;
  const _VideoFullscreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(child: VideoPlayer(controller)),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
