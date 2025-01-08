import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
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
    final encodedFile = kIsWeb
        ? await _encodeFileForWeb(
            this,
          )
        : await _encodeFileInIsolate(
            this.path,
          );

    return 'data:$mimeType;name=$name;base64,$encodedFile';
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
