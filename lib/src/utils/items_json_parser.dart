import 'package:jsonschema_form/src/models/json_schema.dart';

/// This is a util used to parse items property from JsonSchema
/// The type will vary depending on JsonSchema additionalItems property
class ItemsJsonParser {
  /// Parse items property from JsonSchema model
  static dynamic fromJson(dynamic json) {
    if (json is List) {
      return List<JsonSchema>.from(
        json.map((item) => JsonSchema.fromJson(item as Map<String, dynamic>)),
      ).toList();
    } else if (json is Map<String, dynamic>) {
      return JsonSchema.fromJson(json);
    }
  }
}
