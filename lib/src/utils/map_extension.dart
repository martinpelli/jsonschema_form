import 'package:collection/collection.dart';
import 'package:jsonschema_form/src/utils/dynamic_utils.dart';

/// Extension for useful non built-in methods for Map<String, dyamic>
extension MapExtension on Map<String, dynamic> {
  /// Checks and removes every empty map
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

  /// Checks if every value of the map is from the type specified.
  /// This is necessary in some scenarios where doing
  /// [something is Map<String, T>] is no tvalid as it can lead to false when
  /// something is just a Map without type
  bool isMapOfStringAndType<T>() {
    return values.every((value) => value is T);
  }

  /// Checks if a map (and every submap) of type Map<String, dynamic> is equal
  /// to a nother one of same type.
  /// This method can be used to check for example, if two formData are the same
  bool isEqualToMap(Map<String, dynamic> map) {
    const deepEquality = DeepCollectionEquality();
    return deepEquality.equals(this, map);
  }

  /// .from is only applied to the map or list but not to submaps nor sublist.
  /// Therefore, deepCopy supports deep .from
  Map<String, dynamic> deepCopy({Map<String, dynamic>? copiedMap}) {
    return (copiedMap ?? this).map((key, value) {
      if (value is Map<String, dynamic>) {
        return MapEntry(key, deepCopy(copiedMap: value));
      } else if (value is List) {
        return MapEntry(
          key,
          value.map((item) {
            if (item is Map<String, dynamic>) {
              return deepCopy(
                copiedMap: item,
              );
            }
            return item;
          }).toList(),
        );
      } else {
        return MapEntry(key, value);
      }
    });
  }
}
