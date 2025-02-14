part of '../jsonschema_form_builder.dart';

// TODO(martinpelli): add possibility to change to front camera
// TODO(martinpelli): add possibility to change to use flash light
// TODO(martinpelli): some times buildPreview() is showing actual live camera
class _CameraScreen extends StatefulWidget {
  const _CameraScreen({
    required this.isPhotoAllowed,
    required this.isVideoAllowed,
    this.resolution = CameraResolution.max,
  });

  final bool isPhotoAllowed;
  final bool isVideoAllowed;
  final CameraResolution resolution;

  @override
  State<_CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<_CameraScreen>
    with WidgetsBindingObserver {
  bool isRecording = false;
  Timer? _timer;

  CameraController? _controller;

  XFile? file;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _initializeCamera();

    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeCamera() {
    if (!mounted) return;

    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    _controller = null;
    availableCameras().then((cameras) {
      _controller = CameraController(
        cameras[0],
        widget.resolution.resolutionPreset,
      );
      _controller?.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
        });
        setState(() {});
      }).catchError((Object e) {
        if (e is CameraException) {
          switch (e.code) {
            case 'CameraAccessDenied':
              break;
            default:
              break;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                CameraPreview(_controller!),
                if (isRecording)
                  Positioned(
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _formatSecondsToHHMMSS(_timer!.tick),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                if (!kIsWeb)
                  Positioned(
                    left: 20,
                    top: 20,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, size: 50),
                    ),
                  ),
                Positioned(
                  bottom: 50,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isPhotoAllowed && widget.isVideoAllowed) ...[
                        _buildPhotoButton(),
                        const SizedBox(width: 10),
                        _buildVideoButton(),
                      ] else if (widget.isVideoAllowed)
                        _buildVideoButton()
                      else
                        _buildPhotoButton(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPhotoButton() => SizedBox(
        width: 120,
        height: 120,
        child: ElevatedButton(
          style:
              const ButtonStyle(shape: WidgetStatePropertyAll(CircleBorder())),
          onPressed: () async {
            setState(() {
              _isLoading = true;
            });

            final navigator = Navigator.of(context);

            file = await _controller!.takePicture();

            if (!kIsWeb) {
              file = await file?.rename(DateTime.now().toIso8601String());
            }

            //await _buildPreviewAndAskIfDone();
            navigator.pop(file);
          },
          child: const Text(
            'Take Picture',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black),
          ),
        ),
      );

  Widget _buildVideoButton() => SizedBox(
        width: 85,
        height: 85,
        child: ElevatedButton(
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            backgroundColor: const WidgetStatePropertyAll(Colors.red),
            shape: WidgetStatePropertyAll(
              isRecording
                  ? RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    )
                  : const CircleBorder(),
            ),
          ),
          onPressed: () async {
            if (isRecording) {
              _timer?.cancel();

              setState(() {
                _isLoading = true;
              });

              final navigator = Navigator.of(context);

              file = await _controller!.stopVideoRecording();

              if (!kIsWeb) {
                file = await file?.rename(DateTime.now().toIso8601String());
              }

              //await _buildPreviewAndAskIfDone();

              navigator.pop(file);
            } else {
              await _controller!.startVideoRecording();
              _timer?.cancel();
              _timer = Timer.periodic(const Duration(seconds: 1), (_) {
                setState(() {});
              });
            }
            isRecording = !isRecording;
            setState(() {});
          },
          child: Text(
            isRecording ? 'Stop' : 'Record',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      );

  Future<void> _buildPreviewAndAskIfDone() async {
    final navigator = Navigator.of(context);

    final widgetPreview = _controller!.buildPreview();

    final isConfirmed = await showDialog<bool?>(
      context: context,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);

        return AlertDialog(
          title: const Text('Confirm Photo/Video'),
          content: SizedBox(
            width: size.width / 2,
            height: size.height / 2,
            child: widgetPreview,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                await _controller!.pausePreview();
                await _controller!.dispose();

                _initializeCamera();
              },
              child: const Text('Retake'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (isConfirmed != null && isConfirmed) {
      navigator.pop(file);
    }
  }

  String _formatSecondsToHHMMSS(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$secs';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }
}
/// Extension for converting [CameraResolution] to [ResolutionPreset].
///
/// This extension provides a way to convert a [CameraResolution] value into
/// its corresponding [ResolutionPreset] value. It is useful when you need to
/// map different camera resolutions to preset values that 
/// the camera API can use.
///
/// Example usage:
/// ```dart
/// CameraResolution resolution = CameraResolution.high;
/// ResolutionPreset preset = resolution.resolutionPreset;
/// ```
extension CameraResolutionExt on CameraResolution {
  /// Converts the [CameraResolution] to the corresponding [ResolutionPreset].
  ///
  /// This method maps the different camera resolution levels 
  /// (low, medium, high, etc.) to the corresponding preset values available 
  /// in the [ResolutionPreset] enum.
  ///
  /// Returns the appropriate [ResolutionPreset] 
  /// based on the current [CameraResolution].
  ResolutionPreset get resolutionPreset {
    switch (this) {
      case CameraResolution.low:
        return ResolutionPreset.low;
      case CameraResolution.medium:
        return ResolutionPreset.medium;
      case CameraResolution.high:
        return ResolutionPreset.high;
      case CameraResolution.veryHigh:
        return ResolutionPreset.veryHigh;
      case CameraResolution.ultraHigh:
        return ResolutionPreset.ultraHigh;
      case CameraResolution.max:
        return ResolutionPreset.max;
    }
  }
}
