import 'package:flutter/material.dart';
import 'package:jsonschema_form/jsonschema_form.dart';
import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/json_type.dart';
import 'package:jsonschema_form/src/models/ui_schema.dart';
import 'package:jsonschema_form/src/models/ui_type.dart';

part 'widgets/custom_dropdown_menu.dart';
part 'widgets/custom_text_form_field.dart';
part 'widgets/custom_radio_group.dart';

/// Builds a Form by decoding a Json Schema
class JsonschemaFormBuilder extends StatefulWidget {
  /// {@macro jsonschema_form_builder}
  const JsonschemaFormBuilder({super.key});

  @override
  State<JsonschemaFormBuilder> createState() => _JsonschemaFormBuilderState();
}

class _JsonschemaFormBuilderState extends State<JsonschemaFormBuilder> {
  late final JsonschemaForm _jsonSchemaForm;

  final Map<String, String> _selectedEnumValues = {};

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
          ..._buildArrayItems(jsonSchema, uiSchema),
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

  void _onEnumValueSelected(String key, String value) {
    _selectedEnumValues[key] = value;

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
      case UiType.text || null:
        return _CustomTextFormField(labelText: jsonSchema.title);
    }
  }

  List<Widget> _buildArrayItems(JsonSchema jsonSchema, UiSchema? uiSchema) {
    final items = <Widget>[];

    if (jsonSchema.title?.isNotEmpty ?? false) {
      items.add(
        Text(jsonSchema.title!),
      );
    }

    final hasAdditionalItems = jsonSchema.additionalItems != null;

    if (hasAdditionalItems) {
      for (final item in jsonSchema.items as List<JsonSchema>) {
        items.add(
          _buildJsonschemaForm(item, uiSchema),
        );
      }
    }

    for (var i = 0; i < _arrayItems.length; i++) {
      final removeButton = Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          onPressed: () => _removeArrayItem(i),
          icon: const Icon(Icons.remove),
        ),
      );

      items
        ..add(removeButton)
        ..add(
          _buildJsonschemaForm(_arrayItems[i], uiSchema),
        );
    }

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
}
