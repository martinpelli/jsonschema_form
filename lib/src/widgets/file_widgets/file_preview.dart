import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jsonschema_form/src/utils/file_type.dart';
import 'package:jsonschema_form/src/utils/string_extension.dart';
import 'package:jsonschema_form/src/utils/xfile_extension.dart';
import 'package:jsonschema_form/src/widgets/file_widgets/app_image.dart';
import 'package:jsonschema_form/src/widgets/file_widgets/media_player_view.dart';
import 'package:jsonschema_form/src/widgets/file_widgets/unsupported_file_preview.dart';
import 'package:jsonschema_form/src/widgets/file_widgets/video_thumbnail_preview.dart';

/// A widget that displays a preview of a file based on its type
/// (image, video, or unknown).
///
/// If the string [fileData] is a URL or a base64-encoded file,
/// it will display the corresponding preview for image or video.
/// If the file type is unknown, it displays a fallback
/// "Preview Not Available" message.
class FilePreview extends StatelessWidget {
  /// Creates a new [FilePreview] widget.
  ///
  /// Takes a required [fileData] of type [String] which represents
  /// the file URL or base64-encoded data.
  const FilePreview({
    required this.fileData,
    super.key,
  });

  /// The [String] to be previewed. Can be a URL or base64-encoded data.
  final String fileData;

  @override
  Widget build(BuildContext context) {
    // Check if the string is a base64 string or a URL
    if (fileData.isBase64()) {
      // Check if it's base64 encoded (assumes it's an image or video)
      final file = fileData.base64ToXFile();
      final path = file?.path ?? '';
      switch (file?.fileType) {
        case FileType.image:
          return GestureDetector(
            onTap: () {
              _showFullScreenMedia(
                context,
                FileType.image,
                path,
              );
            },
            child: AppImage(
              imageData: path,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          );
        case FileType.video:
          return GestureDetector(
            onTap: () {
              _showFullScreenMedia(
                context,
                FileType.video,
                path,
              );
            },
            child: VideoThumbnailPreview(path: path),
          );
        // ignore: no_default_cases
        default:
          return const UnsupportedFilePreview();
      }
    } else if (fileData.isValidUrl) {
      switch (fileData.fileType) {
        case FileType.image:
          return GestureDetector(
            onTap: () {
              _showFullScreenMedia(
                context,
                FileType.image,
                fileData,
              );
            },
            child: AppImage(
              imageData: fileData,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          );
        case FileType.video:
          return GestureDetector(
            onTap: () {
              _showFullScreenMedia(
                context,
                FileType.video,
                fileData,
              );
            },
            child: VideoThumbnailPreview(path: fileData),
          );
        // ignore: no_default_cases
        default:
          return const UnsupportedFilePreview();
      }
    } else {
      // Unknown file type (not a valid URL or base64)
      return const UnsupportedFilePreview();
    }
  }

  // Show the image or video in full size using a dialog
  Future<void> _showFullScreenMedia(
    BuildContext context,
    FileType type,
    String path,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero, // Optional, to remove padding
          child: _buildFullScreenMedia(
            context,
            type,
            path,
          ),
        );
      },
    );
  }

  // Full-screen display for image or video
  Widget _buildFullScreenMedia(
    BuildContext context,
    FileType type,
    String path,
  ) {
    switch (type) {
      case FileType.image:
        return AppImage(
          imageData: path,
          fit: BoxFit.contain,
        );
      case FileType.video:
        return MediaPlayerView(
          path: path,
        );
      case FileType.unknown:
        return const Center(child: Text('Unsupported file type'));
    }
  }
}
