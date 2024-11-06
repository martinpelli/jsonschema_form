import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:jsonschema_form/src/models/json_map.dart';
import 'package:meta/meta.dart';

part 'json_dependency.g.dart';

/// {@template json_schema}
/// A single `json_schema` item.
///
/// Contains a [title], [type] and [properties]
///
/// [JsonDependency]s are immutable, they can
/// being serialized and deserialized using [toJson] and [fromJson]
/// respectively.
/// {@endtemplate}
@immutable
@JsonSerializable()
class JsonDependency extends Equatable {
  /// {@macro todo_item}
  const JsonDependency({
    required this.oneOf,
  });

  /// A human-readable name or label for a particular schema or field.
  /// It’s often displayed as the label or header when generating forms based
  /// on the schema.
  /// Can be empty.
  final List<JsonMap> oneOf;

  /// Deserializes the given [JsonMap] into a [JsonDependency].
  static JsonDependency fromJson(JsonMap json) =>
      _$JsonDependencyFromJson(json);

  /// Converts this [JsonDependency] into a [JsonMap].
  JsonMap toJson() => _$JsonDependencyToJson(this);

  @override
  List<Object?> get props => [oneOf];
}
