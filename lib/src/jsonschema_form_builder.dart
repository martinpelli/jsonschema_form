import 'dart:async';

import 'package:camera/camera.dart';
import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:jsonschema_form/jsonschema_form.dart';
import 'package:jsonschema_form/src/models/input_type.dart';
import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/json_schema_format.dart';
import 'package:jsonschema_form/src/models/json_type.dart';
import 'package:jsonschema_form/src/models/ui_options.dart';
import 'package:jsonschema_form/src/models/ui_schema.dart';
import 'package:jsonschema_form/src/models/ui_type.dart';
import 'package:jsonschema_form/src/screens/camera_resolution.dart';
import 'package:jsonschema_form/src/utils/dynamic_utils.dart';
import 'package:jsonschema_form/src/utils/xfile_extension.dart';
import 'package:jsonschema_form/src/widgets/file_widgets/file_preview.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:phone_form_field/phone_form_field.dart';

part 'screens/camera_screen.dart';
part 'widgets/array_form.dart';
part 'widgets/custom_checkbox_group.dart';
part 'widgets/custom_dropdown_menu.dart';
part 'widgets/custom_file_upload.dart';
part 'widgets/custom_form_field_validator.dart';
part 'widgets/custom_phone_form_field.dart';
part 'widgets/custom_radio_group.dart';
part 'widgets/custom_text_form_field.dart';
part 'widgets/one_of_form.dart';
part 'widgets/ui_widget.dart';

/// Builds a Form by decoding a Json Schema
class JsonschemaFormBuilder extends StatefulWidget {
  /// {@macro jsonschema_form_builder}
  const JsonschemaFormBuilder({
    required this.jsonSchemaForm,
    this.readOnly = false,
    this.resolution = CameraResolution.max,
    this.isScrollable = true,
    this.scrollToBottom = true,
    this.scrollToFirstError = true,
    this.onItemAdded,
    this.onItemRemoved,
    this.padding,
    super.key,
  });

  /// The json schema for the form.
  final JsonschemaForm jsonSchemaForm;

  /// Useful if the user needs to see the whole form in read only, so none field
  /// will be editable. This can be useful if you don't want to provide a
  /// ui:readonly key to each field.
  final bool readOnly;

  /// [CameraResolution] affects the quality of video recording and image
  /// capture.
  final CameraResolution resolution;

  /// If the form overflows the screen it will be automatically scrollable.
  /// Default set to true.
  final bool isScrollable;

  /// if [isScrollable] and [scrollToBottom] are true then when new fields are
  /// added to the screen and they overflow, the form will automaticallly scroll
  /// to the bottom.
  /// Default set to true.
  final bool scrollToBottom;

  /// if [isScrollable] and [scrollToFirstError] are true then when the form is
  /// validated and it overflows the screen, the form will automaticallly scroll
  /// to first error field
  /// Default set to true.
  final bool scrollToFirstError;

  /// Function called when an item is added to an array
  /// This can be useful if you want to scroll to the bottom in case the new
  /// item overflows the screen
  final void Function(JsonSchema)? onItemAdded;

  /// Function called when an item is removed from an array
  final void Function()? onItemRemoved;

  // For adding padding to the form. Useful if you have [isScrollable] set to
  // true
  final EdgeInsets? padding;

  @override
  State<JsonschemaFormBuilder> createState() => JsonschemaFormBuilderState();
}

/// The state of the [JsonschemaFormBuilder].
/// It can be accessed using a GlobalKey to [submit] the form
/// It is needed to rebuild the form when there is a conditional dependency
/// change.
/// It is also needed to hold each field key and the [ScrollController] if valid
class JsonschemaFormBuilderState extends State<JsonschemaFormBuilder> {
  final _formKey = GlobalKey<FormState>();

  final _formFieldKeys = <GlobalKey<FormFieldState<dynamic>>>[];

  late final ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();

    if (widget.isScrollable) {
      _scrollController = ScrollController();
    } else {
      _scrollController = null;
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Form(
        key: _formKey,
        child: _buildJsonschemaForm(
          widget.jsonSchemaForm.jsonSchema!,
          null,
          widget.jsonSchemaForm.uiSchema,
          widget.jsonSchemaForm.formData,
        ),
      ),
    );

    if (widget.isScrollable) {
      return SingleChildScrollView(controller: _scrollController, child: form);
    } else {
      return form;
    }
  }

  Widget _buildJsonschemaForm(
    JsonSchema jsonSchema,
    String? jsonKey,
    UiSchema? uiSchema,
    dynamic formData, {
    JsonSchema? previousSchema,
    String? previousJsonKey,
    UiSchema? previousUiSchema,
    int? arrayIndex,
  }) {
    final mergedJsonSchema =
        _mergeDependencies(jsonSchema, formData) ?? jsonSchema;

    final (newFormData, previousFormData) = _modifyFormData(
      mergedJsonSchema,
      jsonKey,
      formData,
    );

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

            final description =
                _getDescription(jsonKey, mergedJsonSchema, uiSchema);

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
                newFormData,
              )
          else
            ..._buildOrderedObjectEntries(
              jsonKey,
              mergedJsonSchema,
              uiSchema,
              arrayIndex,
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
              buildJsonschemaForm: _buildJsonschemaForm,
              rebuildForm: _rebuildForm,
              getTitle: () => _getTitle(
                jsonKey,
                mergedJsonSchema,
                uiSchema,
                previousSchema,
                arrayIndex,
              ),
              getDescription: () =>
                  _getDescription(jsonKey, mergedJsonSchema, uiSchema),
              getReadOnly: () =>
                  _getReadOnly(jsonKey, mergedJsonSchema, uiSchema),
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
            buildJsonschemaForm: _buildJsonschemaForm,
            getReadOnly: () =>
                _getReadOnly(jsonKey, mergedJsonSchema, uiSchema),
            getIsRequired: () => _getIsRequired(
              jsonKey,
              previousSchema,
              arrayIndex,
              previousFormData,
            ),
            onItemAdded: widget.onItemAdded,
            onItemRemoved: widget.onItemRemoved,
            scrollToBottom: _scrollToBottom,
          )
        else
          _UiWidget(
            mergedJsonSchema,
            jsonKey,
            uiSchema,
            formData,
            rebuildForm: _rebuildForm,
            previousSchema: previousSchema,
            previousFormData: previousFormData,
            arrayIndex: arrayIndex,
            getTitle: () => _getTitle(
              jsonKey,
              mergedJsonSchema,
              uiSchema,
              previousSchema,
              arrayIndex,
            ),
            getDescription: () =>
                _getDescription(jsonKey, mergedJsonSchema, uiSchema),
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
            getReadOnly: () =>
                _getReadOnly(jsonKey, mergedJsonSchema, uiSchema),
            formFieldKeys: _formFieldKeys,
            resolution: widget.resolution,
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

  /// Rebulds the whole form when needed. For example: when a nested field
  /// changes and depends on others from the tree this will rebuild everything
  /// so te form is updated accordingly. This is an easy and fast solution but a
  /// new more eperformant solution should be done in future.
  void _rebuildForm() {
    setState(() {});
  }

  List<Widget> _buildObjectEntries(
    MapEntry<String, JsonSchema> entry,
    String? jsonKey,
    JsonSchema jsonSchema,
    UiSchema? uiSchema,
    int? arrayIndex,
    dynamic newFormData,
  ) {
    return [
      /// Build one Widget for each property in the schema
      _buildJsonschemaForm(
        entry.value,
        entry.key,
        uiSchema?.children?[entry.key],
        newFormData,
        previousSchema: jsonSchema,
        previousJsonKey: jsonKey,
        previousUiSchema: uiSchema,
        arrayIndex: arrayIndex,
      ),

      /// Build Schema dependencies, widgets that will be added
      /// dynamically depending on other field values
      if (jsonSchema.dependencies != null &&
          jsonSchema.dependencies![entry.key] is JsonSchema &&
          jsonSchema.dependencies!.keys.contains(entry.key))

        /// This is a schema based dependency, so new fields will be added
        /// dynamically
        _buildJsonschemaForm(
          jsonSchema.dependencies![entry.key] as JsonSchema,
          entry.key,
          uiSchema?.children?[entry.key],
          newFormData,
          previousSchema: jsonSchema,
          previousJsonKey: jsonKey,
          previousUiSchema: uiSchema,
          arrayIndex: arrayIndex,
        ),
    ];
  }

  /// This will be used to order widgets when ui:order is specified
  List<Widget> _buildOrderedObjectEntries(
    String? jsonKey,
    JsonSchema jsonSchema,
    UiSchema? uiSchema,
    int? arrayIndex,
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
        return formData[jsonKey]?.toString() ?? jsonSchema.defaultValue;
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
    int? arrayIndex,
  ) {
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
        return '${previousSchema?.title}-${arrayIndex + 1}';
      } else {
        return null;
      }
    }

    return jsonKey;
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
  ) {
    if (widget.readOnly) {
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

  void _scrollToBottom() {
    if (!widget.isScrollable || !widget.scrollToBottom) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController!.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.easeIn,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  void _scrollToFirstInvalidField() {
    if (!widget.isScrollable || !widget.scrollToFirstError) {
      return;
    }

    final context = _getFirstInvalidFieldContext();

    if (context == null) return;

    final renderObject = context.findRenderObject() as RenderBox?;

    if (renderObject == null) return;

    _scrollController?.position.ensureVisible(
      renderObject,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
    );
  }

  /// Method used to get the context of the first field with an error after
  /// submitting the form. Useful to scroll to that context.
  BuildContext? _getFirstInvalidFieldContext() {
    for (final formFieldKey in _formFieldKeys) {
      if (formFieldKey.currentState != null &&
          formFieldKey.currentContext != null) {
        if (formFieldKey.currentState!.hasError) {
          return formFieldKey.currentContext!;
        }
      }
    }
    return null;
  }

  /// Validated the form. If the form is invalid it will return null otherwise
  /// it will return the cleared formData.
  Map<String, dynamic>? submit() {
    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      _scrollToFirstInvalidField();

      return null;
    }

    return Map<String, dynamic>.from(widget.jsonSchemaForm.formData!)
        .removeEmptySubmaps();
  }
}
