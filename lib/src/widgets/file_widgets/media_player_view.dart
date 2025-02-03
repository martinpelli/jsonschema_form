import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A widget that provides a video player to play a media file.
class MediaPlayerView extends StatefulWidget {
  /// Creates a [MediaPlayerView] widget that plays
  /// a video from the given [path].
  ///
  /// The [path] should be a valid `String` pointing to the video to be played.
  /// For web platforms, the `path` should be a valid URL.
  const MediaPlayerView({required this.path, super.key});

  /// The [String] representing the video file path to be played.
  /// This property holds the video file's location. It can either be
  /// a file path or a network URL
  /// (depending on the platform, for example, web).
  final String path;

  @override
  State<StatefulWidget> createState() => _MediaPlayerViewState();
}

class _MediaPlayerViewState extends State<MediaPlayerView> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // Handle web behavior: Use `VideoPlayerController.networkUrl()` for web
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.path), // For web, path is treated as URL
      )..initialize().then((_) {
          setState(() {});
          _isPlaying = true;
          _controller.play(); // Optionally start the video on initialization
        });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: () {
            if (_isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
            setState(() {
              _isPlaying = !_isPlaying;
            });
          },
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
        ),
        // Play/Pause Button
        Positioned(
          bottom: 20,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                if (_isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
                _isPlaying = !_isPlaying;
              });
            },
            backgroundColor: Colors.black.withValues(alpha: 0.5),
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
          ),
        ),
        // Close Button with Shadow
        Positioned(
          top: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () {
              // Dismiss or close the video player
              Navigator.of(context).pop();
            },
            backgroundColor: Colors.black.withValues(alpha: 0.5),
            child: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
