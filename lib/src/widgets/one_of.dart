part of '../jsonschema_form_builder.dart';

class _OneOfForm extends StatefulWidget {
  const _OneOfForm({
    required this.jsonSchema,
    required this.jsonKey,
    required this.uiSchema,
    required this.buildJsonschemaForm,
    required this.formData,
  });

  final JsonSchema jsonSchema;
  final String? jsonKey;
  final UiSchema? uiSchema;
  final Map<String, dynamic> formData;
  final Widget Function(
    JsonSchema jsonSchema,
    String? jsonKey,
    UiSchema? uiSchema, {
    JsonSchema? previousSchema,
    String? previousJsonKey,
  }) buildJsonschemaForm;

  @override
  State<_OneOfForm> createState() => _OneOfFormState();
}

class _OneOfFormState extends State<_OneOfForm> {
  late JsonSchema selectedOneOfJsonSchema;

  @override
  void initState() {
    super.initState();

    /// If there is no selected value, then the default selected value is the
    /// first element of the oneOf list
    selectedOneOfJsonSchema = widget.jsonSchema.oneOf!.first;
  }

  @override
  Widget build(BuildContext context) {
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
        ),
      ],
    );
  }

  Widget _buildWidgetFromUiSchema() {
    final title = widget.jsonSchema.title ?? widget.jsonKey;

    void onValueSelected(JsonSchema value) {
      selectedOneOfJsonSchema = value;

      //TODO when changing oneOf option, the formData is cleared but
      //TODO TextEditingControllers are not, cuasing issues with form validator

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

      setState(() {});
    }

    String itemLabel(int index, JsonSchema item) =>
        item.title ?? 'Option ${index + 1}';

    if (widget.uiSchema?.widget == null ||
        widget.uiSchema?.widget == UiType.select) {
      return _CustomDropdownMenu<JsonSchema>(
        label: title,
        itemLabel: itemLabel,
        items: widget.jsonSchema.oneOf!,
        selectedItem: selectedOneOfJsonSchema,
        onDropdownValueSelected: onValueSelected,
      );
    } else {
      return _CustomRadioGroup<JsonSchema>(
        label: title,
        itemLabel: itemLabel,
        jsonKey: widget.jsonKey!,
        items: widget.jsonSchema.oneOf!,
        onRadioValueSelected: (_, value) => onValueSelected(value),
      );
    }
  }
}
