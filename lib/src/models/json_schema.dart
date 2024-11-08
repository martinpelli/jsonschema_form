import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:jsonschema_form/src/models/json_dependency.dart';
import 'package:jsonschema_form/src/models/json_map.dart';
import 'package:jsonschema_form/src/models/json_type.dart';
import 'package:meta/meta.dart';

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
@JsonSerializable(createToJson: false)
class JsonSchema extends Equatable {
  /// {@macro json_schema}
  const JsonSchema({
    required this.title,
    required this.type,
    required this.properties,
    required this.enumValue,
    required this.constValue,
    required this.dependencies,
  });

  /// A human-readable name or label for a particular schema or field.
  /// It’s often displayed as the label or header when generating forms based
  /// on the schema. Can be empty.
  final String? title;

  /// Defines the data type of a field or schema element.
  /// Possible types include "string", "number", "boolean", "array", and
  /// "object"
  /// It tells the UI what kind of input widget needs to be rendered
  final JsonType? type;

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
  final Map<String, JsonDependency>? dependencies;

  //TODO define items property which is used when the type is array

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
