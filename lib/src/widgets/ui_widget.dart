part of '../jsonschema_form_builder.dart';

class _UiWidget extends StatelessWidget {
  const _UiWidget(
    this.jsonSchema,
    this.jsonKey,
    this.uiSchema,
    this.formData, {
    required this.rebuildForm,
    required this.previousSchema,
    required this.previousFormData,
    required this.arrayIndex,
  });

  final JsonSchema jsonSchema;
  final String? jsonKey;
  final UiSchema? uiSchema;
  final dynamic formData;
  final void Function() rebuildForm;
  final JsonSchema? previousSchema;
  final dynamic previousFormData;
  final int? arrayIndex;

  @override
  Widget build(BuildContext context) {
    final title = jsonSchema.title ?? jsonKey;

    final hasUniqueItems = previousSchema?.uniqueItems ?? false;

    /// If the previous jsonSchema has uniqueItems it means that this is a
    /// multiple choice list, so it cannot have default values
    final defaultValue = hasUniqueItems ? null : _getDefaultValue();

    if (defaultValue != null) {
      _setValueInFormData(defaultValue);
    }

    final hasValidator =
        (previousSchema?.requiredFields?.contains(jsonKey) ?? false) ||
            _isPropertyDependantAndDependencyHasValue();

    void onFieldChanged(dynamic value) {
      _setValueInFormData(value);
      _rebuildFormIfHasDependants();
    }

    if (uiSchema?.widget == UiType.select ||
        (uiSchema?.widget == null && jsonSchema.enumValue != null)) {
      final initialValue = defaultValue is String ? defaultValue : null;

      return _CustomFormFieldValidator<String>(
        isEnabled: hasValidator,
        initialValue: initialValue,
        isEmpty: (value) => value.isEmpty,
        childFormBuilder: (field) {
          return _CustomDropdownMenu<String>(
            label: "$title${hasValidator ? '*' : ''}",
            itemLabel: (_, item) => item,
            items: jsonSchema.enumValue!,
            selectedItem: initialValue,
            onDropdownValueSelected: (value) {
              field?.didChange(value);
              if (field?.isValid ?? true) {
                onFieldChanged(value);
              }
              _rebuildFormIfHasDependants();
            },
          );
        },
      );
    } else if (uiSchema?.widget == UiType.radio) {
      final initialValue = defaultValue is String ? defaultValue : null;

      return _CustomFormFieldValidator<String>(
        isEnabled: hasValidator,
        initialValue: initialValue,
        isEmpty: (value) => value.isEmpty,
        childFormBuilder: (field) {
          return _CustomRadioGroup<String>(
            jsonKey: jsonKey!,
            label: "$title${hasValidator ? '*' : ''}",
            itemLabel: (_, item) => item,
            items: jsonSchema.enumValue!,
            initialItem: initialValue,
            onRadioValueSelected: (value) {
              field?.didChange(value);
              if (field?.isValid ?? true) {
                onFieldChanged(value);
              }
              _rebuildFormIfHasDependants();
            },
          );
        },
      );
    } else if (jsonSchema.type == JsonType.boolean) {
      final initialValue = defaultValue is bool ? defaultValue : null;

      return _CustomFormFieldValidator<bool>(
        isEnabled: hasValidator,
        initialValue: initialValue,
        childFormBuilder: (field) {
          return _CustomRadioGroup<bool>(
            jsonKey: jsonKey!,
            label: "$title${hasValidator ? '*' : ''}",
            itemLabel: (_, item) => item ? 'Yes' : 'No',
            items: const [false, true],
            initialItem: initialValue,
            onRadioValueSelected: (value) {
              field?.didChange(value);
              if (field?.isValid ?? true) {
                onFieldChanged(value);
              }
              _rebuildFormIfHasDependants();
            },
          );
        },
      );
    } else if (uiSchema?.widget == UiType.checkboxes) {
      final initialValues = (formData as List).cast<String>();

      return _CustomFormFieldValidator<List<String>>(
        isEnabled: hasValidator,
        initialValue: initialValues,
        isEmpty: (value) => value.isEmpty,
        childFormBuilder: (field) {
          return _CustomCheckboxGroup(
            jsonKey: jsonKey!,
            label: "$title${hasValidator ? '*' : ''}",
            items: jsonSchema.enumValue!,
            initialItems: initialValues,
            onCheckboxValuesSelected: (value) {
              field?.didChange(value);
              if (field?.isValid ?? true) {
                onFieldChanged(value);
              }
              _rebuildFormIfHasDependants();
            },
          );
        },
      );
    } else if (uiSchema?.widget == UiType.textarea) {
      return _CustomTextFormField(
        onChanged: onFieldChanged,
        hasRequiredValidator: hasValidator,
        labelText: "$title${hasValidator ? '*' : ''}",
        minLines: 4,
        maxLines: null,
        defaultValue: defaultValue?.toString(),
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
      );
    } else if (uiSchema?.widget == UiType.updown) {
      return _CustomTextFormField(
        onChanged: onFieldChanged,
        hasRequiredValidator: hasValidator,
        labelText: "$title${hasValidator ? '*' : ''}",
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        defaultValue: defaultValue?.toString(),
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
      );
    }
    if (jsonSchema.format == JsonSchemaFormat.dataUrl) {
      final acceptedExtensions =
          (uiSchema?.options?.containsKey(UiOptions.accept.name) ?? false)
              ? (uiSchema?.options?[UiOptions.accept.name] as String?)
                  ?.split(',')
              : null;

      final hasFilePicker =
          !(uiSchema?.options?.containsKey(UiOptions.explorer.name) ?? true) ||
              (uiSchema?.options?[UiOptions.explorer.name] as bool? ?? true);

      final hasCameraButton =
          (uiSchema?.options?.containsKey(UiOptions.camera.name) ?? false) &&
              (uiSchema?.options?[UiOptions.camera.name] as bool);

      final isPhotoAllowed =
          !(uiSchema?.options?.containsKey(UiOptions.photo.name) ?? true) ||
              (uiSchema?.options?[UiOptions.photo.name] as bool? ?? true);

      final isVideoAllowed =
          (uiSchema?.options?.containsKey(UiOptions.video.name) ?? false) &&
              (uiSchema?.options?[UiOptions.video.name] as bool);

      return _CustomFileUpload(
        acceptedExtensions: acceptedExtensions,
        hasFilePicker: hasFilePicker,
        hasCameraButton: hasCameraButton,
        title: "$title${hasValidator ? '*' : ''}",
        onFileChosen: _setValueInFormData,
        isPhotoAllowed: isPhotoAllowed,
        isVideoAllowed: isVideoAllowed,
      );
    } else {
      final isEmailTextFormField = jsonSchema.format == JsonSchemaFormat.email;

      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _CustomTextFormField(
          onChanged: onFieldChanged,
          labelText: "$title${hasValidator ? '*' : ''}",
          defaultValue: defaultValue?.toString(),
          emptyValue: uiSchema?.emptyValue,
          placeholder: uiSchema?.placeholder,
          helperText: uiSchema?.help,
          autofocus: uiSchema?.autofocus,
          keyboardType:
              isEmailTextFormField ? TextInputType.emailAddress : null,
          hasRequiredValidator: hasValidator,
          validator: isEmailTextFormField
              ? (value) {
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (value != null &&
                      value.isNotEmpty &&
                      !emailRegex.hasMatch(value.trim())) {
                    return 'Invalid email';
                  }

                  return null;
                }
              : null,
        ),
      );
    }
  }

  dynamic _getDefaultValue() {
    if (formData is Map) {
      final data = formData as Map;
      if (data.containsKey(jsonKey)) {
        return data[jsonKey]?.toString() ?? jsonSchema.defaultValue;
      } else {
        return jsonSchema.defaultValue;
      }
    } else if (formData is List) {
      final data = formData as List;

      if (arrayIndex! <= data.length - 1) {
        final fieldData = data[arrayIndex!];
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

  void _setValueInFormData(dynamic value) {
    if (value is String && value.isEmpty) {
      if (formData is Map) {
        (formData as Map).remove(jsonKey);
      } else {
        (formData as List)[arrayIndex!] = null;
      }
    } else if (value is List<String>) {
      (formData as List).clear();
      (formData as List).addAll(value);
    } else {
      if (formData is Map) {
        (formData as Map)[jsonKey!] = value;
      } else {
        (formData as List)[arrayIndex!] = value;
      }
    }
  }

  /// Property dependencies: unidirectional and bidirectional
  void _rebuildFormIfHasDependants() {
    if (_hasDependants()) {
      rebuildForm();
    }
  }

  /// Property dependencies: unidirectional and bidirectional
  /// If a field has dependants, it means that when the field is changed, the
  /// whole form will be rebuilt so that the dependants fields are required or
  /// not, depending if the value is valid or not
  bool _hasDependants() {
    if (previousSchema?.dependencies != null &&
        previousSchema!.dependencies!.keys.contains(jsonKey)) {
      return true;
    }
    return false;
  }

  /// If a field is dependant of another one then it will add a required
  /// validation if the field which depends on is filled with a valid value
  bool _isPropertyDependantAndDependencyHasValue() {
    if (previousSchema?.dependencies != null) {
      for (final dependency in previousSchema!.dependencies!.entries) {
        /// Property dependency
        if (dependency.value is List<String>) {
          final dependencies = dependency.value as List<String>;

          if (dependencies.contains(jsonKey) &&
              ((previousFormData as Map<String, dynamic>?)
                      ?.containsKey(dependency.key) ??
                  false)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
