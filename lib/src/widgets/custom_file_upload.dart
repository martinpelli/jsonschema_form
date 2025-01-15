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
    required this.readOnly,
    this.fileData,
  });

  final bool hasFilePicker;
  final bool hasCameraButton;
  final bool isPhotoAllowed;
  final bool isVideoAllowed;
  final List<String>? acceptedExtensions;
  final String? title;
  final void Function(XFile? value) onFileChosen;
  final bool readOnly;
  final XFile? fileData;

  @override
  State<_CustomFileUpload> createState() => _CustomFileUploadState();
}

class _CustomFileUploadState extends State<_CustomFileUpload> with WidgetsBindingObserver {
  XFile? _file;
  late String? _fileName;

  bool _isLoading = false;

  @override
  void initState() {
    _file = widget.fileData;
    super.initState();
  }

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
        if (_file != null)
          Row(
            children: [
              AppImage(
                imageData: _file!.path,
                width: 200,
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: widget.readOnly
                    ? null
                    : () {
                        _file = null;
                        widget.onFileChosen(null);
                        setState(() {});
                      },
                icon: const Icon(Icons.delete),
              ),
            ],
          )
        else
          Row(
            children: [
              if (widget.hasFilePicker) ...[
                ElevatedButton(
                  onPressed: widget.readOnly ? null : _openSingleFile,
                  child: const Text('Choose File'),
                ),
                const SizedBox(width: 20),
              ],
              if (widget.hasCameraButton) ...[
                ElevatedButton(
                  onPressed: widget.readOnly ? null : _openCamera,
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
                      onPressed: widget.readOnly
                          ? null
                          : () {
                              _file = null;
                              widget.onFileChosen(null);
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
      if (mounted) setState(() => _isLoading = true);

      try {
        widget.onFileChosen(
          // ignore: lines_longer_than_80_chars
          selectedFile,
        );

        if (mounted) {
          setState(() {
            _file = selectedFile;
            _fileName = _file!.name;
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error during file encoding: $e');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
      widget.onFileChosen(
        // ignore: lines_longer_than_80_chars
        file,
      );

      setState(() {
        _file = file;
        _fileName = _file!.name.isEmpty ? DateTime.now().toIso8601String() : _file!.name;
      });
    }
  }

  @protected
  @mustCallSuper
  void dispose() {
    print('dispose $runtimeType');
    super.dispose();
  }
}
