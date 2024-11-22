import 'package:json_annotation/json_annotation.dart';

/// This enum defines possible values for the format property in jsonSchema
enum JsonSchemaFormat {
  /// Enables file upload
  @JsonValue('data-url')
  dataUrl;
}
