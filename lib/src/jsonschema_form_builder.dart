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
    final newFormData = _modifyFormData(jsonSchema, jsonKey, formData);

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
              jsonSchema: jsonSchema,
              jsonKey: jsonKey,
              uiSchema: uiSchema,
              buildJsonschemaForm: _buildJsonschemaForm,
              formData: _formData,
            ),
        ] else
          _buildWidgetFromUiSchema(
            jsonSchema,
            jsonKey,
            uiSchema,
            formData as Map<String, dynamic>,
            previousSchema,
          ),
      ],
    );
  }

  Widget _buildWidgetFromUiSchema(
    JsonSchema jsonSchema,
    String? jsonKey,
    UiSchema? uiSchema,
    Map<String, dynamic> formData,
    JsonSchema? previousSchema,
  ) {
    final hasValidator =
        previousSchema?.requiredFields?.contains(jsonKey) ?? false;

    final title = jsonSchema.title ?? jsonKey;

    final defaultValue = formData.containsKey(jsonKey)
        ? formData[jsonKey]?.toString()
        : jsonSchema.defaultValue;

    void onEnumValueSelected(String key, String value) {
      if (value.isEmpty) {
        formData.remove(key);
      } else {
        formData[key] = value;
      }

      setState(() {});
    }

    void onMultipleEnumValuesSelected(String key, List<String> value) {
      if (value.isEmpty) {
        formData.remove(key);
      } else {
        formData[key] = value;
      }

      setState(() {});
    }

    switch (uiSchema?.widget) {
      case UiType.select:
        return _CustomFormFieldValidator<String>(
          isEnabled: hasValidator,
          isEmpty: (value) => value.isEmpty,
          childFormBuilder: (field) {
            return _CustomDropdownMenu<String>(
              label: title,
              itemLabel: (_, item) => item,
              items: jsonSchema.enumValue!,
              onDropdownValueSelected: (value) {
                field?.didChange(value);
                if (field?.isValid ?? true) {
                  onEnumValueSelected(jsonKey!, value);
                }
              },
            );
          },
        );

      case UiType.radio:
        return _CustomFormFieldValidator<String>(
          isEnabled: hasValidator,
          isEmpty: (value) => value.isEmpty,
          childFormBuilder: (field) {
            return _CustomRadioGroup<String>(
              jsonKey: jsonKey!,
              label: title,
              itemLabel: (_, item) => item,
              items: jsonSchema.enumValue!,
              onRadioValueSelected: (key, value) {
                field?.didChange(value);
                if (field?.isValid ?? true) {
                  onEnumValueSelected(key, value);
                }
              },
            );
          },
        );

      case UiType.checkboxes:
        return _CustomFormFieldValidator<List<String>>(
          isEnabled: hasValidator,
          isEmpty: (value) => value.isEmpty,
          childFormBuilder: (field) {
            return _CustomCheckboxGroup(
              jsonKey: jsonKey!,
              label: title,
              items: jsonSchema.enumValue!,
              onCheckboxValuesSelected: (key, value) {
                field?.didChange(value);
                if (field?.isValid ?? true) {
                  onMultipleEnumValuesSelected(key, value);
                }
              },
            );
          },
        );

      case UiType.textarea:
        return _CustomTextFormField(
          onChanged: (value) {
            if (value.isEmpty) {
              formData.remove(jsonKey);
            } else {
              formData[jsonKey!] = value;
            }
          },
          hasValidator: hasValidator,
          labelText: title,
          minLines: 4,
          maxLines: null,
          defaultValue: defaultValue,
          emptyValue: uiSchema?.emptyValue,
          placeholder: uiSchema?.placeholder,
          helperText: uiSchema?.help,
          autofocus: uiSchema?.autofocus,
        );
      case UiType.updown:
        return _CustomTextFormField(
          onChanged: (value) {
            if (value.isEmpty) {
              formData.remove(jsonKey);
            } else {
              formData[jsonKey!] = value;
            }
          },
          hasValidator: hasValidator,
          labelText: title,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          defaultValue: defaultValue,
          emptyValue: uiSchema?.emptyValue,
          placeholder: uiSchema?.placeholder,
          helperText: uiSchema?.help,
          autofocus: uiSchema?.autofocus,
        );
      case UiType.text || null:
        return _CustomTextFormField(
          onChanged: (value) {
            if (value.isEmpty) {
              formData.remove(jsonKey);
            } else {
              formData[jsonKey!] = value;
            }
          },
          hasValidator: hasValidator,
          labelText: title,
          defaultValue: defaultValue,
          emptyValue: uiSchema?.emptyValue,
          placeholder: uiSchema?.placeholder,
          helperText: uiSchema?.help,
          autofocus: uiSchema?.autofocus,
        );
    }
  }

  dynamic _modifyFormData(
      JsonSchema jsonSchema, String? jsonKey, dynamic formData) {
    if (jsonKey != null &&
        (jsonSchema.type == JsonType.object ||
            jsonSchema.type == JsonType.array)) {
      if (formData is Map<String, dynamic>) {
        return formData.putIfAbsent(
          jsonKey,
          () {
            if (jsonSchema.type == JsonType.object) {
              return <String, dynamic>{};
            } else {
              return <Map<String, dynamic>>[];
            }
          },
        );
      } else if (formData is List<Map<String, dynamic>>) {
        return formData;
      }
    } else {
      return formData;
    }
  }
}
