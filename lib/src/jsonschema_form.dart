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

  /// Form data that pre-populates the form and gets updated with user inputs.
  Map<String, dynamic>? formData;

  /// Asynchronous init [JsonschemaForm] from an asset
  /// file.
  Future<void> initFromJsonAsset(String pathToJson) async {
    final jsonString = await rootBundle.loadString(pathToJson);
    final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
    _init(decodedJson);
  }

  /// Init [JsonschemaForm] from an already decoded json
  void initFromDecodedJson(Map<String, dynamic> decodedJson) {
    _init(decodedJson);
  }

  /// Init [JsonschemaForm] from an already decoded json
  void initFromJsonString(String json) {
    final decodedJson = jsonDecode(json) as Map<String, dynamic>;
    _init(decodedJson);
  }

  /// Init [JsonschemaForm] from an already decoded [jsonSchema],
  /// [uiSchema] and [formData]
  void initFromJsonsString(
    String jsonSchema,
    String uiSchema,
    String formData,
  ) {
    final decodedJsonSchema = jsonDecode(jsonSchema) as Map<String, dynamic>;
    final decodedUiSchema = jsonDecode(uiSchema) as Map<String, dynamic>;
    final decodedFormData = jsonDecode(formData) as Map<String, dynamic>;

    _setJsonSchema(decodedJsonSchema);
    _setUiSchema(decodedUiSchema);
    this.formData = decodedFormData;
  }

  void _init(Map<String, dynamic> decodedJson) {
    if (decodedJson['jsonSchema'] == null ||
        decodedJson['uiSchema'] == null ||
        decodedJson['formData'] == null) {
      return;
    }

    _setJsonSchema(decodedJson['jsonSchema'] as Map<String, dynamic>);
    _setUiSchema(decodedJson['uiSchema'] as Map<String, dynamic>);
    formData = decodedJson['formData'] as Map<String, dynamic>;
  }

  void _setJsonSchema(Map<String, dynamic> decodedJsonSchema) {
    jsonSchema = JsonSchema.fromJson(decodedJsonSchema);
  }

  void _setUiSchema(Map<String, dynamic> decodedJsonSchema) {
    uiSchema = UiSchema.fromJson(decodedJsonSchema);
  }
}
