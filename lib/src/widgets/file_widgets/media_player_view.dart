import 'package:appinio_video_player/appinio_video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  late CachedVideoPlayerController _videoPlayerController;

  late CustomVideoPlayerController _customVideoPlayerController;
  late CustomVideoPlayerWebController _customVideoPlayerWebController;

  final CustomVideoPlayerSettings _customVideoPlayerSettings =
      const CustomVideoPlayerSettings(
    showFullscreenButton: false,
    playbackSpeedButtonAvailable: false,
    settingsButtonAvailable: false,
  );

  late CustomVideoPlayerWebSettings _customVideoPlayerWebSettings;

  @override
  void initState() {
    super.initState();

    _videoPlayerController = CachedVideoPlayerController.network(
      widget.path,
    )..initialize().then((value) => setState(() {}));
    _customVideoPlayerController = CustomVideoPlayerController(
      context: context,
      videoPlayerController: _videoPlayerController,
      customVideoPlayerSettings: _customVideoPlayerSettings,
    );

    _customVideoPlayerWebSettings = CustomVideoPlayerWebSettings(
      src: widget.path,
      autoplay: true,
      hideDownloadButton: true,
      disablePictureInPicture: true,
    );

    _customVideoPlayerWebController = CustomVideoPlayerWebController(
      webVideoPlayerSettings: _customVideoPlayerWebSettings,
    );
  }

  @override
  void dispose() {
    _customVideoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: kIsWeb
          ? CustomVideoPlayerWeb(
              customVideoPlayerWebController: _customVideoPlayerWebController,
            )
          : CustomVideoPlayer(
              customVideoPlayerController: _customVideoPlayerController,
            ),
    );
  }
}
