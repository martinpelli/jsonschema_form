import 'package:json_annotation/json_annotation.dart';
import 'package:jsonschema_form/src/models/json_schema.dart';

/// Converter to parse the `dependencies` property from a JsonSchema.
class DependenciesJsonParser
    implements JsonConverter<Map<String, dynamic>?, dynamic> {
  /// {@macro dependencies_json_parser}
  const DependenciesJsonParser();

  @override
  Map<String, dynamic>? fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return json.map(
        (key, value) {
          if (value is List) {
            return MapEntry(key, List<String>.from(value));
          } else if (value is Map<String, dynamic>) {
            return MapEntry(key, JsonSchema.fromJson(value));
          } else {
            throw const FormatException(
                'Unexpected value type in dependencies');
          }
        },
      );
    }
    return null;
  }

  @override
  Map<String, dynamic> toJson(dynamic data) {
    throw UnimplementedError();
  }
}
