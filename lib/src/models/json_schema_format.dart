import 'package:json_annotation/json_annotation.dart';

/// This enum defines possible values for the format property in jsonSchema
enum JsonSchemaFormat {
  /// Enables file upload
  @JsonValue('data-url')
  dataUrl,

  /// When is provided to an input it will have an email regex validator as long
  /// as the corresponding keyboard
  email,
}
