import 'package:flutter/material.dart';
import 'package:jsonschema_form/jsonschema_form.dart';
import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/json_type.dart';

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

  @override
  void initState() {
    super.initState();

    _jsonSchemaForm = JsonschemaForm();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _buildJsonschemaForm(_jsonSchemaForm.jsonSchema, null, null),
    );
  }

  Widget _buildJsonschemaForm(
    JsonSchema schema,
    String? jsonKey,
    JsonSchema? previousSchema,
  ) {
    return Column(
      children: [
        if (schema.type == JsonType.object) ...[
          if (schema.title?.isNotEmpty ?? false) Text(schema.title!),
          for (final entry in schema.properties!.entries)
            _buildJsonschemaForm(entry.value, entry.key, schema),
        ] else if (schema.type == JsonType.string &&
            (schema.enumValue == null || schema.enumValue!.isEmpty))
          TextFormField(
            decoration: InputDecoration(labelText: schema.title),
          )
        else if (schema.type == JsonType.string &&
            (schema.enumValue != null || schema.enumValue!.isNotEmpty))
          _CustomDropdownMenu(
            jsonKey: jsonKey!,
            label: schema.title,
            items: schema.enumValue!,
            onDropdownValueSelected: _onDropdownValueSelected,
          ),
        if (previousSchema?.dependencies != null &&
            jsonKey != null &&
            _selectedEnumValues.containsKey(jsonKey))
          ..._getDependencies(
            jsonKey,
            previousSchema!.dependencies![jsonKey]!.oneOf,
            schema,
          ),
      ],
    );
  }

  void _onDropdownValueSelected(String key, String value) {
    _selectedEnumValues[key] = value;

    setState(() {});
  }

  List<Widget> _getDependencies(
    String jsonKey,
    List<JsonSchema> dependencies,
    JsonSchema schema,
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
      widgets.add(_buildJsonschemaForm(entry.value, entry.key, schema));
    }

    return widgets;
  }
}

class _CustomDropdownMenu extends StatefulWidget {
  const _CustomDropdownMenu({
    required this.jsonKey,
    required this.label,
    required this.items,
    required this.onDropdownValueSelected,
  });

  final String jsonKey;
  final String? label;
  final List<String> items;
  final void Function(String, String) onDropdownValueSelected;

  @override
  State<_CustomDropdownMenu> createState() => _CustomDropdownMenuState();
}

class _CustomDropdownMenuState extends State<_CustomDropdownMenu> {
  final TextEditingController colorController = TextEditingController();
  final TextEditingController iconController = TextEditingController();
  String? selectedItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: DropdownMenu<String>(
        enableSearch: false,
        width: double.infinity,
        controller: colorController,
        requestFocusOnTap: true,
        label: widget.label == null ? null : Text(widget.label!),
        onSelected: (String? item) {
          if (item != null) {
            widget.onDropdownValueSelected(widget.jsonKey, item);
          }
          setState(() {
            selectedItem = item;
          });
        },
        dropdownMenuEntries:
            widget.items.map<DropdownMenuEntry<String>>((String item) {
          return DropdownMenuEntry<String>(
            value: item,
            label: item,
            style: MenuItemButton.styleFrom(),
          );
        }).toList(),
      ),
    );
  }
}
