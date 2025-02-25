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
import 'package:jsonschema_form/src/typedefs/typedefs.dart';
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
part 'widgets/form_section.dart';
part 'widgets/hybrid_widget.dart';
part 'widgets/one_of_form.dart';
part 'widgets/ui_widget.dart';

/// Builds a Form by decoding a Json Schema
class JsonschemaFormBuilder extends StatefulWidget {
  /// {@macro jsonschema_form_builder}
  const JsonschemaFormBuilder({
    required this.jsonSchemaForm,
    this.prefixFormDataMapper,
    this.suffixFormDataMapper,
    this.readOnly = false,
    this.cameraResolution = CameraResolution.max,
    this.isScrollable = true,
    this.scrollToBottom = true,
    this.scrollToFirstError = true,
    this.onArrayItemAdded,
    this.onArrayItemRemoved,
    this.createArrayItemAs = CreateArrayItemAs.inside,
    this.padding,
    super.key,
  });

  /// The json schema for the form.
  final JsonschemaForm jsonSchemaForm;

  /// A function used to map or transform data before adding it to the form.
  ///
  /// This function is typically used to process or modify form data before it
  /// is added to the form submission. It takes a `String` as the key and
  /// `dynamic` data as the value and returns a transformed value.
  final dynamic Function(String, dynamic)? prefixFormDataMapper;

  /// A function used to map or transform data after it is added to the form.
  ///
  /// This function is typically used to process or modify form data after it
  /// has been added to the form, before it is submitted. It takes two `dynamic`
  ///  parameters (the existing value and the new value) and returns
  /// a transformed value.
  final dynamic Function(dynamic, dynamic)? suffixFormDataMapper;

  /// Useful if the user needs to see the whole form in read only, so none field
  /// will be editable. This can be useful if you don't want to provide a
  /// ui:readonly key to each field.
  final bool readOnly;

  /// [CameraResolution] affects the quality of video recording and image
  /// capture.
  final CameraResolution cameraResolution;

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
  final void Function(JsonSchema)? onArrayItemAdded;

  /// Function called when an item is removed from an array
  final void Function()? onArrayItemRemoved;

  /// Change the way that a new array item is created, see [CreateArrayItemAs]
  /// for all options available
  final CreateArrayItemAs createArrayItemAs;

  /// For adding padding to the form. Useful if you have [isScrollable] set to
  /// Padding applied to the widget or component.
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
  /// Used for validating all fields when the form is submitted
  final _formKey = GlobalKey<FormState>();

  /// Used for holding a reference to the state of those widgets that have a
  /// FormFieldState.
  /// This is only used when isScrollable and scrollToFirstError is true in
  /// order to find the first field with an error
  late final List<GlobalKey<FormFieldState<dynamic>>>? _formFieldKeys;

  late final ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();

    if (widget.isScrollable) {
      _scrollController = ScrollController();
    } else {
      _scrollController = null;
    }

    if (widget.isScrollable && widget.scrollToFirstError) {
      _formFieldKeys = [];
    } else {
      _formFieldKeys = null;
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
          widget.jsonSchemaForm.jsonSchema,
          null,
          widget.jsonSchemaForm.uiSchema,
          widget.jsonSchemaForm.formData,
          prefixFormDataMapper: widget.prefixFormDataMapper,
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
    dynamic Function(String, dynamic)? prefixFormDataMapper,
    JsonSchema? previousSchema,
    String? previousJsonKey,
    UiSchema? previousUiSchema,
    int? arrayIndex,
  }) {
    final hasDependencies = jsonSchema.dependencies != null ||
        (jsonSchema.items is JsonSchema &&
            (jsonSchema.items as JsonSchema).dependencies != null);

    _FormSection buildFormSection() => _FormSection(
          jsonSchema,
          jsonKey,
          uiSchema,
          formData,
          prefixFormDataMapper: prefixFormDataMapper,
          buildJsonschemaForm: _buildJsonschemaForm,
          previousSchema: previousSchema,
          previousJsonKey: previousJsonKey,
          previousUiSchema: previousUiSchema,
          arrayIndex: arrayIndex,
          onArrayItemAdded: widget.onArrayItemAdded,
          onArrayItemRemoved: widget.onArrayItemRemoved,
          createArrayItemAs: widget.createArrayItemAs,
          rebuildDependencies: rebuildDependencies,
          isWholeFormReadOnly: widget.readOnly,
          cameraResolution: widget.cameraResolution,
          scrollToBottom: widget.isScrollable && widget.scrollToBottom
              ? _scrollToBottom
              : null,
          formFieldKeys: _formFieldKeys,
        );

    if (hasDependencies) {
      return _HybridWidget.stateful(
        jsonKey: jsonKey,
        buildFormSection: buildFormSection,
      );
    } else {
      return _HybridWidget.stateless(
        formSection: buildFormSection(),
      );
    }
  }

  /// Rebuilds a form dependency section. For example: when a nested field
  /// changes and this field has a dependency, this will only rebuild the
  /// dependency so it gets updated accordingly
  void rebuildDependencies(BuildContext context, String? jsonKeyDependency) {
    _HybridWidget.rebuildFormSection(context, jsonKeyDependency);
  }

  /// If isScrollable and scrollToBottom are true and if the form is
  /// overflowing the screen this will allow to scroll to the bottom, in order
  /// to see the latest item added
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

  /// If isScrollable and scrollToFirstError are true and if the form is
  /// overflowing the screen this will allow to scroll to the first field with
  /// an error
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
    if (_formFieldKeys == null) {
      return null;
    }

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
  /// Cleared formData is just the formData but without empty maps
  Map<String, dynamic>? submit() {
    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      _scrollToFirstInvalidField();

      return null;
    }
    final formData = Map<String, dynamic>.from(
      widget.jsonSchemaForm.formData,
    ).removeEmptySubmaps();
    final initialFormData = widget.jsonSchemaForm.initialFormData;
    return (widget.suffixFormDataMapper?.call(
          formData,
          initialFormData,
        ) as Map<String, dynamic>?) ??
        formData;
  }
}
