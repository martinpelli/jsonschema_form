/// Affect the quality of video recording and image capture:
///
/// A preset is treated as a target resolution, and exact values are not
/// guaranteed. Platform implementations may fall back to a higher or lower
/// resolution if a specific preset is not available.
enum CameraResolution {
  /// 352x288 on iOS, ~240p on Android and Web
  low,

  /// ~480p
  medium,

  /// ~720p
  high,

  /// ~1080p
  veryHigh,

  /// ~2160p
  ultraHigh,

  /// The highest resolution available.
  max,
}

extension CameraStringExt on String? {
// Function to map the string to CameraResolution
  CameraResolution? get cameraResolution {
    // Try to match the string with an enum value
    final value = this?.toLowerCase() ?? '';

    switch (value) {
      case 'low':
        return CameraResolution.low;
      case 'medium':
        return CameraResolution.medium;
      case 'high':
        return CameraResolution.high;
      case 'veryhigh':
        return CameraResolution.veryHigh;
      case 'ultrahigh':
        return CameraResolution.ultraHigh;
      case 'max':
        return CameraResolution.max;
      default:
        return null; // Return null if no matching enum found
    }
  }
}
