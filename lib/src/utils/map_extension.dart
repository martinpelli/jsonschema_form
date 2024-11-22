import 'package:jsonschema_form/src/utils/dynamic_utils.dart';

/// Extension for useful non built-in methods for Map<String, dyamic>
extension MapExtension on Map<String, dynamic> {
  /// Checks if a map and all its submaps are empty
  Map<String, dynamic> removeEmptySubmaps({Map<String, dynamic>? map}) {
    final cleanedMap = <String, dynamic>{};

    (map ?? this).forEach((String key, dynamic value) {
      final castedListOfMaps = DynamicUtils.tryParseListOfMaps(value);

      if (value is Map<String, dynamic>) {
        final cleanedSubmap = removeEmptySubmaps(map: value);

        if (cleanedSubmap.isNotEmpty) {
          cleanedMap[key] = cleanedSubmap;
        }
      } else if (castedListOfMaps != null) {
        if (castedListOfMaps.isEmpty) {
          cleanedMap[key] = castedListOfMaps;
        } else {
          for (var i = 0; i < castedListOfMaps.length; i++) {
            final cleanedSubmap = removeEmptySubmaps(map: castedListOfMaps[i]);

            if (castedListOfMaps[i].isNotEmpty) {
              if (cleanedMap[key] == null) {
                cleanedMap[key] = [cleanedSubmap];
              } else {
                (cleanedMap[key] as List<Map<String, dynamic>>)
                    .add(cleanedSubmap);
              }
            }
          }
        }
      } else {
        cleanedMap[key] = value;
      }
    });

    return cleanedMap;
  }
}
