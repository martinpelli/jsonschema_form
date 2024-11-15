import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/ui_schema.dart';

/// {@template jsonschema_form}
/// A Flutter package capable of using JSON Schema to declaratively build and
/// customize Flutter forms.
/// {@endtemplate}
class JsonschemaForm {
  /// Private constructor for internal initialization.
  JsonschemaForm._({
    required this.jsonSchema,
    required this.uiSchema,
    required this.formData,
  });

  /// Factory constructor to create a `JsonschemaForm` from a decoded JSON map.
  factory JsonschemaForm.fromDecodedJson(Map<String, dynamic> decodedJson) {
    return JsonschemaForm._(
      jsonSchema: JsonSchema.fromJson(
        decodedJson['jsonSchema'] as Map<String, dynamic>,
      ),
      uiSchema:
          UiSchema.fromJson(decodedJson['uiSchema'] as Map<String, dynamic>),
      formData: decodedJson['formData'] as Map<String, dynamic>,
    );
  }

  /// Asynchronous factory constructor to load a `JsonschemaForm` from an asset
  /// file.
  static Future<JsonschemaForm> fromJsonAsset(String pathToJson) async {
    final jsonString = await rootBundle.loadString(pathToJson);
    final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
    return JsonschemaForm.fromDecodedJson(decodedJson);
  }

  /// Decoded JSON Schema that defines the layout.
  final JsonSchema jsonSchema;

  /// Decoded UI Schema that customizes the form's UI.
  final UiSchema uiSchema;

  /// Form data that pre-populates the form and gets updated with user input.
  final Map<String, dynamic> formData;
}
