import 'package:json_annotation/json_annotation.dart';

import 'package:jsonschema_form/src/models/json_schema.dart';

/// This is a util used to parse items property from JsonSchema
/// The type will vary depending on JsonSchema additionalItems property
class ItemsJsonParser implements JsonConverter<dynamic, dynamic> {
  /// {@macro items_json_parser}
  const ItemsJsonParser();

  @override
  dynamic fromJson(dynamic json) {
    if (json is List) {
      return List<JsonSchema>.from(
        json.map((item) => JsonSchema.fromJson(item as Map<String, dynamic>)),
      ).toList();
    } else if (json is Map<String, dynamic>) {
      return JsonSchema.fromJson(json);
    }
  }

  @override
  Map<String, dynamic> toJson(dynamic date) {
    throw UnimplementedError();
  }
}
