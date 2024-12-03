part of '../jsonschema_form_builder.dart';

class _OneOfForm extends StatefulWidget {
  const _OneOfForm(
    this.jsonSchema,
    this.jsonKey,
    this.uiSchema,
    this.formData, {
    required this.buildJsonschemaForm,
    required this.rebuildForm,
    this.previousSchema,
    this.previousJsonKey,
  });

  final JsonSchema jsonSchema;
  final String? jsonKey;
  final UiSchema? uiSchema;
  final Map<String, dynamic> formData;
  final JsonSchema? previousSchema;
  final String? previousJsonKey;
  final Widget Function(
    JsonSchema jsonSchema,
    String? jsonKey,
    UiSchema? uiSchema,
    dynamic formData, {
    JsonSchema? previousSchema,
    String? previousJsonKey,
  }) buildJsonschemaForm;
  final void Function() rebuildForm;

  @override
  State<_OneOfForm> createState() => _OneOfFormState();
}

class _OneOfFormState extends State<_OneOfForm> {
  late JsonSchema selectedOneOfJsonSchema;

  @override
  void initState() {
    super.initState();

    if (widget.formData.isEmpty) {
      /// If there is no selected value, then the default selected value is the
      /// first element of the oneOf list
      selectedOneOfJsonSchema = widget.jsonSchema.oneOf!.first;
    } else {
      /// If there is data in formData then it will select the oneOf item if the
      /// first key from oneOf items matches the first key from the formData
      selectedOneOfJsonSchema = widget.jsonSchema.oneOf!.firstWhere(
        (element) =>
            element.properties!.entries.first.key ==
            widget.formData.entries.first.key,
      );
    }
  }

  @override
  void didUpdateWidget(covariant _OneOfForm oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    /// If oneOf list is part of dependencies, then it means iw will conditional
    /// select one element of the list depending on other selected value
    if (widget.previousSchema?.dependencies != null &&
        (widget.previousSchema!.properties?.containsKey(widget.jsonKey) ??
            false) &&
        widget.formData.containsKey(widget.jsonKey)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildOneOfDependencies(),
      );
    } else {
      return _buildSimpleOneOf();
    }
  }

  Widget _buildSimpleOneOf() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// With this widget the user can select one value from the oneOf list
        _buildWidgetFromUiSchema(),

        /// This widgets will be built based on oneOf selected value
        widget.buildJsonschemaForm(
          selectedOneOfJsonSchema,
          widget.jsonKey,
          widget.uiSchema,
          widget.formData,
          previousSchema: widget.jsonSchema,
          previousJsonKey: widget.jsonKey,
        ),
      ],
    );
  }

  Widget _buildWidgetFromUiSchema() {
    final title = widget.jsonSchema.title ?? widget.jsonKey;

    void onValueSelected(JsonSchema value) {
      selectedOneOfJsonSchema = value;

      /// Clear all oneOf filled fields
      bool removeWhere(String key, dynamic _) {
        return widget.jsonSchema.oneOf!
            .expand(
              (element) => element.properties!.keys,
            )
            .contains(key);
      }

      if (widget.jsonKey == null) {
        widget.formData.removeWhere(removeWhere);
      } else if (widget.formData[widget.jsonKey] is Map<String, dynamic>) {
        (widget.formData[widget.jsonKey] as Map<String, dynamic>)
            .removeWhere(removeWhere);
      }

      /// When oneOf has changed, it will rebuild the whole form so that all
      /// controllers get cleared
      widget.rebuildForm();
    }

    String itemLabel(int index, JsonSchema item) =>
        item.title ?? 'Option ${index + 1}';

    if (widget.uiSchema?.widget == null ||
        widget.uiSchema?.widget == UiType.select) {
      return _CustomDropdownMenu<JsonSchema>(
        label: title,
        labelStyle: null,
        itemLabel: itemLabel,
        items: widget.jsonSchema.oneOf!,
        selectedItem: selectedOneOfJsonSchema,
        onDropdownValueSelected: onValueSelected,
      );
    } else {
      return _CustomRadioGroup<JsonSchema>(
        label: title,
        labelStyle: null,
        itemLabel: itemLabel,
        jsonKey: widget.jsonKey!,
        items: widget.jsonSchema.oneOf!,
        initialItem: selectedOneOfJsonSchema,
        onRadioValueSelected: onValueSelected,
      );
    }
  }

  List<Widget> _buildOneOfDependencies() {
    /// This is neccessary in order to match the dependency from the current
    /// schema
    /// The first element of the property [oneOf] is the selected value, so it
    /// is skipped
    final dependencySchema = widget.jsonSchema.oneOf!
        .firstWhere((element) {
          final firstOneOfValue =
              element.properties![widget.jsonKey]!.enumValue?.first ??
                  element.properties![widget.jsonKey]!.constValue;
          return firstOneOfValue == widget.formData[widget.jsonKey];
        })
        .properties!
        .entries
        .skip(1);

    final widgets = <Widget>[];

    for (final entry in dependencySchema) {
      widgets.add(
        widget.buildJsonschemaForm(
          entry.value,
          entry.key,
          widget.uiSchema?.children?[entry.key],
          widget.formData,
          previousSchema: widget.jsonSchema,
          previousJsonKey: widget.jsonKey,
        ),
      );
    }

    return widgets;
  }
}
