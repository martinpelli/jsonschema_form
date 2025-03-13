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
    required this.isNewRoute,
    required this.buildJsonschemaForm,
    required this.getReadOnly,
    required this.getIsRequired,
    required this.onItemAdded,
    required this.onItemRemoved,
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
  final bool isNewRoute;
  final BuildJsonschemaForm buildJsonschemaForm;
  final bool Function() getReadOnly;
  final bool Function() getIsRequired;
  final void Function(JsonSchema)? onItemAdded;
  final void Function()? onItemRemoved;
  final void Function()? scrollToBottom;
  final List<GlobalKey<FormFieldState<dynamic>>>? formFieldKeys;

  @override
  State<_ArrayForm> createState() => _ArrayFormState();
}

class _ArrayFormState extends State<_ArrayForm> {
  late final GlobalKey<FormFieldState<dynamic>>? _formFieldKey;

  final List<JsonSchema> _arrayItems = [];

  final List<Widget> _initialItems = [];

  final List<ExpansionTileController> _expansionTileControllers = [];

  late final bool isExpandable;

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

    /// If [isExpandable] is true because is set to tre in its corresponding
    /// ui:option then a controller needs to be added for each item in order to
    /// expand or collapse a single item at a time
    isExpandable = (widget.uiSchema?.children?['items']
            ?.options?[UiOptions.expandable.name] as bool?) ??
        false;

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
            previousSchema: widget.previousSchema,
            previousJsonKey: widget.previousJsonKey,
            previousUiSchema: widget.previousUiSchema,
            arrayIndex: i + initialItemsLength,
            isNewRoute: widget.isNewRoute,
          ),
        );

        if (isExpandable) {
          _expansionTileControllers.add(ExpansionTileController());
        }
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
            previousSchema: widget.previousSchema,
            previousJsonKey: widget.previousJsonKey,
            previousUiSchema: widget.previousUiSchema,
            arrayIndex: initialItemsLength,
            isNewRoute: widget.isNewRoute,
          ),
        );

        if (isExpandable) {
          _expansionTileControllers.add(ExpansionTileController());
        }
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
          previousSchema: widget.previousSchema,
          previousJsonKey: widget.previousJsonKey,
          previousUiSchema: widget.previousUiSchema,
          arrayIndex: i + initialItemsLength,
          isNewRoute: widget.isNewRoute,
        ),
      );

      if (isExpandable) {
        _expansionTileControllers.add(ExpansionTileController());
      }
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
        if (isExpandable) {
          _expansionTileControllers.add(ExpansionTileController());
        }
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

    final listOfMapsCastedFormData =
        DynamicUtils.tryParseListOfMaps(widget.formData);

    final hasRemoveButton = !isExpandable &&
        (widget.uiSchema?.options == null ||
            (widget.uiSchema!.options!.containsKey(UiOptions.removable.name) &&
                widget.uiSchema!.options![UiOptions.removable.name] is bool &&
                (widget.uiSchema!.options![UiOptions.removable.name] as bool)));

    final editArrayItemAs = (widget.uiSchema?.children?['items']
            ?.options?[UiOptions.editArrayItemAs.name] as String?) ??
        ArrayItemAs.dialog.name;

    /// Builds items that user has added using (+) button from the form
    /// They can be removed if [removable] is not present or is set to false
    /// in the corresponding [uiSchema] property
    for (var i = 0; i < _arrayItems.length; i++) {
      void onRemovePressed() {
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

        setState(() {});

        widget.onItemRemoved?.call();
      }

      final newFormData = listOfMapsCastedFormData != null
          ? listOfMapsCastedFormData[i]
          : widget.formData;

      // TODO(qaysdwekat): convert this Row to a Stack to take full width.
      final newFormWidget = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _createNewFormWidget(
              _arrayItems[i],
              newFormData,
              i,
              false,
            ),
          ),
          if (hasRemoveButton)
            SizedBox(
              child: widget.getReadOnly()
                  ? null
                  : IconButton(
                      onPressed: onRemovePressed,
                      icon: const Icon(Icons.delete),
                    ),
            ),
        ],
      );

      if (isExpandable) {
        Future<void> onEditPressed() async {
          final hasAdditionalItems = widget.jsonSchema.additionalItems != null;

          final JsonSchema newJsonSchema;
          if (hasAdditionalItems) {
            newJsonSchema = widget.jsonSchema.additionalItems!;
          } else {
            newJsonSchema = widget.jsonSchema.items as JsonSchema;
          }

          final listOfMapsCastedFormData =
              DynamicUtils.tryParseListOfMaps(widget.formData);

          dynamic oldFormData;

          if (listOfMapsCastedFormData != null) {
            oldFormData = listOfMapsCastedFormData[i].deepCopy();
          } else {
            oldFormData = widget.formData;
          }

          var isItemEdited = false;

          if (editArrayItemAs == ArrayItemAs.dialog.name) {
            isItemEdited = await _createNewRoute(
              newJsonSchema,
              newFormData,
              isDialog: true,
            );
          } else {
            isItemEdited = await _createNewRoute(
              newJsonSchema,
              newFormData,
              isDialog: false,
            );
          }

          if (!isItemEdited) {
            if (listOfMapsCastedFormData != null) {
              (widget.formData as List<Map<String, dynamic>>)[i] =
                  oldFormData as Map<String, dynamic>;
            } else {
              oldFormData = widget.formData;
            }
          }
          setState(() {});
        }

        final expandedNewFormWidget = _buildExpansionTile(
          i,
          '${widget.jsonSchema.title}-${i + 1}',
          newFormWidget,
          editArrayItemAs == ArrayItemAs.inner.name ? null : onEditPressed,
          onRemovePressed,
        );

        items.add(expandedNewFormWidget);
      } else {
        items.add(newFormWidget);
      }
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
        (widget.uiSchema!.options!.containsKey(
              UiOptions.addable.name,
            ) &&
            widget.uiSchema!.options![UiOptions.addable.name] is bool &&
            (widget.uiSchema!.options![UiOptions.addable.name] as bool));

    final actionTitle = (widget.uiSchema?.options?.containsKey(
              UiOptions.addableText.name,
            ) ??
            false)
        ? (widget.uiSchema!.options![UiOptions.addableText.name] as String)
        : null;

    final actionAlignment = (widget.uiSchema?.options?.containsKey(
              UiOptions.addableAlignment.name,
            ) ??
            false)
        ? (widget.uiSchema!.options![UiOptions.addableAlignment.name] as String)
        : null;

    if (hasAddButton && !isMaxReached) {
      final addButton = Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        child: Align(
          alignment: actionAlignment.getAlignment(),
          child: actionTitle != null
              ? ElevatedButton(
                  onPressed: widget.getReadOnly()
                      ? null
                      : () => onAddPressed(
                            field,
                            isExpandable: isExpandable,
                          ),
                  child: Text(actionTitle),
                )
              : IconButton(
                  onPressed: widget.getReadOnly()
                      ? null
                      : () => onAddPressed(
                            field,
                            isExpandable: isExpandable,
                          ),
                  icon: const Icon(Icons.add),
                ),
        ),
      );

      items.add(addButton);
    }

    return items;
  }

  Future<void> onAddPressed(
    FormFieldState<bool>? field, {
    required bool isExpandable,
  }) async {
    final hasAdditionalItems = widget.jsonSchema.additionalItems != null;

    final JsonSchema newJsonSchema;
    if (hasAdditionalItems) {
      newJsonSchema = widget.jsonSchema.additionalItems!;
    } else {
      newJsonSchema = widget.jsonSchema.items as JsonSchema;
    }

    final listOfMapsCastedFormData =
        DynamicUtils.tryParseListOfMaps(widget.formData);

    if (listOfMapsCastedFormData != null) {
      listOfMapsCastedFormData.add(<String, dynamic>{});
    } else if (widget.formData is List) {
      (widget.formData as List).add(
        DynamicUtils.isListOfMaps(widget.jsonSchema.items)
            ? <String, dynamic>{}
            : null,
      );
    }

    final newFormData = listOfMapsCastedFormData != null
        ? listOfMapsCastedFormData[_arrayItems.length]
        : widget.formData;

    final createArrayItemAs = (widget.uiSchema?.children?['items']
            ?.options?[UiOptions.createArrayItemAs.name] as String?) ??
        ArrayItemAs.inner.name;

    var isItemAdded = false;

    if (createArrayItemAs == ArrayItemAs.inner.name) {
      isItemAdded = true;
    } else if (createArrayItemAs == ArrayItemAs.dialog.name) {
      isItemAdded = await _createNewRoute(
        newJsonSchema,
        newFormData,
        isDialog: true,
      );
    } else if (createArrayItemAs == ArrayItemAs.screen.name) {
      isItemAdded = await _createNewRoute(
        newJsonSchema,
        newFormData,
        isDialog: false,
      );
    }

    if (isItemAdded) {
      if (isExpandable) {
        _expansionTileControllers.add(ExpansionTileController());
      }

      _arrayItems.add(newJsonSchema);

      /// If the array has a required validator, then when there
      /// is an item added by the user, we will let the validator
      /// known that is valid because user added an item
      if (_arrayItems.length > _initialItems.length) {
        field?.didChange(true);
      }

      setState(() {});

      widget.onItemAdded?.call(newJsonSchema);
      widget.scrollToBottom?.call();
    } else {
      if (newFormData is List) {
        newFormData.removeAt(_arrayItems.length + _initialItems.length);
      }
    }
  }

  Future<bool> _createNewRoute(
    JsonSchema newJsonSchema,
    dynamic newFormData, {
    required bool isDialog,
  }) async {
    final formKey = GlobalKey<FormState>();
    final newFormWidget = Form(
      key: formKey,
      child: _createNewFormWidget(
        newJsonSchema,
        newFormData,
        _arrayItems.length,
        true,
      ),
    );

    final bool? isFormDataAdded;

    final addButon = TextButton(
      onPressed: () {
        final isFormValid = formKey.currentState?.validate() ?? false;

        if (isFormValid) {
          Navigator.of(context).pop(true);
        }
      },
      child: const Text('Confirm'),
    );

    if (isDialog) {
      isFormDataAdded = await showDialog<bool?>(
        context: context,
        builder: (_) => AlertDialog(
          scrollable: true,
          icon: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
              ),
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          iconPadding: const EdgeInsets.only(right: 10, top: 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          content: newFormWidget,
          actions: [addButon],
        ),
      );
    } else {
      isFormDataAdded = await Navigator.of(context).push<bool?>(
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

    return isFormDataAdded != null && isFormDataAdded;
  }

  Widget _createNewFormWidget(
    JsonSchema newJsonSchema,
    dynamic newFormData,
    int index,
    bool isNewRoute,
  ) {
    final listOfMapsCastedFormData =
        DynamicUtils.tryParseListOfMaps(widget.formData);

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
      listOfMapsCastedFormData != null ? null : widget.jsonKey,
      uiSchema,
      newFormData,
      arrayIndex: index + _initialItems.length,
      previousSchema: widget.jsonSchema,
      previousJsonKey:
          listOfMapsCastedFormData != null ? null : widget.previousJsonKey,
      previousUiSchema: previousUiSchema,
      isNewRoute: isNewRoute,
    );
  }

  Widget _buildExpansionTile(
    int index,
    String title,
    Widget newFormWidget,
    void Function()? onEditPressed,
    void Function() onRemovePressed,
  ) {
    return ExpansionTile(
      controller: _expansionTileControllers[index],
      onExpansionChanged: (isExpanded) {
        if (isExpanded) {
          for (var i = 0; i < _expansionTileControllers.length; i++) {
            if (i != index) {
              _expansionTileControllers[i].collapse();
            }
          }
        }
      },
      shape: const OutlineInputBorder(borderSide: BorderSide.none),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      trailing: (onEditPressed == null)
          ? IconButton(
              onPressed: onRemovePressed,
              icon: const Icon(Icons.delete),
            )
          : PopupMenuButton(
              icon: const Icon(Icons.more_vert_outlined),
              padding: EdgeInsets.zero,
              menuPadding: EdgeInsets.zero,
              itemBuilder: (context) {
                return [
                  PopupMenuItem<int>(
                    onTap: onEditPressed,
                    child: const Text('Edit'),
                  ),
                  PopupMenuItem<int>(
                    onTap: onRemovePressed,
                    child: const Text('Delete'),
                  ),
                ];
              },
            ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      children: [const Divider(), newFormWidget],
    );
  }
}
