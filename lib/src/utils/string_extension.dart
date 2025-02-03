import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:http/http.dart' as http;
import 'package:jsonschema_form/src/utils/file_type.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

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
      // Check if input matches the pattern for a Base64 string
      final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');

      // Remove data URI prefix if it exists
      final cleanBase64String = replaceAll(RegExp('^data.*base64,'), '');

      // Validate the cleaned string against the Base64 pattern
      if (!base64Pattern.hasMatch(cleanBase64String)) {
        return false;
      }

      // Attempt to decode the Base64 string
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

  /// Returns `true` if the string is a valid URL with
  /// an `http` or `https` scheme.
  ///
  /// This is a simple check using a regular expression to verify that 
  /// the string starts with `http://` or `https://`,
  /// followed by a domain and other URL components.
  ///
  /// Example:
  /// ```dart
  /// 'https://example.com'.isValidUrl; // Returns true
  /// 'invalid-url'.isValidUrl; // Returns false
  /// ```
  bool get isValidUrl {
    final urlRegex = RegExp(
      r'^(http|https):\/\/[a-zA-Z0-9\-]+\.[a-zA-Z0-9\-]+.*$',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(this);
  }

  /// Determines the type of media from the URL's file extension.
  ///
  /// This method checks the file extension of the URL and classifies
  /// it into one of the following categories:
  /// - `FileType.image` for image files (e.g., PNG, JPEG, GIF)
  /// - `FileType.video` for video files (e.g., MP4, AVI, MKV)
  /// - `FileType.unknown` for unsupported or unknown file types.
  ///
  /// The method compares the file extension or MIME type in the URL 
  /// to known image and video formats to return the correct `FileType`.
  ///
  /// Example:
  /// ```dart
  /// 'https://example.com/image.jpg'.fileType; // Returns FileType.image
  /// 'https://example.com/video.mp4'.fileType; // Returns FileType.video
  /// 'https://example.com/file.txt'.fileType; // Returns FileType.unknown
  /// ```
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

/// Fetches the media from the URL and returns an `XFile` with the media data.
  ///
  /// This method performs an HTTP GET request to the provided URL,
  /// retrieves the media file (such as an image or video), and returns
  /// an `XFile` containing the raw byte data and MIME type of the file.
  ///
  /// The file is saved with a generated name based on the current timestamp.
  ///
  /// Returns `null` if the URL cannot be reached or the request fails.
  ///
  /// Example:
  /// ```dart
  /// final mediaFile = await 'https://example.com/image.png'.urlMediaToFile();
  /// if (mediaFile != null) {
  ///   // Handle the file (e.g., save it, display it)
  /// }
  /// ```
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
