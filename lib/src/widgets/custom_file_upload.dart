part of '../jsonschema_form_builder.dart';

//TODO add possibility to select video or photo
//TODO add possibility to change to front camera
//TODO add possibility to change to use flash light
//TODO fix issue some time buildPreview() is showing actual live camera
class _CustomFileUpload extends StatefulWidget {
  const _CustomFileUpload({
    required this.hasFilePicker,
    required this.hasCameraButton,
    required this.acceptedExtensions,
    required this.title,
    required this.onFileChosen,
  });

  final bool hasFilePicker;
  final bool hasCameraButton;
  final List<String>? acceptedExtensions;
  final String? title;
  final void Function(dynamic value) onFileChosen;

  @override
  State<_CustomFileUpload> createState() => _CustomFileUploadState();
}

class _CustomFileUploadState extends State<_CustomFileUpload>
    with WidgetsBindingObserver {
  XFile? _file;

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(widget.title!),
          ),
        Row(
          children: [
            if (widget.hasFilePicker) ...[
              ElevatedButton(
                onPressed: _openSingleFile,
                child: const Text('Choose File'),
              ),
              const SizedBox(width: 20),
            ],
            if (widget.hasCameraButton) ...[
              ElevatedButton(
                onPressed: _openCamera,
                child: const Text('Take Photo/Video'),
              ),
              const SizedBox(width: 20),
            ],
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Text(
                _file?.name == null
                    ? 'No file chosen'
                    : _file!.name.isEmpty
                        ? 'No file name'
                        : _file!.name,
              ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _openSingleFile() async {
    final selectedFile = await openFile(
      acceptedTypeGroups: <XTypeGroup>[
        XTypeGroup(extensions: widget.acceptedExtensions),
      ],
    );

    if (selectedFile != null) {
      setState(() => _isLoading = true);

      try {
        final encodedFile = kIsWeb
            ? await _encodeFileForWeb(selectedFile)
            : await _encodeFileInIsolate(selectedFile.path);

        widget.onFileChosen(
          // ignore: lines_longer_than_80_chars
          'data:${selectedFile.mimeType};name=${selectedFile.name};base64,$encodedFile',
        );

        setState(() {
          _file = selectedFile;
        });
      } catch (e) {
        if (kDebugMode) {
          print('Error during file encoding: $e');
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Encoding for Web
  Future<String> _encodeFileForWeb(XFile selectedFile) async {
    try {
      final bytes = await selectedFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Failed to encode file on web: $e');
    }
  }

  /// Encoding for Non-Web Platforms
  Future<String> _encodeFileInIsolate(String filePath) async {
    final receivePort = ReceivePort();

    /// Spawn the isolate for heavy computation
    await Isolate.spawn(_isolateEncode, [filePath, receivePort.sendPort]);

    final response = await receivePort.first;

    if (response is String) {
      return response;
    } else {
      throw Exception('Failed to encode file in isolate.');
    }
  }

  /// Isolate Function
  static void _isolateEncode(List<dynamic> args) {
    final filePath = args[0] as String;
    final sendPort = args[1] as SendPort;

    try {
      // Perform the encoding synchronously within the isolate
      final file = File(filePath);
      final bytes = file.readAsBytesSync();
      final base64String = base64Encode(bytes);

      // Send the Base64 string result back
      sendPort.send(base64String);
    } catch (e) {
      sendPort.send('Error: $e');
    }
  }

  Future<void> _openCamera() async {
    final file = await Navigator.of(context).push<XFile?>(
      MaterialPageRoute(
        builder: (context) {
          return const _CameraScreen();
        },
      ),
    );

    if (file != null) {
      setState(() {
        _file = file;
      });
    }
  }
}

class _CameraScreen extends StatefulWidget {
  const _CameraScreen();

  @override
  State<_CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<_CameraScreen>
    with WidgetsBindingObserver {
  bool isRecording = false;

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
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    _controller = null;
    availableCameras().then((cameras) {
      _controller = CameraController(cameras[0], ResolutionPreset.max);
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
    final photoButton = SizedBox(
      width: 120,
      height: 120,
      child: ElevatedButton(
        style: const ButtonStyle(shape: WidgetStatePropertyAll(CircleBorder())),
        onPressed: () async {
          setState(() {
            _isLoading = true;
          });
          file = await _controller!.takePicture();
          await _buildPreviewAndAskIfDone();
        },
        child: const Text(
          'Take Picture',
          textAlign: TextAlign.center,
        ),
      ),
    );

    final videoButton = SizedBox(
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
            setState(() {
              _isLoading = true;
            });
            file = await _controller!.stopVideoRecording();

            await _buildPreviewAndAskIfDone();
          } else {
            await _controller!.startVideoRecording();
          }
          isRecording = !isRecording;
          setState(() {});
        },
        child: Text(
          isRecording ? 'Stop' : 'Record',
          textAlign: TextAlign.center,
        ),
      ),
    );

    return Scaffold(
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                CameraPreview(_controller!),
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
                      photoButton,
                      const SizedBox(width: 10),
                      videoButton,
                    ],
                  ),
                ),
              ],
            ),
    );
  }

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

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
}
