import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:jsonschema_form/src/utils/file_type.dart';
import 'package:path/path.dart' as path;


/// Extension for useful non built-in methods for XFile
extension XFileExtension on XFile {
  /// Rename a file by returning a new [XFile] class.
  /// Only supported on non web platforms
  Future<XFile> rename(String newFileName) async {
    final directory = path.dirname(this.path);

    final newPath = path.join(directory, newFileName);

    final newFile = await File(this.path).copy(newPath);

    return XFile(newFile.path);
  }

  /// Converts a file into a base64 encoded string, prefixed with the necessary
  /// MIME type and file name.
  ///
  /// The method determines the platform being used (web or non-web) and
  /// utilizes different encoding methods for each.
  /// On web, it uses `_encodeFileForWeb`, and on non-web (i.e., mobile),
  /// it uses `_encodeFileInIsolate` to encode the file.
  /// The resulting base64 string is then prefixed with the MIME type and
  /// file name to match the format of a data URI.
  ///
  /// **Returns**:
  /// A base64-encoded string, prefixed with the data URI scheme
  /// (`data:mimeType;base64,`), or `null` if encoding fails.
  ///
  /// **Platform-specific behavior**:
  /// - **Web**: Uses `_encodeFileForWeb` to handle file encoding
  /// in a browser environment.
  /// - **Non-Web**: Uses `_encodeFileInIsolate` to handle file encoding
  /// in isolates (for mobile platforms).
  ///
  /// **Example**:
  /// ```dart
  /// final base64String = await file.getBase64();
  /// ```
  ///
  /// If `mimeType` is `image/png` and the file is named `image.png`, the returned string might look like:
  /// ```dart
  /// 'data:image/png;name=image.png;base64,....'
  /// ```
  Future<String?> getBase64() async {
    final fileData = kIsWeb
        ? await _encodeFileForWeb(
            this,
          )
        : await _encodeFileInIsolate(
            this.path,
          );

    final fileExtension = name.split('.').last.toLowerCase();
    final fileType = fileTypeMap[fileExtension];

    final base64 = 'data:$fileType;base64,$fileData';
    return base64;
  }

  /// Determines the type of file based on its MIME type.
  ///
  /// This getter checks the MIME type of the file and returns the appropriate
  /// `FileType` (either `image`, `video`, or `unknown`). It is useful for
  /// categorizing the file to handle it properly (e.g.,
  /// for previewing or processing).
  ///
  /// The MIME types are matched with known types for images and videos. If the
  /// MIME type doesn't match any of the known types,
  /// it defaults to `FileType.unknown`.
  ///
  /// Example:
  /// - For `image/png`, it will return `FileType.image`.
  /// - For `video/mp4`, it will return `FileType.video`.
  /// - For unknown MIME types, it will return `FileType.unknown`.
  FileType get fileType {
    // FileType
    switch (mimeType) {
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

  /// Retrieves an updated `XFile` with the file's details,
  /// including bytes, length, last modified date, and MIME type.
  ///
  /// This method reads the file's bytes, length, and last modified timestamp,
  /// and constructs an updated `XFile` object with the current
  /// file's information.
  /// It also determines the file's MIME type based on
  /// its extension using the `fileTypeMap`.
  /// If the MIME type cannot be determined from the extension,
  /// the method falls back to using
  /// the extension as the MIME type.
  ///
  /// This method is useful for updating file details when they change or
  /// when new file information is needed
  /// (e.g., for uploading, previewing, etc.).
  ///
  /// Returns an updated `XFile` object with the following details:
  /// - `bytes`: The raw byte data of the file.
  /// - `length`: The length of the file in bytes.
  /// - `lastModified`: The last modified timestamp of the file.
  /// - `mimeType`: The MIME type determined from the file extension
  /// or `fileTypeMap`.
  ///
  /// Example usage:
  /// ```dart
  /// XFile updatedFile = await getUpdatedFile();
  /// ```
  Future<XFile> getUpdatedFile() async {
    final bytes = await readAsBytes();
    final length = await this.length();
    final lastModified = await this.lastModified();
    final fileExtension = name.split('.').last.toLowerCase();
    return XFile(
      this.path,
      mimeType: fileTypeMap[fileExtension] ?? fileExtension,
      name: name,
      length: length,
      bytes: bytes,
      lastModified: lastModified,
    );
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
