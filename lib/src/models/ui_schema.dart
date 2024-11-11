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
    this.options,
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

    late final Map<String, bool>? options;

    if (json['ui:options'] == null) {
      options = null;
    } else {
      options = (json['ui:options'] as Map<String, dynamic>).map((key, value) {
        return MapEntry(key, value as bool);
      });
    }

    return UiSchema(
      widget: $enumDecodeNullable(_$UiTypeEnumMap, json['ui:widget']),
      options: options,
      children: parsedChildren,
    );
  }

  /// Map to hold child nodes for nested fields
  final Map<String, UiSchema>? children;

  /// Defines the type of widget to be used for the given key
  final UiType? widget;

  /// Defines options to be used for the given key, for instance: if options
  /// is {
  ///   removable: false
  /// }
  /// then this indicates user can't delete items from array
  final Map<String, bool>? options;

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
