/// Extension for useful non built-in methods for Map<String, dyamic>
extension MapExtension on Map<String, dynamic> {
  /// Checks if a map and all its submaps are empty
  Map<String, dynamic> removeEmptySubmaps({Map<String, dynamic>? map}) {
    final cleanedMap = <String, dynamic>{};

    (map ?? this).forEach((String key, dynamic value) {
      if (value is Map<String, dynamic>) {
        final cleanedSubmap = removeEmptySubmaps(map: value);

        if (cleanedSubmap.isNotEmpty) {
          cleanedMap[key] = cleanedSubmap;
        }
      } else {
        cleanedMap[key] = value;
      }
    });

    return cleanedMap;
  }
}
