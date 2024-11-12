import 'package:flutter/material.dart';
import 'package:jsonschema_form/jsonschema_form.dart';
import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/json_type.dart';
import 'package:jsonschema_form/src/models/ui_options.dart';
import 'package:jsonschema_form/src/models/ui_schema.dart';
import 'package:jsonschema_form/src/models/ui_type.dart';

part 'widgets/custom_dropdown_menu.dart';
part 'widgets/custom_text_form_field.dart';
part 'widgets/custom_radio_group.dart';
part 'widgets/custom_checkbox_group.dart';

/// Builds a Form by decoding a Json Schema
class JsonschemaFormBuilder extends StatefulWidget {
  /// {@macro jsonschema_form_builder}
  const JsonschemaFormBuilder({super.key});

  @override
  State<JsonschemaFormBuilder> createState() => _JsonschemaFormBuilderState();
}

class _JsonschemaFormBuilderState extends State<JsonschemaFormBuilder> {
  late final JsonschemaForm _jsonSchemaForm;

  final Map<String, dynamic> _selectedEnumValues = {};

  final List<JsonSchema> _arrayItems = [];

  @override
  void initState() {
    super.initState();

    _jsonSchemaForm = JsonschemaForm();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _buildJsonschemaForm(
        _jsonSchemaForm.jsonSchema,
        _jsonSchemaForm.uiSchema,
      ),
    );
  }

  Widget _buildJsonschemaForm(
    JsonSchema jsonSchema,
    UiSchema? uiSchema, {
    String? jsonKey,
    JsonSchema? previousSchema,
    String? previousJsonKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (jsonSchema.type == JsonType.object) ...[
          if (jsonSchema.title?.isNotEmpty ?? false) Text(jsonSchema.title!),
          for (final entry in jsonSchema.properties!.entries)
            _buildJsonschemaForm(
              entry.value,
              uiSchema?.children?[entry.key],
              jsonKey: entry.key,
              previousSchema: jsonSchema,
              previousJsonKey: jsonKey,
            ),
        ] else if (jsonSchema.type == JsonType.string &&
            (jsonSchema.enumValue == null || jsonSchema.enumValue!.isEmpty))
          _buildWidgetFromUiSchema(jsonSchema, uiSchema, jsonKey)
        else if (jsonSchema.type == JsonType.string &&
            (jsonSchema.enumValue != null || jsonSchema.enumValue!.isNotEmpty))
          _buildWidgetFromUiSchema(
            jsonSchema,
            uiSchema,
            jsonKey,
          )
        else if (jsonSchema.type == JsonType.array && jsonSchema.items != null)
          ..._buildArrayItems(jsonSchema, uiSchema, jsonKey),
        if (previousSchema?.dependencies != null &&
            jsonKey != null &&
            _selectedEnumValues.containsKey(jsonKey))
          ..._getDependencies(
            jsonSchema,
            uiSchema,
            jsonKey,
            previousSchema!.dependencies![jsonKey]!.oneOf,
          ),
      ],
    );
  }

  Widget _buildWidgetFromUiSchema(
    JsonSchema jsonSchema,
    UiSchema? uiSchema,
    String? jsonKey,
  ) {
    switch (uiSchema?.widget) {
      case UiType.select:
        return _CustomDropdownMenu(
          jsonKey: jsonKey!,
          label: jsonSchema.title,
          items: jsonSchema.enumValue!,
          onDropdownValueSelected: _onEnumValueSelected,
        );
      case UiType.radio:
        return _CustomRadioGroup(
          jsonKey: jsonKey!,
          label: jsonSchema.title,
          items: jsonSchema.enumValue!,
          onRadioValueSelected: _onEnumValueSelected,
        );
      case UiType.checkboxes:
        return _CustomCheckboxGroup(
          jsonKey: jsonKey!,
          label: jsonSchema.title,
          items: jsonSchema.enumValue!,
          onCheckboxValuesSelected: _onMultipleEnumValuesSelected,
        );
      case UiType.text || null:
        return _CustomTextFormField(labelText: jsonSchema.title);
    }
  }

  void _onEnumValueSelected(String key, String value) {
    _selectedEnumValues[key] = value;

    setState(() {});
  }

  void _onMultipleEnumValuesSelected(String key, List<String> value) {
    _selectedEnumValues[key] = value;

    setState(() {});
  }

  List<Widget> _buildArrayItems(
    JsonSchema jsonSchema,
    UiSchema? uiSchema,
    String? jsonKey,
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
          _buildJsonschemaForm(item, uiSchema, jsonKey: jsonKey),
        );
      }
    }

    /// if the [jsonSchema] has the [uniqueItems] property then this form will
    /// be considered a multiple choice list and the [enum] value from items
    /// must not be null

    if (jsonSchema.uniqueItems ?? false) {
      final schemaFromItems = jsonSchema.items as JsonSchema;
      if (schemaFromItems.enumValue != null) {
        items.add(
          _buildJsonschemaForm(schemaFromItems, uiSchema, jsonKey: jsonKey),
        );
      }
    }

    /// if the [jsonSchema] has the [minItems] property then [items] will be
    /// added at first and user can't remove them

    final minItems = jsonSchema.minItems ?? 0;

    for (var i = 0; i < minItems; i++) {
      items.add(
        _buildJsonschemaForm(
          jsonSchema.items as JsonSchema,
          uiSchema,
          jsonKey: jsonKey,
        ),
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
        _buildJsonschemaForm(_arrayItems[i], uiSchema, jsonKey: jsonKey),
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
    UiSchema? uiSchema,
    String jsonKey,
    List<JsonSchema> dependencies,
  ) {
    /// This is neccessary in order to match the dependency from the current
    /// schema
    /// The first element of the property [oneOf] is the selected value, so it
    /// is skipped
    final dependencySchema = dependencies
        .firstWhere(
          (element) =>
              element.properties![jsonKey]!.constValue ==
              _selectedEnumValues[jsonKey],
        )
        .properties!
        .entries
        .skip(1);

    final widgets = <Widget>[];

    for (final entry in dependencySchema) {
      widgets.add(
        _buildJsonschemaForm(
          entry.value,
          uiSchema?.children?[entry.key],
          jsonKey: entry.key,
          previousSchema: jsonSchema,
          previousJsonKey: jsonKey,
        ),
      );
    }

    return widgets;
  }
}
