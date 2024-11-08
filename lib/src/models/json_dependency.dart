import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:jsonschema_form/src/models/json_map.dart';
import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:meta/meta.dart';

part 'json_dependency.g.dart';

/// {@template json_dependency}
/// A single `json_dependency` item.
///
/// Contains a [oneOf]
///
/// [JsonDependency]s are immutable, they can
/// being serialized and deserialized using [fromJson]
/// respectively.
/// {@endtemplate}
@immutable
@JsonSerializable(createToJson: false)
class JsonDependency extends Equatable {
  /// {@macro todo_item}
  const JsonDependency({
    required this.oneOf,
  });

  /// A way to define conditional schemas where only one of multiple schemas
  /// must be valid, depending on specific conditions.
  /// When dependencies is used with oneOf, it enables conditional logic based
  /// on the fields in the JSON data, allowing the schema to adapt according to
  /// certain field value
  final List<JsonSchema> oneOf;

  /// Deserializes the given [JsonMap] into a [JsonDependency].
  static JsonDependency fromJson(JsonMap json) =>
      _$JsonDependencyFromJson(json);

  @override
  List<Object?> get props => [oneOf];
}
