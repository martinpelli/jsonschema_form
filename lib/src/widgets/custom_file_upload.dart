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
    this.resolution,
  });

  final bool hasFilePicker;
  final bool hasCameraButton;
  final bool isPhotoAllowed;
  final bool isVideoAllowed;
  final List<String>? acceptedExtensions;
  final String? title;
  final void Function(String? value) onFileChosen;
  final bool readOnly;
  final String? fileData;
  final String? resolution;

  @override
  State<_CustomFileUpload> createState() => _CustomFileUploadState();
}

class _CustomFileUploadState extends State<_CustomFileUpload>
    with WidgetsBindingObserver {
  String? _file;
  String? _fileName;

  bool _isLoading = false;

  @override
  void initState() {
    _file = widget.fileData;
    _fileName = null;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _CustomFileUpload oldWidget) {
    _file = widget.fileData;
    _fileName = null;

    super.didUpdateWidget(oldWidget);
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
              FilePreview(
                fileData: _file!,
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: widget.readOnly
                    ? null
                    : () {
                        _file = null;
                        widget.onFileChosen(null);
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
              else if (_file != null)
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
                            },
                      icon: const Icon(Icons.delete),
                    ),
                  ],
                )
              else if (widget.hasFilePicker)
                const Text('No file chosen'),
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
      final base64 = await selectedFile.getBase64();
      if (mounted) setState(() => _isLoading = true);

      try {
        if (mounted) {
          _file = base64;
          _fileName = selectedFile.name;
        }
        widget.onFileChosen(base64);
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
          final mediaTypes = <CameraMediaType>[];
          if (widget.isPhotoAllowed) {
            mediaTypes.add(CameraMediaType.photo);
          }
          if (widget.isVideoAllowed) {
            mediaTypes.add(CameraMediaType.video);
          }
          return CameraScreen(
            mediaTypes: mediaTypes,
            resolution: widget.resolution.cameraResolution,
          );
        },
      ),
    );

    if (file != null) {
      final base64 = await file.getBase64();

      _file = base64;
      _fileName =
          file.name.isEmpty ? DateTime.now().toIso8601String() : file.name;

      widget.onFileChosen(base64);
    }
  }
}
