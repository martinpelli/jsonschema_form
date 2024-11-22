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
  final _arrayItems = <JsonSchema>[];

  late final bool hasAdditionalItems;

  final _initialItems = <Widget>[];

  late final int minItems;

  @override
  void initState() {
    super.initState();

    hasAdditionalItems = widget.jsonSchema.additionalItems != null;

    if (widget.jsonSchema.title?.isNotEmpty ?? false) {
      _initialItems.add(
        Text(widget.jsonSchema.title!),
      );
    }

    var initialItemsLength = _initialItems.length;

    /// If [additionalItems] property from the corresponding [jsonSchema] is
    /// present then the user is allowed to add additional items for the given
    /// [jsonSchema]
    var additionalItemsLength = 0;
    if (hasAdditionalItems) {
      final additionalItems = widget.jsonSchema.items as List<JsonSchema>;
      additionalItemsLength = additionalItems.length;
      for (var i = 0; i < additionalItems.length; i++) {
        final data = widget.formData as List;
        if (data.length < additionalItems.length) {
          data.add(null);
        }

        _initialItems.add(
          widget.buildJsonschemaForm(
            additionalItems[i],
            widget.jsonKey,
            widget.uiSchema,
            widget.formData,
            arrayIndex: i + initialItemsLength - 1,
          ),
        );
      }
    }

    initialItemsLength = _initialItems.length;

    /// if the [jsonSchema] has the [uniqueItems] property then this form will
    /// be considered a multiple choice list and the [enum] value from items
    /// must not be null as they will be the possible choices
    if (widget.jsonSchema.uniqueItems ?? false) {
      final schemaFromItems = widget.jsonSchema.items as JsonSchema;
      if (schemaFromItems.enumValue != null) {
        (widget.formData as List).add(null);

        _initialItems.add(
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

    initialItemsLength = _initialItems.length;

    for (var i = 0; i < minItems; i++) {
      final data = widget.formData as List;
      if (data.length < minItems) {
        data.add(null);
      }
      _initialItems.add(
        widget.buildJsonschemaForm(
          widget.jsonSchema.items as JsonSchema,
          widget.jsonKey,
          widget.uiSchema,
          widget.formData,
          arrayIndex: i + (initialItemsLength - 1),
        ),
      );
    }

    initialItemsLength = _initialItems.length;

    /// If there is initial data in [formData] then each item is added to the
    /// array and filled with corresponding values
    if (widget.formData is List) {
      final data = widget.formData as List;
      for (var i = minItems + additionalItemsLength; i < data.length; i++) {
        _arrayItems.add(
          hasAdditionalItems
              ? widget.jsonSchema.additionalItems!
              : widget.jsonSchema.items as JsonSchema,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._initialItems,
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
      _addRemoveButtonIfNeeded(items, () {
        if (widget.formData is List) {
          (widget.formData as List).removeAt(i + (_initialItems.length - 1));
        }

        _arrayItems.removeAt(i);
      });

      final castedListOfMaps = DynamicUtils.tryParseListOfMaps(widget.formData);

      final newFormData =
          castedListOfMaps != null ? castedListOfMaps[i] : widget.formData;

      items.add(
        widget.buildJsonschemaForm(
          _arrayItems[i],
          DynamicUtils.isLitOfMaps(widget.jsonSchema.items)
              ? null
              : widget.jsonKey,
          widget.uiSchema,
          newFormData,
          arrayIndex: i + (_initialItems.length - 1),
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
            _modifyFormData();

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

  void _modifyFormData() {
    final castedListOfMaps = DynamicUtils.tryParseListOfMaps(widget.formData);
    if (castedListOfMaps != null) {
      castedListOfMaps.add(<String, dynamic>{});
    } else if (widget.formData is List) {
      (widget.formData as List).add(
        DynamicUtils.isLitOfMaps(widget.jsonSchema.items)
            ? <String, dynamic>{}
            : null,
      );
    }
  }

  void _addRemoveButtonIfNeeded(
    List<Widget> items,
    VoidCallback onRemovePressed,
  ) {
    final hasRemoveButton = widget.uiSchema?.options == null ||
        (widget.uiSchema!.options!.containsKey(UiOptions.removable.name) &&
            widget.uiSchema!.options![UiOptions.removable.name] is bool &&
            (widget.uiSchema!.options![UiOptions.removable.name] as bool));

    if (hasRemoveButton) {
      final removeButton = Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          onPressed: () {
            onRemovePressed();

            setState(() {});
          },
          icon: const Icon(Icons.remove),
        ),
      );
      items.add(removeButton);
    }
  }

  void _addArrayItem(JsonSchema jsonSchema) {
    _arrayItems.add(jsonSchema);
    setState(() {});
  }
}
