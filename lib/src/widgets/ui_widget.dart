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

    final defaultValue = _getDefaultValue();

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
      return _CustomFormFieldValidator<String>(
        isEnabled: hasValidator,
        isEmpty: (value) => value.isEmpty,
        childFormBuilder: (field) {
          return _CustomDropdownMenu<String>(
            label: title,
            itemLabel: (_, item) => item,
            items: jsonSchema.enumValue!,
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
      return _CustomFormFieldValidator<String>(
        isEnabled: hasValidator,
        isEmpty: (value) => value.isEmpty,
        childFormBuilder: (field) {
          return _CustomRadioGroup<String>(
            jsonKey: jsonKey!,
            label: title,
            itemLabel: (_, item) => item,
            items: jsonSchema.enumValue!,
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
      return _CustomFormFieldValidator<bool>(
        isEnabled: hasValidator,
        childFormBuilder: (field) {
          return _CustomRadioGroup<bool>(
            jsonKey: jsonKey!,
            label: title,
            itemLabel: (_, item) => item ? 'Yes' : 'No',
            items: const [false, true],
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
      return _CustomFormFieldValidator<List<String>>(
        isEnabled: hasValidator,
        isEmpty: (value) => value.isEmpty,
        childFormBuilder: (field) {
          return _CustomCheckboxGroup(
            jsonKey: jsonKey!,
            label: title,
            items: jsonSchema.enumValue!,
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
        hasValidator: hasValidator,
        labelText: title,
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
        hasValidator: hasValidator,
        labelText: title,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        defaultValue: defaultValue?.toString(),
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
      );
    } else {
      return _CustomTextFormField(
        onChanged: onFieldChanged,
        hasValidator: hasValidator,
        labelText: title,
        defaultValue: defaultValue?.toString(),
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
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
        return data[arrayIndex!]?.toString() ?? jsonSchema.defaultValue;
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
