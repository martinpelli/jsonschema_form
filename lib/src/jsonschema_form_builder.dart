import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jsonschema_form/jsonschema_form.dart';
import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/json_type.dart';
import 'package:jsonschema_form/src/models/ui_options.dart';
import 'package:jsonschema_form/src/models/ui_schema.dart';
import 'package:jsonschema_form/src/models/ui_type.dart';
import 'package:jsonschema_form/src/utils/map_extension.dart';

part 'widgets/custom_checkbox_group.dart';
part 'widgets/custom_dropdown_menu.dart';
part 'widgets/custom_form_field_validator.dart';
part 'widgets/custom_radio_group.dart';
part 'widgets/custom_text_form_field.dart';
part 'widgets/one_of_form.dart';
part 'widgets/array_form.dart';
part 'widgets/ui_widget.dart';

/// Builds a Form by decoding a Json Schema
class JsonschemaFormBuilder extends StatefulWidget {
  /// {@macro jsonschema_form_builder}
  const JsonschemaFormBuilder({
    required this.jsonSchemaForm,
    required this.onFormSubmitted,
    super.key,
  });

  /// The json schema for the form.
  final JsonschemaForm jsonSchemaForm;

  /// Method triggered when the field is succesfully submitted, if there is any
  /// error on the form, this will not trigger. The method receives the final
  /// formData filled by the user
  final void Function(Map<String, dynamic> formData) onFormSubmitted;

  @override
  State<JsonschemaFormBuilder> createState() => _JsonschemaFormBuilderState();
}

class _JsonschemaFormBuilderState extends State<JsonschemaFormBuilder> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, dynamic> _formData;

  @override
  void initState() {
    super.initState();
    if (widget.jsonSchemaForm.formData != null) {
      _formData = Map.from(widget.jsonSchemaForm.formData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildJsonschemaForm(
              widget.jsonSchemaForm.jsonSchema!,
              null,
              widget.jsonSchemaForm.uiSchema,
              _formData,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                FocusScope.of(context).unfocus();

                final isFormValid = _formKey.currentState?.validate() ?? false;

                if (isFormValid) {
                  widget.onFormSubmitted(_formData.removeEmptySubmaps());
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJsonschemaForm(
    JsonSchema jsonSchema,
    String? jsonKey,
    UiSchema? uiSchema,
    dynamic formData, {
    JsonSchema? previousSchema,
    String? previousJsonKey,
  }) {
    final (newFormData, previousFormData) =
        _modifyFormData(jsonSchema, jsonKey, formData);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (uiSchema?.description != null && uiSchema!.description!.isNotEmpty)
          Text(uiSchema.description!),
        if (jsonSchema.type == null || jsonSchema.type == JsonType.object) ...[
          if (jsonSchema.title?.isNotEmpty ?? false) ...[
            Text(
              jsonSchema.title!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(),
          ],
          for (final entry in jsonSchema.properties?.entries ??
              <MapEntry<String, JsonSchema>>[])
            _buildJsonschemaForm(
              entry.value,
              entry.key,
              uiSchema?.children?[entry.key],
              newFormData,
              previousSchema: jsonSchema,
              previousJsonKey: jsonKey,
            ),
          if (jsonSchema.oneOf != null)
            _OneOfForm(
              jsonSchema,
              jsonKey,
              uiSchema,
              formData as Map<String, dynamic>,
              buildJsonschemaForm: _buildJsonschemaForm,
            ),
        ] else
          _UiWidget(
            jsonSchema,
            jsonKey,
            uiSchema,
            formData as Map<String, dynamic>,
            rebuildForm: _rebuildForm,
            previousSchema: previousSchema,
            previousFormData: previousFormData as Map<String, dynamic>,
          ),
      ],
    );
  }

  (dynamic, dynamic) _modifyFormData(
    JsonSchema jsonSchema,
    String? jsonKey,
    dynamic formData,
  ) {
    final previousFormData = formData is List
        ? List<dynamic>.from(formData)
        : Map<String, dynamic>.from(formData as Map<String, dynamic>);

    if (jsonKey != null &&
        (jsonSchema.type == JsonType.object ||
            jsonSchema.type == JsonType.array)) {
      if (formData is Map<String, dynamic>) {
        return (
          formData.putIfAbsent(
            jsonKey,
            () {
              if (jsonSchema.type == JsonType.object) {
                return <String, dynamic>{};
              } else {
                return <Map<String, dynamic>>[];
              }
            },
          ),
          previousFormData
        );
      } else if (formData is List<Map<String, dynamic>>) {
        return (formData, previousFormData);
      }
    } else {
      return (formData, previousFormData);
    }

    return (formData, previousFormData);
  }

  void _rebuildForm() {
    setState(() {});
  }
}
