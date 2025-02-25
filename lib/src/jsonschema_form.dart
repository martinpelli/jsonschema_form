import 'package:jsonschema_form/jsonschema_form.dart';
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
    this.formData = const {},
  }) {
    jsonSchema = JsonSchema.fromJson(schemaJson);
    uiSchema = UiSchema.fromJson(uiJson);
    initialFormData = formData.deepCopy();
  }

  /// The JSON schema of the form, which defines the structure and validation
  /// rules.
  final Map<String, dynamic> schemaJson;

  /// The UI schema of the form, which defines the visual structure and how
  /// the form will be displayed.
  final Map<String, dynamic> uiJson;

  /// Variable holding the parsed [JsonSchema] object.
  late JsonSchema jsonSchema;

  /// Variable holding the parsed [UiSchema] object.
  late UiSchema uiSchema;

  /// Variable holding the form data as a [Map<String, dynamic>].
  late Map<String, dynamic> formData;

  /// Variable holding the initial form data as a [Map<String, dynamic>].
  late Map<String, dynamic> initialFormData;
}
