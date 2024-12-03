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
    this.autofocus,
    this.emptyValue,
    this.placeholder,
    this.title,
    this.description,
    this.help,
    this.options,
    this.readonly,
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

    late final Map<String, dynamic>? options;

    if (json['ui:options'] == null) {
      options = null;
    } else {
      options = (json['ui:options'] as Map<String, dynamic>).map((key, value) {
        return MapEntry(key, value as dynamic);
      });
    }

    return UiSchema(
      widget: $enumDecodeNullable(_$UiTypeEnumMap, json['ui:widget']),
      autofocus: json['ui:autofocus'] as bool?,
      emptyValue: json['ui:emptyValue'] as String?,
      placeholder: json['ui:placeholder'] as String?,
      title: json['ui:title'] as String?,
      description: json['ui:description'] as String?,
      help: json['ui:help'] as String?,
      options: options,
      readonly: json['ui:readonly'] as bool?,
      children: parsedChildren,
    );
  }

  /// Map to hold child nodes for nested fields
  final Map<String, UiSchema>? children;

  /// Defines the type of widget to be used for the given key
  final UiType? widget;

  /// Automatically focus on a text input or textarea input when is true
  final bool? autofocus;

  /// Provides the default value to use when an input for a field is empty
  final String? emptyValue;

  /// Add placeholder text to an input
  final String? placeholder;

  /// The title of a field. If this is null, jsonSchema.title will be used and
  /// if jsonSchema.title is null the jsonKey will be used as title.
  final String? title;

  /// Sometimes it's convenient to change the description of a field. This will
  /// be shown as a Text widget above the field
  final String? description;

  /// Provides a brief description for helping de user
  final String? help;

  /// If the filed is an input and [readonly] is true then the input can't
  /// be modified
  final bool? readonly;

  /// Defines options to be used for the given key, for instance: if options
  /// is {
  ///   removable: false
  /// }
  /// then this indicates user can't delete items from array
  final Map<String, dynamic>? options;

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
  UiType.updown: 'updown',
  UiType.textarea: 'textarea',
  UiType.date: 'date',
  UiType.dateTime: 'datetime',
  UiType.file: 'file',
};
