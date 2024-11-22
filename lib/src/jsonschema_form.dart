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
  JsonschemaForm({
    this.jsonSchema,
    this.uiSchema,
    this.formData,
  });

  /// Decoded JSON Schema that defines the layout.
  JsonSchema? jsonSchema;

  /// Decoded UI Schema that customizes the form's UI.
  UiSchema? uiSchema;

  /// Form data that pre-populates the form and gets updated with user input.
  Map<String, dynamic>? formData;

  /// Asynchronous factory constructor to load a `JsonschemaForm` from an asset
  /// file.
  Future<void> initFromJsonAsset(String pathToJson) async {
    final jsonString = await rootBundle.loadString(pathToJson);
    final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
    _init(decodedJson);
  }

  /// Asynchronous factory constructor to load a `JsonschemaForm` from an asset
  /// file.
  void initFromDecodedJson(Map<String, dynamic> decodedJson) {
    _init(decodedJson);
  }

  void _init(Map<String, dynamic> decodedJson) {
    if (decodedJson['jsonSchema'] == null ||
        decodedJson['uiSchema'] == null ||
        decodedJson['formData'] == null) {
      return;
    }

    jsonSchema = JsonSchema.fromJson(
      decodedJson['jsonSchema'] as Map<String, dynamic>,
    );
    uiSchema =
        UiSchema.fromJson(decodedJson['uiSchema'] as Map<String, dynamic>);
    formData = decodedJson['formData'] as Map<String, dynamic>;
  }
}
