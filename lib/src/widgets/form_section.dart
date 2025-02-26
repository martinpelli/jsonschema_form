part of '../jsonschema_form_builder.dart';

class _FormSection extends StatelessWidget {
  const _FormSection(
    this.jsonSchema,
    this.jsonKey,
    this.uiSchema,
    this.formData, {
    required this.prefixFormDataMapper,
    required this.buildJsonschemaForm,
    required this.previousSchema,
    required this.previousJsonKey,
    required this.previousUiSchema,
    required this.arrayIndex,
    required this.onArrayItemAdded,
    required this.onArrayItemRemoved,
    required this.rebuildDependencies,
    required this.isWholeFormReadOnly,
    required this.scrollToBottom,
    required this.formFieldKeys,
    required this.isNewRoute,
  });

  final JsonSchema jsonSchema;
  final String? jsonKey;
  final UiSchema? uiSchema;
  final dynamic formData;
  final dynamic Function(String, dynamic)? prefixFormDataMapper;
  final BuildJsonschemaForm buildJsonschemaForm;
  final JsonSchema? previousSchema;
  final String? previousJsonKey;
  final UiSchema? previousUiSchema;
  final int? arrayIndex;
  final void Function()? onArrayItemRemoved;
  final void Function(JsonSchema)? onArrayItemAdded;
  final void Function(BuildContext contest, String)? rebuildDependencies;
  final bool isWholeFormReadOnly;
  final void Function()? scrollToBottom;
  final List<GlobalKey<FormFieldState<dynamic>>>? formFieldKeys;
  final bool isNewRoute;

  @override
  Widget build(BuildContext context) {
    final (newFormData, previousFormData) = _modifyFormData(
      jsonSchema,
      jsonKey,
      formData,
    );

    final mergedJsonSchema =
        _mergeDependencies(jsonSchema, newFormData) ?? jsonSchema;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mergedJsonSchema.type == JsonType.object ||
            mergedJsonSchema.type == JsonType.array) ...[
          ...(() {
            final widgets = <Widget>[];

            final title = _getTitle(
              jsonKey,
              mergedJsonSchema,
              uiSchema,
              previousSchema,
              previousUiSchema,
              arrayIndex,
            );

            if (title != null && !(mergedJsonSchema.uniqueItems ?? false)) {
              final isRequired = _getIsRequired(
                jsonKey,
                previousSchema,
                arrayIndex,
                previousFormData,
              );

              widgets.addAll([
                Text(
                  title + (isRequired ? '*' : ''),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Divider(),
                const SizedBox(height: 10),
              ]);
            }

            final description = _getDescription(
              jsonKey,
              mergedJsonSchema,
              uiSchema,
            );

            if (description != null) {
              widgets.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(description),
                ),
              );
            }

            return widgets;
          })(),
        ],
        if (mergedJsonSchema.type == null ||
            mergedJsonSchema.type == JsonType.object) ...[
          if (uiSchema?.order == null)
            for (final entry in mergedJsonSchema.properties?.entries ??
                <MapEntry<String, JsonSchema>>[])
              ..._buildObjectEntries(
                entry,
                jsonKey,
                mergedJsonSchema,
                uiSchema,
                arrayIndex,
                isNewRoute,
                newFormData,
              )
          else
            ..._buildOrderedObjectEntries(
              jsonKey,
              mergedJsonSchema,
              uiSchema,
              arrayIndex,
              isNewRoute,
              newFormData,
            ),
          if (mergedJsonSchema.oneOf != null)
            _OneOfForm(
              mergedJsonSchema,
              jsonKey,
              uiSchema,
              newFormData as Map<String, dynamic>,
              previousSchema: previousSchema,
              previousJsonKey: previousJsonKey,
              previousUiSchema: previousUiSchema,
              buildJsonschemaForm: buildJsonschemaForm,
              arrayIndex: arrayIndex,
              isNewRoute: isNewRoute,
              getTitle: () => _getTitle(
                jsonKey,
                mergedJsonSchema,
                uiSchema,
                previousSchema,
                previousUiSchema,
                arrayIndex,
              ),
              getDescription: () => _getDescription(
                jsonKey,
                mergedJsonSchema,
                uiSchema,
              ),
              getReadOnly: () => _getReadOnly(
                jsonKey,
                mergedJsonSchema,
                uiSchema,
                previousUiSchema,
              ),
            ),
        ] else if (mergedJsonSchema.type == JsonType.array)
          _ArrayForm(
            jsonSchema: mergedJsonSchema,
            jsonKey: jsonKey,
            uiSchema: uiSchema,
            formData: newFormData,
            previousJsonKey: previousJsonKey,
            previousSchema: previousSchema,
            previousUiSchema: previousUiSchema,
            isNewRoute: isNewRoute,
            buildJsonschemaForm: buildJsonschemaForm,
            getReadOnly: () => _getReadOnly(
              jsonKey,
              mergedJsonSchema,
              uiSchema,
              previousUiSchema,
            ),
            getIsRequired: () => _getIsRequired(
              jsonKey,
              previousSchema,
              arrayIndex,
              previousFormData,
            ),
            onItemAdded: onArrayItemAdded,
            onItemRemoved: onArrayItemRemoved,
            scrollToBottom: scrollToBottom,
            formFieldKeys: formFieldKeys,
          )
        else
          _UiWidget(
            mergedJsonSchema,
            jsonKey,
            uiSchema,
            formData,
            rebuildDependencies: rebuildDependencies,
            previousSchema: previousSchema,
            previousJsonKey: previousJsonKey,
            previousFormData: previousFormData,
            arrayIndex: arrayIndex,
            getTitle: () => _getTitle(
              jsonKey,
              mergedJsonSchema,
              uiSchema,
              previousSchema,
              previousUiSchema,
              arrayIndex,
            ),
            getDescription: () => _getDescription(
              jsonKey,
              mergedJsonSchema,
              uiSchema,
            ),
            getDefaultValue: () => _getDefaultValue(
              jsonKey,
              mergedJsonSchema,
              formData,
              previousSchema,
              arrayIndex,
            ),
            getIsRequired: () => _getIsRequired(
              jsonKey,
              previousSchema,
              arrayIndex,
              previousFormData,
            ),
            getReadOnly: () => _getReadOnly(
              jsonKey,
              mergedJsonSchema,
              uiSchema,
              previousUiSchema,
            ),
            formFieldKeys: formFieldKeys,
          ),
      ],
    );
  }

  /// Access the corresponding jsonKey in the formData in order to put values
  /// in the appropiated field value
  (dynamic, dynamic) _modifyFormData(
    JsonSchema jsonSchema,
    String? jsonKey,
    dynamic formData,
  ) {
    final previousFormData = formData is List
        ? List<dynamic>.from(formData)
        : Map<String, dynamic>.from(
            formData as Map<String, dynamic>,
          );

    if (jsonKey != null &&
        (jsonSchema.type == JsonType.object ||
            jsonSchema.type == JsonType.array)) {
      if (formData is Map<String, dynamic>) {
        /// If there is an empty list coming from formData (possible from an
        /// external data source) it will be removed because dart cannot detect
        /// the list type, so a new one with the correct type wil be created
        /// using putIfAbsent
        if (formData[jsonKey] is List && (formData[jsonKey] as List).isEmpty) {
          formData.remove(jsonKey);
        }

        final newFormData = formData.putIfAbsent(
          jsonKey,
          () {
            /// If the current jsonSchema is an object then it will add a new
            /// empty map to the formData. If it is a list of objects then it
            /// will add a list of maps otherwise will add a dynamic list.
            /// This new data added will be passed to the UiWidget and that
            /// widget will add entries to this new data so it will be possible
            /// to the widget to modify the appropiate property and at same time
            /// will be referencing the formData so it will be updated
            if (jsonSchema.type == JsonType.object) {
              return <String, dynamic>{};
            } else {
              if ((DynamicUtils.isListOfMaps(jsonSchema.items) ||
                      jsonSchema.items is JsonSchema) &&
                  !(jsonSchema.uniqueItems ?? false)) {
                return <Map<String, dynamic>>[];
              } else {
                return <dynamic>[];
              }
            }
          },
        );
        return (newFormData, previousFormData);
      } else if (formData is List) {
        return (formData, previousFormData);
      }
    } else {
      return (formData, previousFormData);
    }

    return (formData, previousFormData);
  }

  JsonSchema? _mergeDependencies(
    JsonSchema jsonSchema,
    dynamic formData,
  ) {
    if (jsonSchema.dependencies == null) {
      return jsonSchema;
    }

    final mergedJsonSchema = jsonSchema.dependencies!.entries.fold(jsonSchema,
        (previousValue, dependency) {
      final dependencyValue = dependency.value;

      if (dependencyValue is JsonSchema && dependencyValue.oneOf != null) {
        if (jsonSchema.properties?.keys.contains(dependency.key) ?? false) {
          if (dependencyValue.oneOf != null) {
            final dependencySchema = dependencyValue.oneOf!.firstWhereOrNull(
              (element) {
                final firstOneOfValue =
                    element.properties![dependency.key]!.enumValue?.first ??
                        element.properties![dependency.key]!.constValue;

                if (formData is Map<String, dynamic>) {
                  return firstOneOfValue == formData[dependency.key];
                } else if (formData is List<String>) {
                  return formData.contains(firstOneOfValue);
                } else {
                  return false;
                }
              },
            );

            if (dependencySchema != null) {
              return previousValue.mergeWith(dependencySchema);
            }
          }
        }
      }
      return previousValue;
    });

    return mergedJsonSchema;
  }

  List<Widget> _buildObjectEntries(
    MapEntry<String, JsonSchema> entry,
    String? jsonKey,
    JsonSchema jsonSchema,
    UiSchema? uiSchema,
    int? arrayIndex,
    bool isNewRoute,
    dynamic newFormData,
  ) {
    return [
      /// Build one Widget for each property in the schema
      buildJsonschemaForm(
        entry.value,
        entry.key,
        uiSchema?.children?[entry.key],
        newFormData,
        previousSchema: jsonSchema,
        previousJsonKey: jsonKey,
        previousUiSchema: uiSchema,
        arrayIndex: arrayIndex,
        isNewRoute: isNewRoute,
      ),

      /// Build Schema dependencies, widgets that will be added
      /// dynamically depending on other field values
      if (jsonSchema.dependencies != null &&
          jsonSchema.dependencies![entry.key] is JsonSchema &&
          jsonSchema.dependencies!.keys.contains(entry.key))

        /// This is a schema based dependency, so new fields will be added
        /// dynamically
        buildJsonschemaForm(
          jsonSchema.dependencies![entry.key] as JsonSchema,
          entry.key,
          uiSchema?.children?[entry.key],
          newFormData,
          previousSchema: jsonSchema,
          previousJsonKey: jsonKey,
          previousUiSchema: uiSchema,
          arrayIndex: arrayIndex,
          isNewRoute: isNewRoute,
        ),
    ];
  }

  /// If a field is dependant of another one then it will add a required
  /// validation if the field which depends on is filled with a valid value
  bool _isPropertyDependantAndDependencyHasValue(
    String? jsonKey,
    JsonSchema? previousSchema,
    dynamic previousFormData,
  ) {
    if (previousSchema?.dependencies != null) {
      for (final dependency in previousSchema!.dependencies!.entries) {
        /// Property dependency
        if (dependency.value is List<String>) {
          final dependencies = dependency.value as List<String>;

          if (dependencies.contains(
                jsonKey,
              ) &&
              ((previousFormData as Map<String, dynamic>?)?.containsKey(
                    dependency.key,
                  ) ??
                  false)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// This will be used to order widgets when ui:order is specified
  List<Widget> _buildOrderedObjectEntries(
    String? jsonKey,
    JsonSchema jsonSchema,
    UiSchema? uiSchema,
    int? arrayIndex,
    bool isNewRoute,
    dynamic newFormData,
  ) {
    final widgets = <Widget>[];
    const wildcard = '*';

    final orderSet = Set<String>.from(uiSchema!.order!);
    final properties = jsonSchema.properties?.entries ?? [];

    void addWidgetsForEntry(String entryKey) {
      final entry = properties.firstWhereOrNull((e) => e.key == entryKey);
      if (entry != null) {
        widgets.addAll(
          _buildObjectEntries(
            entry,
            jsonKey,
            jsonSchema,
            uiSchema,
            arrayIndex,
            isNewRoute,
            newFormData,
          ),
        );
      }
    }

    for (final orderKey in uiSchema.order!) {
      if (orderKey == wildcard) {
        final itemsNotInOrder =
            properties.map((e) => e.key).toSet().difference(orderSet);

        for (final wildcardItemKey in itemsNotInOrder) {
          addWidgetsForEntry(wildcardItemKey);
        }
      } else {
        addWidgetsForEntry(orderKey);
      }
    }

    return widgets;
  }

  dynamic _getDefaultValue(
    String? jsonKey,
    JsonSchema jsonSchema,
    dynamic formData,
    JsonSchema? previousSchema,
    int? arrayIndex,
  ) {
    /// If the previous jsonSchema has uniqueItems it means that this is a
    /// multiple choice list, so it cannot have default values
    final hasUniqueItems = previousSchema?.uniqueItems ?? false;
    if (hasUniqueItems) {
      return null;
    }

    if (formData is Map) {
      if (formData.containsKey(jsonKey)) {
        final value = prefixFormDataMapper?.call(jsonKey!, formData[jsonKey]) ??
            formData[jsonKey]?.toString() ??
            jsonSchema.defaultValue;
        return value;
      } else {
        return jsonSchema.defaultValue;
      }
    } else if (formData is List) {
      if (arrayIndex! <= formData.length - 1) {
        final fieldData = formData[arrayIndex];
        if (fieldData is Map) {
          return fieldData[jsonKey] ?? jsonSchema.defaultValue;
        } else {
          return fieldData ?? jsonSchema.defaultValue;
        }
      } else {
        return jsonSchema.defaultValue;
      }
    }
  }

  String? _getTitle(
    String? jsonKey,
    JsonSchema jsonSchema,
    UiSchema? uiSchema,
    JsonSchema? previousSchema,
    UiSchema? previousUiSchema,
    int? arrayIndex,
  ) {
    final isExpandable =
        (uiSchema?.options?[UiOptions.expandable.name] as bool?) ?? false;
    if (isExpandable) {
      return null;
    }

    if (uiSchema?.title != null && uiSchema!.title!.isNotEmpty) {
      return uiSchema.title;
    }

    if (jsonSchema.title != null && jsonSchema.title!.isNotEmpty) {
      return jsonSchema.title;
    }

    if (arrayIndex != null && previousSchema?.title != null) {
      if (previousSchema?.uniqueItems ?? false) {
        return previousSchema?.title;
      } else if (uiSchema?.showArrayTitles ?? true) {
        final isExpandable =
            (previousUiSchema?.options?[UiOptions.expandable.name] as bool?) ??
                false;
        if (!isExpandable) {
          return '${previousSchema?.title}-${arrayIndex + 1}';
        }
      }
    }

    return null;
  }

  String? _getDescription(
    String? jsonKey,
    JsonSchema jsonSchema,
    UiSchema? uiSchema,
  ) {
    if (uiSchema?.description != null && uiSchema!.description!.isNotEmpty) {
      return uiSchema.description;
    }
    if (jsonSchema.description != null && jsonSchema.description!.isNotEmpty) {
      return jsonSchema.description;
    }

    return null;
  }

  bool _getReadOnly(
    String? jsonKey,
    JsonSchema jsonSchema,
    UiSchema? uiSchema,
    UiSchema? previousUiSchema,
  ) {
    final isExpandable =
        (previousUiSchema?.options?[UiOptions.expandable.name] as bool?) ??
            false;

    final isInnerEdit = ((previousUiSchema
                ?.options?[UiOptions.editArrayItemAs.name] as String?) ??
            ArrayItemAs.dialog) ==
        ArrayItemAs.inner;

    if (isWholeFormReadOnly || (isExpandable && !isInnerEdit && !isNewRoute)) {
      return true;
    }

    return jsonSchema.readOnly ?? uiSchema?.readonly ?? false;
  }

  /// The field is required if:
  /// The jsonSchema has its jsonKey in the required array
  /// It is a required item from an array with additional items
  /// It is an item index less than minItems from an array
  /// It is required by a dependency
  bool _getIsRequired(
    String? jsonKey,
    JsonSchema? previousSchema,
    int? arrayIndex,
    dynamic previousFormData,
  ) {
    final items = previousSchema?.items;
    final minItems = previousSchema?.minItems;

    final requiredFields = previousSchema?.requiredFields;

    if (requiredFields?.contains(jsonKey) ?? false) {
      return true;
    }

    if (items is List<dynamic> ||
        (minItems != null && arrayIndex! < minItems)) {
      return true;
    }

    return _isPropertyDependantAndDependencyHasValue(
      jsonKey,
      previousSchema,
      previousFormData,
    );
  }
}
