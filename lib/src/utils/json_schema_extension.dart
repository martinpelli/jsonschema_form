import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/json_type.dart';

/// Extension for useful JsonSchema methdos
extension JsonSchemaExtension on JsonSchema {
  /// Checks if the current [JsonSchema] is an array and if it is, checks if
  /// the items are non objects of type map {}
  bool areItemsNonObjects() {
    if (items == null) {
      return false;
    }

    if (items is List) {
      return true;
    }

    if (items is JsonSchema && (items as JsonSchema).type != JsonType.object) {
      return true;
    }

    return false;
  }
}
