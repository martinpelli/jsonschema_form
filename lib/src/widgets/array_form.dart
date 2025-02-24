part of '../jsonschema_form_builder.dart';

class _ArrayForm extends StatefulWidget {
  const _ArrayForm({
    required this.jsonSchema,
    required this.jsonKey,
    required this.uiSchema,
    required this.formData,
    required this.previousSchema,
    required this.previousJsonKey,
    required this.previousUiSchema,
    required this.buildJsonschemaForm,
    required this.getReadOnly,
    required this.getIsRequired,
    required this.onItemAdded,
    required this.onItemRemoved,
    required this.createArrayItemAs,
    required this.scrollToBottom,
    required this.formFieldKeys,
  });

  final JsonSchema jsonSchema;
  final String? jsonKey;
  final UiSchema? uiSchema;
  final dynamic formData;
  final String? previousJsonKey;
  final JsonSchema? previousSchema;
  final UiSchema? previousUiSchema;
  final BuildJsonschemaForm buildJsonschemaForm;
  final bool Function() getReadOnly;
  final bool Function() getIsRequired;
  final void Function(JsonSchema)? onItemAdded;
  final void Function()? onItemRemoved;
  final CreateArrayItemAs createArrayItemAs;
  final void Function()? scrollToBottom;
  final List<GlobalKey<FormFieldState<dynamic>>>? formFieldKeys;

  @override
  State<_ArrayForm> createState() => _ArrayFormState();
}

class _ArrayFormState extends State<_ArrayForm> {
  late final GlobalKey<FormFieldState<dynamic>>? _formFieldKey;

  final List<JsonSchema> _arrayItems = [];

  final List<Widget> _initialItems = [];

  @override
  void initState() {
    super.initState();

    if (widget.formFieldKeys != null) {
      _formFieldKey = GlobalKey<FormFieldState<dynamic>>();
      widget.formFieldKeys!.add(_formFieldKey!);
    } else {
      _formFieldKey = null;
    }

    _initItems();
  }

  @override
  void dispose() {
    widget.formFieldKeys?.removeLast();
    super.dispose();
  }

  void _initItems() {
    var initialItemsLength = _initialItems.length;

    /// If [additionalItems] property from the corresponding [jsonSchema] is
    /// present then the user is allowed to add additional items for the given
    /// [jsonSchema]
    var additionalItemsLength = 0;

    final hasAdditionalItems = widget.jsonSchema.additionalItems != null;

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
            arrayIndex: i + initialItemsLength,
            previousSchema: widget.previousSchema,
            previousJsonKey: widget.previousJsonKey,
            previousUiSchema: widget.previousUiSchema,
          ),
        );
      }
    }

    initialItemsLength = _initialItems.length;

    /// if the [jsonSchema] has the [uniqueItems] property then this form will
    /// be considered a multiple choice list and the [enum] value from items
    /// must not be null as they will be the possible choices

    final hasUniqueItems = widget.jsonSchema.uniqueItems ?? false;

    if (hasUniqueItems) {
      final schemaFromItems = widget.jsonSchema.items as JsonSchema;
      if (schemaFromItems.enumValue != null) {
        _initialItems.add(
          widget.buildJsonschemaForm(
            schemaFromItems,
            widget.jsonKey,
            widget.uiSchema,
            widget.formData,
            arrayIndex: initialItemsLength,
            previousSchema: widget.previousSchema,
            previousJsonKey: widget.previousJsonKey,
            previousUiSchema: widget.previousUiSchema,
          ),
        );
      }
    }

    /// if the [jsonSchema] has the [minItems] property then [items] will be
    /// added at first and user can't remove them
    final minItems = widget.jsonSchema.minItems ?? 0;

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
          arrayIndex: i + initialItemsLength,
          previousSchema: widget.previousSchema,
          previousJsonKey: widget.previousJsonKey,
          previousUiSchema: widget.previousUiSchema,
        ),
      );
    }

    initialItemsLength = _initialItems.length;

    /// If there is initial data in [formData] then each item is added to the
    /// array and filled with corresponding values
    if (widget.formData is List && !hasUniqueItems) {
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
    return _CustomFormFieldValidator<bool>(
      formFieldKey: _formFieldKey,
      isEnabled: widget.getIsRequired(),
      initialValue: _arrayItems.length == _initialItems.length ? null : true,
      childFormBuilder: (field) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._initialItems,
            ..._buildArrayItems(field),
          ],
        );
      },
    );
  }

  List<Widget> _buildArrayItems(FormFieldState<bool>? field) {
    final items = <Widget>[];

    /// Builds items that user has added using (+) button from the form
    /// They can be removed if [removable] is not present or is set to false
    /// in the corresponding [uiSchema] property
    for (var i = 0; i < _arrayItems.length; i++) {
      _addRemoveButtonIfNeeded(items, () {
        if (widget.formData is List) {
          (widget.formData as List).removeAt(i + _initialItems.length);
        }

        _arrayItems.removeAt(i);

        /// If the array has a required validator, then when there is a removed
        /// item by the user, we let the validator knows that is invalid if
        /// there are no more items added by the user
        if (_arrayItems.length == _initialItems.length) {
          field?.didChange(null);
        }
      });

      final listOfMapsCastedFormData =
          DynamicUtils.tryParseListOfMaps(widget.formData);

      final newFormData = listOfMapsCastedFormData != null
          ? listOfMapsCastedFormData[i]
          : widget.formData;

      final newFormWidget = _createNewFormWidget(
        listOfMapsCastedFormData,
        _arrayItems[i],
        newFormData,
        i,
      );

      items.add(newFormWidget);
    }

    /// The (+) button is added by default unless [addable] is
    /// provided to the corresponding [uiSchema] property and set to false
    /// If [maxItems] property specified in [jsonSchema] and the array
    /// has reached [maxItems] then (+) is not added
    /// final hasAdditionalItems = widget.jsonSchema.additionalItems != null;
    final minItems = widget.jsonSchema.minItems ?? 0;

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
          onPressed: widget.getReadOnly()
              ? null
              : () async {
                  final hasAdditionalItems =
                      widget.jsonSchema.additionalItems != null;

                  final JsonSchema newJsonSchema;
                  if (hasAdditionalItems) {
                    newJsonSchema = widget.jsonSchema.additionalItems!;
                  } else {
                    newJsonSchema = widget.jsonSchema.items as JsonSchema;
                  }

                  var isItemNotAdded = false;

                  switch (widget.createArrayItemAs) {
                    case CreateArrayItemAs.inside:
                      _modifyFormData();
                      _addArrayItem(newJsonSchema);

                    case CreateArrayItemAs.dialog:
                      isItemNotAdded =
                          await _createNewView(newJsonSchema, isDialog: true);

                    case CreateArrayItemAs.screen:
                      isItemNotAdded =
                          await _createNewView(newJsonSchema, isDialog: false);
                  }

                  if (isItemNotAdded) {
                    return;
                  }

                  /// If the array has a required validator, then when there is
                  /// an item added by the user, we will let the validator known
                  /// that is valid because user added an item
                  if (_arrayItems.length > _initialItems.length) {
                    field?.didChange(true);
                  }

                  widget.onItemAdded?.call(newJsonSchema);
                  widget.scrollToBottom?.call();
                },
          icon: const Icon(Icons.add),
        ),
      );

      items.add(addButton);
    }

    return items;
  }

  Future<bool> _createNewView(
    JsonSchema newJsonSchema, {
    required bool isDialog,
  }) async {
    final listOfMapsCastedFormData =
        DynamicUtils.tryParseListOfMaps(widget.formData);

    _modifyFormData();

    final newFormData = listOfMapsCastedFormData != null
        ? listOfMapsCastedFormData[_arrayItems.length]
        : widget.formData;

    final newFormWidget = _createNewFormWidget(
      listOfMapsCastedFormData,
      newJsonSchema,
      newFormData,
      _arrayItems.length,
    );

    final dynamic addedFormData;

    final addButon = TextButton(
      onPressed: () => Navigator.of(context).pop(newFormData),
      child: const Text('Add'),
    );

    if (isDialog) {
      addedFormData = await showDialog<dynamic>(
        context: context,
        builder: (_) => AlertDialog(
          scrollable: true,
          content: newFormWidget,
          actions: [addButon],
        ),
      );
    } else {
      addedFormData = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: newFormWidget,
              ),
            ),
            bottomNavigationBar: addButon,
          ),
        ),
      );
    }

    if (addedFormData != null) {
      _addArrayItem(newJsonSchema);
      return false;
    } else {
      if (widget.formData is List) {
        (widget.formData as List)
            .removeAt(_arrayItems.length + _initialItems.length);
      }
      return true;
    }
  }

  Widget _createNewFormWidget(
    List<Map<String, dynamic>>? listOfMapsCastedFormData,
    JsonSchema newJsonSchema,
    dynamic newFormData,
    int index,
  ) {
    final uiSchema = listOfMapsCastedFormData != null
        ? (widget.uiSchema?.children != null &&
                widget.uiSchema!.children!.containsKey('items'))
            ? widget.uiSchema!.children!['items']
            : null
        : widget.uiSchema;

    final previousUiSchema = listOfMapsCastedFormData != null
        ? (widget.uiSchema?.children != null &&
                widget.uiSchema!.children!.containsKey('items'))
            ? widget.uiSchema
            : null
        : widget.previousUiSchema;

    return widget.buildJsonschemaForm(
      newJsonSchema,
      listOfMapsCastedFormData != null ? widget.jsonKey : null,
      uiSchema,
      newFormData,
      arrayIndex: index + _initialItems.length,
      previousSchema: widget.jsonSchema,
      previousJsonKey:
          listOfMapsCastedFormData != null ? widget.previousJsonKey : null,
      previousUiSchema: previousUiSchema,
    );
  }

  void _modifyFormData() {
    final castedListOfMaps = DynamicUtils.tryParseListOfMaps(widget.formData);
    if (castedListOfMaps != null) {
      castedListOfMaps.add(<String, dynamic>{});
    } else if (widget.formData is List) {
      (widget.formData as List).add(
        DynamicUtils.isListOfMaps(widget.jsonSchema.items)
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
        child: widget.getReadOnly()
            ? null
            : IconButton(
                onPressed: () {
                  onRemovePressed();

                  setState(() {});

                  widget.onItemRemoved?.call();
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
