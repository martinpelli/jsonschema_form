part of '../jsonschema_form_builder.dart';

class _ArrayForm extends StatefulWidget {
  const _ArrayForm({
    required this.jsonSchema,
    required this.jsonKey,
    required this.uiSchema,
    required this.formData,
    required this.buildJsonschemaForm,
  });

  final JsonSchema jsonSchema;
  final String? jsonKey;
  final UiSchema? uiSchema;
  final dynamic formData;
  final Widget Function(
    JsonSchema jsonSchema,
    String? jsonKey,
    UiSchema? uiSchema,
    dynamic formData, {
    JsonSchema? previousSchema,
    String? previousJsonKey,
    int? arrayIndex,
  }) buildJsonschemaForm;

  @override
  State<_ArrayForm> createState() => _ArrayFormState();
}

class _ArrayFormState extends State<_ArrayForm> {
  final List<JsonSchema> _arrayItems = [];

  late final bool hasAdditionalItems;

  final initialItems = <Widget>[];

  late final int minItems;

  @override
  void initState() {
    super.initState();

    hasAdditionalItems = widget.jsonSchema.additionalItems != null;

    if (widget.jsonSchema.title?.isNotEmpty ?? false) {
      initialItems.add(
        Text(widget.jsonSchema.title!),
      );
    }

    /// If [additionalItems] property from the corresponding [jsonSchema] is
    /// present then the user is allowed to add additional items for the given
    /// [jsonSchema]

    int initialItemsLength = initialItems.length;

    if (hasAdditionalItems) {
      final additionalItems = widget.jsonSchema.items as List<JsonSchema>;
      for (var i = 0; i < additionalItems.length; i++) {
        final data = widget.formData as List;
        if (data.length < additionalItems.length) {
          data.add(null);
        }

        initialItems.add(
          widget.buildJsonschemaForm(
            additionalItems[i],
            widget.jsonKey,
            widget.uiSchema,
            widget.formData,
            arrayIndex: i + initialItemsLength,
          ),
        );
      }
    }

    /// if the [jsonSchema] has the [uniqueItems] property then this form will
    /// be considered a multiple choice list and the [enum] value from items
    /// must not be null as they will be the possible choices

    initialItemsLength = initialItems.length;

    if (widget.jsonSchema.uniqueItems ?? false) {
      final schemaFromItems = widget.jsonSchema.items as JsonSchema;
      if (schemaFromItems.enumValue != null) {
        (widget.formData as List).add(null);

        initialItems.add(
          widget.buildJsonschemaForm(
            schemaFromItems,
            widget.jsonKey,
            widget.uiSchema,
            widget.formData,
            arrayIndex: initialItemsLength - 1,
          ),
        );
      }
    }

    /// if the [jsonSchema] has the [minItems] property then [items] will be
    /// added at first and user can't remove them

    minItems = widget.jsonSchema.minItems ?? 0;

    initialItemsLength = initialItems.length;

    for (var i = 0; i < minItems; i++) {
      final data = widget.formData as List;
      if (data.length < minItems) {
        data.add(null);
      }

      initialItems.add(
        widget.buildJsonschemaForm(
          widget.jsonSchema.items as JsonSchema,
          widget.jsonKey,
          widget.uiSchema,
          widget.formData,
          arrayIndex: i + (initialItemsLength - 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...initialItems,
        ..._buildArrayItems(),
      ],
    );
  }

  List<Widget> _buildArrayItems() {
    final items = <Widget>[];

    /// Builds items that user has added using (+) button from the form
    /// They can be removed if [removable] is not present or is set to false
    /// in the corresponding [uiSchema] property

    for (var i = 0; i < _arrayItems.length; i++) {
      final hasRemoveButton = widget.uiSchema?.options == null ||
          (widget.uiSchema!.options!.containsKey(UiOptions.removable.name) &&
              widget.uiSchema!.options![UiOptions.removable.name] is bool &&
              (widget.uiSchema!.options![UiOptions.removable.name] as bool));

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

      final newFormData = widget.formData is List<Map<String, dynamic>>
          ? (widget.formData as List)[i]
          : widget.formData;

      items.add(
        widget.buildJsonschemaForm(
          _arrayItems[i],
          widget.jsonSchema.areItemsNonObjects() ? widget.jsonKey : null,
          widget.uiSchema,
          newFormData,
          arrayIndex: i + (initialItems.length - 1),
        ),
      );
    }

    /// The (+) button is added by default unless [addable] is
    /// provided to the corresponding [uiSchema] property and set to false
    /// If [maxItems] property specified in [jsonSchema] and the array
    /// has reached [maxItems] then (+) is not added

    final isMaxReached = widget.jsonSchema.maxItems != null &&
        _arrayItems.length + minItems >= widget.jsonSchema.maxItems!;

    final hasAddButton = widget.uiSchema?.options == null ||
        (widget.uiSchema!.options!.containsKey(UiOptions.addable.name) &&
            widget.uiSchema!.options![UiOptions.addable.name] is bool &&
            (widget.uiSchema!.options![UiOptions.addable.name] as bool));

    if (hasAddButton && !isMaxReached) {
      final addButton = Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          onPressed: () {
            if (widget.formData is List<Map<String, dynamic>>) {
              (widget.formData as List<Map<String, dynamic>>)
                  .add(<String, dynamic>{});
            } else if (widget.formData is List) {
              (widget.formData as List).add(
                widget.jsonSchema.areItemsNonObjects()
                    ? null
                    : <String, dynamic>{},
              );
            }

            if (hasAdditionalItems) {
              _addArrayItem(widget.jsonSchema.additionalItems!);
            } else {
              _addArrayItem(widget.jsonSchema.items as JsonSchema);
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
    if (widget.formData is List) {
      (widget.formData as List).removeAt(index + (initialItems.length - 1));
    }

    _arrayItems.removeAt(index);

    setState(() {});
  }
}
