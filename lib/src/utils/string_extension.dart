import 'dart:convert';

import 'package:file_selector/file_selector.dart';

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
  XFile? base64ToXFile()  {
    try {
      // Remove the data URI scheme if it exists (e.g., 'data:image/png;base64,')
      final cleanBase64String = replaceAll(RegExp('^data.*base64,'), '');

      // Decode the base64 string into bytes
      final bytes = base64Decode(cleanBase64String);
      // Return the file
      return XFile.fromData(bytes);
    } catch (e) {
      return null;
    }
  }
}
