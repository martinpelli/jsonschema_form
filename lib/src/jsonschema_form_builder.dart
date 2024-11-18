import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jsonschema_form/jsonschema_form.dart';
import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/json_type.dart';
import 'package:jsonschema_form/src/models/ui_options.dart';
import 'package:jsonschema_form/src/models/ui_schema.dart';
import 'package:jsonschema_form/src/models/ui_type.dart';

part 'widgets/custom_checkbox_group.dart';
part 'widgets/custom_dropdown_menu.dart';
part 'widgets/custom_form_field_validator.dart';
part 'widgets/custom_radio_group.dart';
part 'widgets/custom_text_form_field.dart';
part 'widgets/one_of.dart';

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
  /// [formData] filled by the user
  final void Function(Map<String, dynamic> formData) onFormSubmitted;

  @override
  State<JsonschemaFormBuilder> createState() => _JsonschemaFormBuilderState();
}

class _JsonschemaFormBuilderState extends State<JsonschemaFormBuilder> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, dynamic> _formData;

  final List<JsonSchema> _arrayItems = [];

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
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                FocusScope.of(context).unfocus();

                final isFormValid = _formKey.currentState?.validate() ?? false;

                if (isFormValid) {
                  widget.onFormSubmitted(_formData);
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
    UiSchema? uiSchema, {
    JsonSchema? previousSchema,
    String? previousJsonKey,
  }) {
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
        ] else if (jsonSchema.type != JsonType.object &&
            jsonSchema.type != JsonType.array)
          _buildWidgetFromUiSchema(
            jsonSchema,
            jsonKey,
            uiSchema,
            previousSchema,
          )
        else if (jsonSchema.type == JsonType.array && jsonSchema.items != null)
          ..._buildArrayItems(jsonSchema, jsonKey, uiSchema),
        if (previousSchema?.dependencies != null &&
            _formData.containsKey(jsonKey))
          ..._getDependencies(
            jsonSchema,
            jsonKey,
            uiSchema,
            previousSchema!.dependencies![jsonKey]!.oneOf!,
          ),
      ],
    );
  }

  Widget _buildWidgetFromUiSchema(
    JsonSchema jsonSchema,
    String? jsonKey,
    UiSchema? uiSchema,
    JsonSchema? previousSchema,
  ) {
    final hasValidator =
        previousSchema?.requiredFields?.contains(jsonKey) ?? false;

    final title = jsonSchema.title ?? jsonKey;

    final defaultValue = _formData.containsKey(jsonKey)
        ? _formData[jsonKey].toString()
        : jsonSchema.defaultValue;

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
                  _onEnumValueSelected(jsonKey!, value);
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
                  _onEnumValueSelected(key, value);
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
                  _onMultipleEnumValuesSelected(key, value);
                }
              },
            );
          },
        );

      case UiType.textarea:
        return _CustomTextFormField(
          onChanged: (value) {
            if (value.isEmpty) {
              _formData.remove(jsonKey);
            } else {
              _formData[jsonKey!] = value;
            }
          },
          hasValidator: hasValidator,
          labelText: title,
          minLines: 4,
          maxLines: null,
          defaultValue: defaultValue,
          emptyValue: uiSchema?.emptyValue,
          placeholder: uiSchema?.placeholder,
          autofocus: uiSchema?.autofocus,
        );
      case UiType.updown:
        return _CustomTextFormField(
          onChanged: (value) {
            if (value.isEmpty) {
              _formData.remove(jsonKey);
            } else {
              _formData[jsonKey!] = value;
            }
          },
          hasValidator: hasValidator,
          labelText: title,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          defaultValue: defaultValue,
          emptyValue: uiSchema?.emptyValue,
          placeholder: uiSchema?.placeholder,
          autofocus: uiSchema?.autofocus,
        );
      case UiType.text || null:
        return _CustomTextFormField(
          onChanged: (value) {
            if (value.isEmpty) {
              _formData.remove(jsonKey);
            } else {
              _formData[jsonKey!] = value;
            }
          },
          hasValidator: hasValidator,
          labelText: title,
          defaultValue: defaultValue,
          emptyValue: uiSchema?.emptyValue,
          placeholder: uiSchema?.placeholder,
          autofocus: uiSchema?.autofocus,
        );
    }
  }

  void _onEnumValueSelected(String key, String value) {
    if (value.isEmpty) {
      _formData.remove(key);
    } else {
      _formData[key] = value;
    }

    setState(() {});
  }

  void _onMultipleEnumValuesSelected(String key, List<String> value) {
    if (value.isEmpty) {
      _formData.remove(key);
    } else {
      _formData[key] = value;
    }

    setState(() {});
  }

  List<Widget> _buildArrayItems(
    JsonSchema jsonSchema,
    String? jsonKey,
    UiSchema? uiSchema,
  ) {
    final items = <Widget>[];

    if (jsonSchema.title?.isNotEmpty ?? false) {
      items.add(
        Text(jsonSchema.title!),
      );
    }

    /// If [additionalItems] property from the corresponding [jsonSchema] is
    /// present then the user is allowed to add additional items for the given
    /// [jsonSchema]

    final hasAdditionalItems = jsonSchema.additionalItems != null;

    if (hasAdditionalItems) {
      for (final item in jsonSchema.items as List<JsonSchema>) {
        items.add(
          _buildJsonschemaForm(item, jsonKey, uiSchema),
        );
      }
    }

    /// if the [jsonSchema] has the [uniqueItems] property then this form will
    /// be considered a multiple choice list and the [enum] value from items
    /// must not be null as they will be the possible choices

    if (jsonSchema.uniqueItems ?? false) {
      final schemaFromItems = jsonSchema.items as JsonSchema;
      if (schemaFromItems.enumValue != null) {
        items.add(
          _buildJsonschemaForm(schemaFromItems, jsonKey, uiSchema),
        );
      }
    }

    /// if the [jsonSchema] has the [minItems] property then [items] will be
    /// added at first and user can't remove them

    final minItems = jsonSchema.minItems ?? 0;

    for (var i = 0; i < minItems; i++) {
      items.add(
        _buildJsonschemaForm(jsonSchema.items as JsonSchema, jsonKey, uiSchema),
      );
    }

    /// Builds items that user has added using (+) button from the form
    /// They can be removed if [removable] is not present or is set to false
    /// in the corresponding [uiSchema] property

    for (var i = 0; i < _arrayItems.length; i++) {
      final hasRemoveButton = uiSchema?.options == null ||
          (uiSchema!.options!.containsKey(UiOptions.removable.name) &&
              (uiSchema.options![UiOptions.removable.name] ?? true));

      if (hasRemoveButton) {
        final removeButton = Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: () => _removeArrayItem(i),
            icon: const Icon(Icons.remove),
          ),
        );
        items.add(removeButton);
      }

      items.add(
        _buildJsonschemaForm(_arrayItems[i], jsonKey, uiSchema),
      );
    }

    /// The (+) button is added by default unless [addable] is
    /// provided to the corresponding [uiSchema] property and set to false
    /// If [maxItems] property specified in [jsonSchema] and the array
    /// has reached [maxItems] then (+) is not added

    final isMaxReached = jsonSchema.maxItems != null &&
        _arrayItems.length + minItems >= jsonSchema.maxItems!;

    final hasAddButton = uiSchema?.options == null ||
        (uiSchema!.options!.containsKey(UiOptions.addable.name) &&
            (uiSchema.options![UiOptions.addable.name] ?? true));

    if (hasAddButton && !isMaxReached) {
      final addButton = Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          onPressed: () {
            if (hasAdditionalItems) {
              _addArrayItem(jsonSchema.additionalItems!);
            } else {
              _addArrayItem(jsonSchema.items as JsonSchema);
            }
          },
          icon: const Icon(Icons.add),
        ),
      );

      items.add(addButton);
    }

    return items;
  }

  void _addArrayItem(JsonSchema jsonSchema) {
    _arrayItems.add(jsonSchema);
    setState(() {});
  }

  void _removeArrayItem(int index) {
    _arrayItems.removeAt(index);
    setState(() {});
  }

  List<Widget> _getDependencies(
    JsonSchema jsonSchema,
    String? jsonKey,
    UiSchema? uiSchema,
    List<JsonSchema> dependencies,
  ) {
    /// This is neccessary in order to match the dependency from the current
    /// schema
    /// The first element of the property [oneOf] is the selected value, so it
    /// is skipped
    final dependencySchema = dependencies
        .firstWhere(
          (element) =>
              element.properties![jsonKey]!.constValue == _formData[jsonKey],
        )
        .properties!
        .entries
        .skip(1);

    final widgets = <Widget>[];

    for (final entry in dependencySchema) {
      widgets.add(
        _buildJsonschemaForm(
          entry.value,
          entry.key,
          uiSchema?.children?[entry.key],
          previousSchema: jsonSchema,
          previousJsonKey: jsonKey,
        ),
      );
    }

    return widgets;
  }
}
