import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:jsonschema_form/src/utils/file_type.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

const Map<String, String> fileTypeMap = {
  'png': 'image/png',
  'jpeg': 'image/jpeg',
  'jpg': 'image/jpeg',
  'gif': 'image/gif',
  'svg': 'image/svg+xml',
  'bmp': 'image/bmp',
  'webp': 'image/webp',
  'tiff': 'image/tiff',
  'ico': 'image/x-icon',
  'heif': 'image/heif',
  'heic': 'image/heic',
  'avif': 'image/avif',

  // Video files
  'mp4': 'video/mp4',
  'webm': 'video/webm',
  'ogg': 'video/ogg',
  'avi': 'video/avi',
  'mov': 'video/quicktime',
  'mkv': 'video/x-matroska',
  '3gp': 'video/3gpp',
  'flv': 'video/x-flv',
};

/// Extension on [String] to provide a method to check if the string
/// is a valid base64 encoded string.
extension StringExt on String {
  /// Checks whether the string is a valid base64 encoded string.
  ///
  /// This method attempts to decode the string after removing any `data:image/*;base64,`
  /// prefix. If the string can be decoded successfully,
  /// it is considered a valid base64 string.
  ///
  /// Returns `true` if the string is valid base64, otherwise `false`.
  bool isBase64() {
    try {
      // Remove the data URI scheme if it exists (e.g., 'data:image/png;base64,')
      final cleanBase64String = replaceAll(RegExp('^data.*base64,'), '');

      // Attempt to decode the cleaned base64 string
      base64Decode(cleanBase64String);
      return true;
    } catch (e) {
      // If decoding fails, it's not valid base64
      return false;
    }
  }

  /// Converts a base64-encoded string into an `XFile`.
  ///
  /// This method decodes the base64 string, writes the resulting byte data
  /// to a temporary file, and returns an `XFile` pointing to that file.
  /// The temporary file is stored in the system's temporary directory and
  /// is named with a unique timestamp. The method assumes the base64 string
  /// represents a valid binary file (e.g., an image).
  ///
  /// Returns a `Future<XFile>`, which resolves to an `XFile` containing
  /// the path to the generated temporary file.
  XFile? base64ToXFile() {
    try {
      // Remove the data URI scheme if it exists (e.g., 'data:image/png;base64,')
      final cleanBase64String = replaceAll(RegExp('^data.*base64,'), '');

      // Decode the base64 string into bytes
      final bytes = base64Decode(cleanBase64String);

      // Use the mime package to get the MIME type from the raw bytes
      var mimeType = lookupMimeType('', headerBytes: bytes);
      if (mimeType == null) {
        final regex = RegExp('(?<=data:)(.*?)(?=;base64)');
        final match = regex.firstMatch(this);
        if (match != null) {
          mimeType = match.group(0);
        }
      }
      // Return the file
      final file = XFile.fromData(
        bytes,
        mimeType: mimeType,
      );
      return file;
    } catch (e) {
      return null;
    }
  }

  // Check if the string is a valid URL
  bool get isValidUrl {
    final urlRegex = RegExp(
      r'^(http|https):\/\/[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-]+.*$',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(this);
  }

  // Check if the URL is an image
  FileType get fileType {
    final uri = Uri.parse(this);

    // Extract the path from the URL and get the file name with its extension
    final fileNameWithExtension = p.basename(uri.path);
    final fileExtension = fileNameWithExtension.split('.').last.toLowerCase();

    switch (fileExtension) {
      case 'png':
      case 'jpeg':
      case 'jpg':
      case 'gif':
      case 'svg':
      case 'bmp':
      case 'webp':
      case 'tiff':
      case 'ico':
      case 'heif':
      case 'heic':
      case 'avif':
      case 'image/png':
      case 'image/jpeg':
      case 'image/gif':
      case 'image/svg+xml':
      case 'image/bmp':
      case 'image/webp':
      case 'image/tiff':
      case 'image/x-icon':
      case 'image/heif':
      case 'image/heic':
      case 'image/avif':
        return FileType.image;
      // Video files
      case 'mp4':
      case 'webm':
      case 'ogg':
      case 'avi':
      case 'mov':
      case 'mkv':
      case '3gp':
      case 'flv':
      case 'video/mp4':
      case 'video/webm':
      case 'video/ogg':
      case 'video/avi':
      case 'video/quicktime':
      case 'video/x-matroska':
      case 'video/3gpp':
      case 'video/x-flv':
        return FileType.video;
      default:
        return FileType.unknown;
    }
  }

  Future<XFile?> urlMediaToFile() async {
    final response = await http.get(Uri.parse(this));

    if (response.statusCode == 200) {
      // On web, we return an XFile with the byte data
      final bytes = response.bodyBytes;

      // Use the mime package to get the MIME type from the raw bytes
      final mimeType = lookupMimeType('', headerBytes: bytes);

      // Create and return an XFile from the Blob URL
      return XFile.fromData(
        bytes,
        mimeType: mimeType,
        name: DateTime.timestamp().microsecondsSinceEpoch.toString(),
      );
    } else {
      return null;
    }
  }
}
