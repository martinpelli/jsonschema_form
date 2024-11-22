import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:jsonschema_form/src/models/json_map.dart';
import 'package:jsonschema_form/src/models/json_schema_format.dart';
import 'package:jsonschema_form/src/models/json_type.dart';
import 'package:jsonschema_form/src/utils/dependencies_json_parser.dart';
import 'package:jsonschema_form/src/utils/items_json_parser.dart';

part 'json_schema.g.dart';

/// {@template json_schema}
/// A single `json_schema` item.
///
/// Contains a [title], [type], [properties], [enumValue], [constValue] and
/// [dependencies]
///
/// [JsonSchema]s are immutable, they can
/// being deserialized using [fromJson]
/// respectively.
/// {@endtemplate}
@immutable
@DependenciesJsonParser()
@JsonSerializable(createToJson: false)
class JsonSchema extends Equatable {
  /// {@macro json_schema}
  const JsonSchema({
    required this.title,
    required this.description,
    required this.defaultValue,
    required this.type,
    required this.requiredFields,
    required this.properties,
    required this.enumValue,
    required this.constValue,
    required this.dependencies,
    required this.items,
    required this.additionalItems,
    required this.minItems,
    required this.maxItems,
    required this.uniqueItems,
    required this.oneOf,
    required this.format,
  });

  /// A human-readable name or label for a particular schema or field.
  /// It’s often displayed as the label or header when generating forms based
  /// on the schema. Can be empty.
  final String? title;

  /// [description] is shown above each field if is not null, providing
  /// neccessary information if needed
  final String? description;

  @JsonKey(name: 'default')

  /// [default] is the default value that this field takes. If there is data
  /// present on the corresponding formData property then [default] is ignored
  final dynamic defaultValue;

  /// Defines the data type of a field or schema element.
  /// Possible types include "string", "number", "boolean", "array", and
  /// "object"
  /// It tells the UI what kind of input widget needs to be rendered
  final JsonType? type;

  @JsonKey(name: 'required')

  /// A list of required fields, is composed by the key properties
  /// that corresponds to the jsonSchema
  final List<String>? requiredFields;

  /// When type is "object", properties is used to define the schema for each of
  /// the fields within that object.
  /// Each key in properties represents a field in the form, and the value is
  /// the schema for that field.
  final Map<String, JsonSchema>? properties;

  @JsonKey(name: 'enum')

  /// Allows to specify a fixed set of acceptable values for a field,
  /// effectively creating a dropdown or selection list in form-based UIs.
  /// It’s used to restrict the possible values for a field.
  final List<String>? enumValue;

  @JsonKey(name: 'const')

  /// Used to specify that a field must have a single specific value.
  /// It’s useful when a field needs a fixed value.
  final String? constValue;

  /// Allows to define conditional logic within the schema, where certain
  /// fields are required or change their validation based on the presence or
  /// value of another field.
  /// Dependencies can work in two ways:
  /// Schema dependencies: Where certain fields are only required or validated
  /// if another field exists.
  /// Property dependencies: Where certain fields are only required if another
  /// field has a specific value.
  final Map<String, dynamic>? dependencies;

  @JsonKey(fromJson: ItemsJsonParser.fromJson)

  /// Items is only present when [type] is equal to array
  /// The form generated will have fields that allow users to enter multiple
  /// entries, essentially creating a dynamic list of inputs.
  /// If [additionalItems] is null then the type of [items] will be JsonSchema
  /// If [additionalItems] is not null then the type if [items] will be Array
  final dynamic items;

  /// When [additionalItems] is not null, then [items] will be an array of
  /// items. Form will show those items by default and pressing add button will
  /// show [additionalItems]
  final JsonSchema? additionalItems;

  /// If the array needs to be populated, you can specify the minimum number of
  /// items using this property
  final int? minItems;

  /// If the array needs to be populated, you can specify the maximum number of
  /// items using this property
  final int? maxItems;

  /// When is set to true, all items from the array follows the same schema
  final bool? uniqueItems;

  /// A way to define conditional schemas where only one of multiple schemas
  /// must be valid, depending on specific conditions.
  /// When dependencies is used with oneOf, it enables conditional logic based
  /// on the fields in the JSON data, allowing the schema to adapt according to
  /// certain field value
  final List<JsonSchema>? oneOf;

  /// Pass data-url in [format] property to enable file upload
  final JsonSchemaFormat? format;

  /// Deserializes the given [JsonMap] into a [JsonSchema].
  static JsonSchema fromJson(JsonMap json) => _$JsonSchemaFromJson(json);

  @override
  List<Object?> get props => [
        title,
        type,
        properties,
        enumValue,
        constValue,
        dependencies,
      ];
}
