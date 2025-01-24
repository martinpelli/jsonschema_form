part of '../jsonschema_form_builder.dart';

class _OneOfForm extends StatefulWidget {
  const _OneOfForm(
    this.jsonSchema,
    this.jsonKey,
    this.uiSchema,
    this.formData, {
    required this.buildJsonschemaForm,
    required this.rebuildForm,
    required this.getTitle,
    required this.getDescription,
    required this.getReadOnly,
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
  final bool Function() getReadOnly;
  final String? Function() getTitle;
  final String? Function() getDescription;

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
      selectedOneOfJsonSchema = widget.jsonSchema.oneOf!.firstWhereOrNull(
            (
              element,
            ) {
              /// First it tries to look for a const value, because if there is
              /// one, it should be different in each oneOf object, so it can be
              /// selected based on const value.
              final firstConstValue =
                  element.properties!.entries.firstWhereOrNull(
                (element) => element.value.constValue != null,
              );

              if (firstConstValue != null) {
                final data = widget.formData[firstConstValue.key];
                final value = firstConstValue.value.constValue;
                final isValid = data == value;
                return isValid;
                // return true;
              }

              /// If const value is not present, then it will try to look at the
              /// first key, and the formData should have only that key
              return element.properties!.entries.first.key ==
                  widget.formData.entries.first.key;
            },
          ) ??
          widget.jsonSchema.oneOf!.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    /// If oneOf list is part of dependencies, then it means it will conditional
    /// select one element of the list depending on other selected value
    if (widget.previousSchema?.dependencies != null &&
        (widget.previousSchema!.properties?.containsKey(widget.jsonKey) ??
            false)) {
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
        _buildOneOfSelectionWidget(),

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

  Widget _buildOneOfSelectionWidget() {
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
        readOnly: widget.uiSchema?.readonly ?? widget.getReadOnly(),
        label: widget.getTitle(),
        labelStyle: null,
        itemLabel: itemLabel,
        items: widget.jsonSchema.oneOf!,
        selectedItem: selectedOneOfJsonSchema,
        onDropdownValueSelected: onValueSelected,
      );
    } else {
      return _CustomRadioGroup<JsonSchema>(
        readOnly: widget.uiSchema?.readonly ?? widget.getReadOnly(),
        label: widget.getTitle(),
        labelStyle: null,
        sublabel: widget.getDescription(),
        itemLabel: itemLabel,
        items: widget.jsonSchema.oneOf!,
        initialItem: selectedOneOfJsonSchema,
        onRadioValueSelected: onValueSelected,
      );
    }
  }

  List<Widget> _buildOneOfDependencies() {
    final dependencySchema = widget.jsonSchema.oneOf!.firstWhereOrNull(
      (element) {
        final firstOneOfValue =
            element.properties![widget.jsonKey]!.enumValue?.first ??
                element.properties![widget.jsonKey]!.constValue;
        return firstOneOfValue == widget.formData[widget.jsonKey];
      },
    );

    final dependencyEntries = dependencySchema?.properties?.entries
        .where((element) => element.key != widget.jsonKey);

    if (dependencyEntries == null) {
      return [];
    }

    final widgets = <Widget>[];

    for (final entry in dependencyEntries) {
      /// There are some schemas defined inside a oneOf that are not fully
      /// defined, for example there can be only a readOnly key, in such case
      /// we don't want to build a widget because there is not enough info to
      /// do it, so it will be merged in UiWidget

      if (!(widget.previousSchema?.properties?.containsKey(entry.key) ??
          false)) {
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
    }

    return widgets;
  }
}
