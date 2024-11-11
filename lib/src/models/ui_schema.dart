import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:jsonschema_form/src/models/json_map.dart';
import 'package:jsonschema_form/src/models/ui_type.dart';
import 'package:meta/meta.dart';

/// {@template ui_schema}
/// A single `ui_schema` item.
///
/// Contains a [widget]
///
/// [UiSchema]s are immutable, they can
/// being serialized and deserialized using [UiSchema.fromJson]
/// respectively.
/// {@endtemplate}
@immutable
class UiSchema extends Equatable {
  /// {@macro json_schema}
  const UiSchema({
    this.children,
    this.widget,
  });

  /// Deserializes the given [JsonMap] into a [UiSchema].
  factory UiSchema.fromJson(Map<String, dynamic> json) {
    Map<String, UiSchema>? parsedChildren;

    // Check for child nodes and recursively parse them
    if (json.isNotEmpty) {
      parsedChildren = json.map((key, value) {
        if (value is Map<String, dynamic>) {
          return MapEntry(key, UiSchema.fromJson(value));
        } else {
          return MapEntry(key, const UiSchema());
        }
      });
    }

    return UiSchema(
      widget: $enumDecodeNullable(_$UiTypeEnumMap, json['ui:widget']),
      children: parsedChildren,
    );
  }

  /// Map to hold child nodes for nested fields
  final Map<String, UiSchema>? children;

  /// Defines the type of widget to be used for the given key
  final UiType? widget;

  @override
  List<Object?> get props => [
        widget,
      ];
}

const _$UiTypeEnumMap = {
  UiType.text: 'text',
  UiType.select: 'select',
  UiType.radio: 'radio',
  UiType.checkboxes: 'checkboxes',
};
