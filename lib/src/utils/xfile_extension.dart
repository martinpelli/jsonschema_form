import 'dart:io';
import 'package:camera/camera.dart';
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
}
