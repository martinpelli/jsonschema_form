import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:jsonschema_form/jsonschema_form.dart';
import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/json_schema_format.dart';
import 'package:jsonschema_form/src/models/json_type.dart';
import 'package:jsonschema_form/src/models/ui_options.dart';
import 'package:jsonschema_form/src/models/ui_schema.dart';
import 'package:jsonschema_form/src/models/ui_type.dart';
import 'package:jsonschema_form/src/utils/dynamic_utils.dart';
import 'package:jsonschema_form/src/utils/map_extension.dart';
import 'package:jsonschema_form/src/utils/xfile_extension.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

part 'screens/camera_screen.dart';
part 'widgets/custom_checkbox_group.dart';
part 'widgets/custom_dropdown_menu.dart';
part 'widgets/custom_form_field_validator.dart';
part 'widgets/custom_radio_group.dart';
part 'widgets/custom_text_form_field.dart';
part 'widgets/custom_file_upload.dart';
part 'widgets/one_of_form.dart';
part 'widgets/array_form.dart';
part 'widgets/ui_widget.dart';

/// Builds a Form by decoding a Json Schema
class JsonschemaFormBuilder extends StatefulWidget {
  /// {@macro jsonschema_form_builder}
  const JsonschemaFormBuilder({
    required this.jsonSchemaForm,
    required this.onFormSubmitted,
    this.submitButtonStyle,
    this.submitButtonChild,
    this.formPadding = EdgeInsets.zero,
    super.key,
  });

  /// The json schema for the form.
  final JsonschemaForm jsonSchemaForm;

  /// Method triggered when the field is succesfully submitted, if there is any
  /// error on the form, this will not trigger. The method receives the final
  /// formData filled by the user
  final void Function(Map<String, dynamic> formData) onFormSubmitted;

  /// Change the style of submit button.
  final ButtonStyle? submitButtonStyle;

  /// Change the child of submit button.
  final Widget? submitButtonChild;

  /// If you need to add padding inside the scroll view, use formPadding
  final EdgeInsets formPadding;

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
      child: Padding(
        padding: widget.formPadding,
        child: Form(
          key: _formKey,
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
                style: widget.submitButtonStyle,
                onPressed: () {
                  FocusScope.of(context).unfocus();

                  final isFormValid =
                      _formKey.currentState?.validate() ?? false;

                  if (isFormValid) {
                    widget.onFormSubmitted(_formData.removeEmptySubmaps());
                  }
                },
                child: widget.submitButtonChild ?? const Text('Submit'),
              ),
            ],
          ),
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
    int? arrayIndex,
  }) {
    final (newFormData, previousFormData) =
        _modifyFormData(jsonSchema, jsonKey, formData);

    final title = _getTitle(jsonSchema, uiSchema, previousSchema, arrayIndex);

    final description = _getDescription(jsonSchema, uiSchema);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (jsonSchema.type == JsonType.object ||
            jsonSchema.type == JsonType.array) ...[
          if (title != null) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Divider(),
            const SizedBox(height: 10),
          ],
          if (description != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(description),
            ),
        ],
        if (jsonSchema.type == null || jsonSchema.type == JsonType.object) ...[
          for (final entry in jsonSchema.properties?.entries ??
              <MapEntry<String, JsonSchema>>[]) ...[
            /// Build one Widget for each property in the schema
            _buildJsonschemaForm(
              entry.value,
              entry.key,
              uiSchema?.children?[entry.key],
              newFormData,
              previousSchema: jsonSchema,
              previousJsonKey: jsonKey,
              arrayIndex: arrayIndex,
            ),

            /// Build Schema dependencies, widgets that will be added
            /// dynamically depending on other field values
            if (jsonSchema.dependencies != null &&
                jsonSchema.dependencies![entry.key] is JsonSchema &&
                jsonSchema.dependencies!.keys.contains(entry.key) &&
                ((newFormData as Map<String, dynamic>?)
                        ?.containsKey(entry.key) ??
                    false))
              _buildJsonschemaForm(
                jsonSchema.dependencies![entry.key] as JsonSchema,
                entry.key,
                uiSchema,
                newFormData,
                previousSchema: jsonSchema,
                previousJsonKey: jsonKey,
                arrayIndex: arrayIndex,
              ),
          ],
          if (jsonSchema.oneOf != null)
            _OneOfForm(
              jsonSchema,
              jsonKey,
              uiSchema,
              newFormData as Map<String, dynamic>,
              previousSchema: previousSchema,
              previousJsonKey: previousJsonKey,
              buildJsonschemaForm: _buildJsonschemaForm,
              rebuildForm: _rebuildForm,
            ),
        ] else if (jsonSchema.type == JsonType.array)
          _ArrayForm(
            jsonSchema: jsonSchema,
            jsonKey: jsonKey,
            uiSchema: uiSchema,
            formData: newFormData,
            buildJsonschemaForm: _buildJsonschemaForm,
          )
        else
          _UiWidget(
            jsonSchema,
            jsonKey,
            uiSchema,
            formData,
            rebuildForm: _rebuildForm,
            previousSchema: previousSchema,
            previousFormData: previousFormData,
            arrayIndex: arrayIndex,
            title: title ?? jsonKey,
          ),
      ],
    );
  }

  /// Access the corresponding jsonKey in the formData in order to put values
  /// in the appropiated field value
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
        /// If there is an empty list coming from formData (possible from an
        /// external data source) it will be removed because dart cannot detect
        /// the list type, so a new one with the correct type wil be created
        /// using putIfAbsent
        if (formData[jsonKey] is List && (formData[jsonKey] as List).isEmpty) {
          formData.remove(jsonKey);
        }

        final newFormData = formData.putIfAbsent(
          jsonKey,
          () {
            /// If the current jsonSchema is an object then it will add a new
            /// empty map to the formData. If it is a list of objects then it
            /// will add a list of maps otherwise will add a dynamic list.
            /// This new data added will be passed to the UiWidget and that
            /// widget will add entries to this new data so it will be possible
            /// to the widget to modify the appropiate property and at same time
            /// will be referencing the formData so it will be updated
            if (jsonSchema.type == JsonType.object) {
              return <String, dynamic>{};
            } else {
              if (DynamicUtils.isLitOfMaps(jsonSchema.items) ||
                  jsonSchema.items is JsonSchema) {
                return <Map<String, dynamic>>[];
              } else {
                return <dynamic>[];
              }
            }
          },
        );
        return (newFormData, previousFormData);
      } else if (formData is List) {
        return (formData, previousFormData);
      }
    } else {
      return (formData, previousFormData);
    }

    return (formData, previousFormData);
  }

  String? _getTitle(
    JsonSchema jsonSchema,
    UiSchema? uiSchema,
    JsonSchema? previousSchema,
    int? arrayIndex,
  ) {
    if (uiSchema?.title != null && uiSchema!.title!.isNotEmpty) {
      return uiSchema.title;
    }
    if (jsonSchema.title != null && jsonSchema.title!.isNotEmpty) {
      return jsonSchema.title;
    }

    if (arrayIndex != null && previousSchema?.title != null) {
      return '${previousSchema?.title}-${arrayIndex + 1}';
    }

    return null;
  }

  String? _getDescription(JsonSchema jsonSchema, UiSchema? uiSchema) {
    if (uiSchema?.description != null && uiSchema!.description!.isNotEmpty) {
      return uiSchema.description;
    }
    if (jsonSchema.description != null && jsonSchema.description!.isNotEmpty) {
      return jsonSchema.description;
    }

    return null;
  }

  /// Rebulds the whole form when needed. For example: when a nested field
  /// changes and depends on others from the tree this will rebuild everything
  /// so te form is updated accordingly. This is an easy and fast solution but a
  /// new more eperformant solution should be done in future.
  void _rebuildForm() {
    setState(() {});
  }
}
