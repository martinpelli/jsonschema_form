part of '../jsonschema_form_builder.dart';

class _CustomFileUpload extends StatefulWidget {
  const _CustomFileUpload({
    required this.hasFilePicker,
    required this.hasCameraButton,
    required this.isPhotoAllowed,
    required this.isVideoAllowed,
    required this.acceptedExtensions,
    required this.title,
    required this.onFileChosen,
  });

  final bool hasFilePicker;
  final bool hasCameraButton;
  final bool isPhotoAllowed;
  final bool isVideoAllowed;
  final List<String>? acceptedExtensions;
  final String? title;
  final void Function(String value) onFileChosen;

  @override
  State<_CustomFileUpload> createState() => _CustomFileUploadState();
}

class _CustomFileUploadState extends State<_CustomFileUpload>
    with WidgetsBindingObserver {
  XFile? _file;
  late String? _fileName;

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
                child: Text(_getCameraButtonText()),
              ),
              const SizedBox(width: 20),
            ],
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_file == null)
              const Text('No file chosen')
            else
              Row(
                children: [
                  Text(_fileName!),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {
                      _file = null;
                      widget.onFileChosen('');
                      setState(() {});
                    },
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  String _getCameraButtonText() {
    if (widget.isPhotoAllowed && widget.isVideoAllowed) {
      return 'Take Photo/Video';
    } else if (widget.isVideoAllowed) {
      return 'Take Video';
    } else {
      return 'Take Photo';
    }
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
          _fileName = _file!.name;
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

  Future<void> _openCamera() async {
    final file = await Navigator.of(context).push<XFile?>(
      MaterialPageRoute(
        builder: (context) {
          return _CameraScreen(
            isPhotoAllowed: widget.isPhotoAllowed,
            isVideoAllowed: widget.isVideoAllowed,
          );
        },
      ),
    );

    if (file != null) {
      final encodedFile = kIsWeb
          ? await _encodeFileForWeb(file)
          : await _encodeFileInIsolate(file.path);

      widget.onFileChosen(
        // ignore: lines_longer_than_80_chars
        'data:${file.mimeType};name=${file.name};base64,$encodedFile',
      );

      setState(() {
        _file = file;
        _fileName = _file!.name.isEmpty
            ? DateTime.now().toIso8601String()
            : _file!.name;
      });
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
}
