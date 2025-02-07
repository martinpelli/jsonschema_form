import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/ui_schema.dart';

/// A form widget that manages a JSON schema, UI schema, and form data.
///
/// This class accepts three arguments:
/// - `schemaJson`: The JSON schema defining the structure and validation
///   of the form.
/// - `uiJson`: The UI schema defining the visual structure of the form.
/// - `dataJson`: The form data (optional, default is an empty map) that holds
///   the current state of the form.
class JsonschemaForm {
  /// Creates a new [JsonschemaForm] instance with the provided schema, UI
  /// schema, and form data.
  ///
  /// - `schemaJson`: A [Map<String, dynamic>] that represents the form's
  ///   JSON schema.
  /// - `uiJson`: A [Map<String, dynamic>] that represents the UI schema.
  /// - `dataJson`: A [Map<String, dynamic>] that represents the form data
  ///   (optional, defaults to an empty map).
  JsonschemaForm({
    required this.schemaJson,
    required this.uiJson,
    this.dataJson = const {},
  }) {
    jsonSchema = JsonSchema.fromJson(schemaJson);
    uiSchema = UiSchema.fromJson(uiJson);
    _formData = dataJson;
  }

  /// The JSON schema of the form, which defines the structure and validation
  /// rules.
  final Map<String, dynamic> schemaJson;

  /// The UI schema of the form, which defines the visual structure and how
  /// the form will be displayed.
  final Map<String, dynamic> uiJson;

  /// The data representing the current state of the form (optional, defaults
  /// to an empty map).
  final Map<String, dynamic> dataJson;

  /// Private variable holding the parsed [JsonSchema] object.
  late JsonSchema _jsonSchema;

  /// Private variable holding the parsed [UiSchema] object.
  late UiSchema _uiSchema;

  /// Private variable holding the form data as a [Map<String, dynamic>].
  late Map<String, dynamic> _formData;

  /// Sets the [JsonSchema] for the form, replacing the current schema.
  ///
  /// This setter accepts a [JsonSchema] object that defines the validation
  /// rules and structure for the form.
  set jsonSchema(JsonSchema newJsonSchema) {
    _jsonSchema = newJsonSchema;
  }

  /// Gets the current [JsonSchema] object.
  ///
  /// This getter returns the [JsonSchema] representing the current form's
  /// schema.
  JsonSchema get jsonSchema => _jsonSchema;

  /// Sets the [UiSchema] for the form, replacing the current UI schema.
  ///
  /// This setter accepts a [UiSchema] object that defines how the form is
  /// visually structured.
  set uiSchema(UiSchema newUiSchema) {
    _uiSchema = newUiSchema;
  }

  /// Gets the current [UiSchema] object.
  ///
  /// This getter returns the [UiSchema] representing the current form's
  /// visual layout.
  UiSchema get uiSchema => _uiSchema;

  /// Sets the form data.
  ///
  /// This setter accepts a [Map<String, dynamic>] that represents the
  /// current form data.
  set formData(Map<String, dynamic> newFormData) {
    _formData = newFormData;
  }

  /// Gets the current form data as a [Map<String, dynamic>].
  ///
  /// This getter returns the form data that represents the current state
  /// of the form.
  Map<String, dynamic> get formData => _formData;
}
