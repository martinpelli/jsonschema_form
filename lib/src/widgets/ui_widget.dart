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
  });

  final JsonSchema jsonSchema;
  final String? jsonKey;
  final UiSchema? uiSchema;
  final Map<String, dynamic> formData;
  final void Function() rebuildForm;
  final JsonSchema? previousSchema;
  final Map<String, dynamic>? previousFormData;

  @override
  Widget build(BuildContext context) {
    final title = jsonSchema.title ?? jsonKey;

    final defaultValue = formData.containsKey(jsonKey)
        ? formData[jsonKey]?.toString()
        : jsonSchema.defaultValue;

    final hasValidator =
        (previousSchema?.requiredFields?.contains(jsonKey) ?? false) ||
            _isDependantAndDependencyHasValue();

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
                _onEnumValueSelected(jsonKey!, value);
                _rebuildFormIfHasDependants();
              }
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
            onRadioValueSelected: (key, value) {
              field?.didChange(value);
              if (field?.isValid ?? true) {
                _onEnumValueSelected(key, value);
                _rebuildFormIfHasDependants();
              }
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
            onCheckboxValuesSelected: (key, value) {
              field?.didChange(value);
              if (field?.isValid ?? true) {
                _onMultipleEnumValuesSelected(key, value);
                _rebuildFormIfHasDependants();
              }
            },
          );
        },
      );
    } else if (uiSchema?.widget == UiType.textarea) {
      return _CustomTextFormField(
        onChanged: (value) {
          if (value.isEmpty) {
            formData.remove(jsonKey);
          } else {
            formData[jsonKey!] = value;
            _rebuildFormIfHasDependants();
          }
        },
        hasValidator: hasValidator,
        labelText: title,
        minLines: 4,
        maxLines: null,
        defaultValue: defaultValue,
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
      );
    } else if (uiSchema?.widget == UiType.updown) {
      return _CustomTextFormField(
        onChanged: (value) {
          if (value.isEmpty) {
            formData.remove(jsonKey);
          } else {
            formData[jsonKey!] = value;
            _rebuildFormIfHasDependants();
          }
        },
        hasValidator: hasValidator,
        labelText: title,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        defaultValue: defaultValue,
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
      );
    } else {
      return _CustomTextFormField(
        onChanged: (value) {
          if (value.isEmpty) {
            formData.remove(jsonKey);
          } else {
            formData[jsonKey!] = value;
            _rebuildFormIfHasDependants();
          }
        },
        hasValidator: hasValidator,
        labelText: title,
        defaultValue: defaultValue,
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
      );
    }
  }

  void _onEnumValueSelected(String key, String value) {
    if (value.isEmpty) {
      formData.remove(key);
    } else {
      formData[key] = value;
    }
  }

  void _onMultipleEnumValuesSelected(String key, List<String> value) {
    if (value.isEmpty) {
      formData.remove(key);
    } else {
      formData[key] = value;
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

  /// Property dependencies: unidirectional and bidirectional
  /// If a filed is dependant then it will add a required validation if the
  /// field which depends on is filled with a vaalid value
  bool _isDependantAndDependencyHasValue() {
    List<String>? dependencies;
    if (previousSchema?.dependencies != null) {
      for (final dependency in previousSchema!.dependencies!.entries) {
        if (dependency.value is List<String>) {
          dependencies = dependency.value as List<String>;

          if (dependencies.contains(jsonKey) &&
              (previousFormData?.containsKey(dependency.key) ?? false)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
