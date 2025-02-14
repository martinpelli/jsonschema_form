import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/ui_schema.dart';
import 'package:jsonschema_form/src/utils/map_extension.dart';

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
    formData = dataJson.deepCopy();
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
  late JsonSchema jsonSchema;

  /// Private variable holding the parsed [UiSchema] object.
  late UiSchema uiSchema;

  /// Private variable holding the form data as a [Map<String, dynamic>].
  late Map<String, dynamic> formData;
}
