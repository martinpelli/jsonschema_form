/// A map that associates file extensions with their corresponding MIME types.
///
/// This map is used to map common file extensions (e.g., 'png', 'mp4') to their
/// appropriate MIME type (e.g., 'image/png', 'video/mp4') for handling and processing
/// of files based on their type.
///
/// The map contains both image and video file types,
///  as well as other multimedia file formats.
///
/// Example:
/// - 'png' -> 'image/png'
/// - 'mp4' -> 'video/mp4'
/// - 'jpeg' -> 'image/jpeg'
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

/// Enum to represent the type of a file.
///
/// This enum is used to categorize files based on their type. It helps in
/// determining the appropriate handling or processing of the file (e.g.,
/// showing a preview, playing video, etc.).
enum FileType {
  /// Represents an image file type.
  ///
  /// This type is used for files that are images, such as PNG, JPEG, GIF, etc.
  image,

  /// Represents a video file type.
  ///
  /// This type is used for files that are videos, such as MP4, AVI, MOV, etc.
  video,

  /// Represents an unknown or unsupported file type.
  ///
  /// This type is used for files whose type is not recognized or is unsupported
  /// for previewing or processing.
  unknown,
}
