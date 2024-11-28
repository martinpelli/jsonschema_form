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

    final initialStringValue = defaultValue?.toString();

    if (_isDropdown()) {
      return _buildDropdown(title, hasValidator, initialStringValue);
    } else if (_isRadioGroup()) {
      return _buildRadioGroup(title, hasValidator, initialStringValue);
    } else if (_isRadio()) {
      final initialValue = defaultValue is bool ? defaultValue : null;
      return _buildRadio(title, hasValidator, initialValue);
    } else if (_isCheckboxGroup()) {
      final initialValues = (formData as List).cast<String>();
      return _buildCheckboxGroup(title, hasValidator, initialValues);
    } else if (_isTextArea()) {
      return _buildTextArea(title, hasValidator, initialStringValue);
    } else if (_isUpDown()) {
      return _buildUpDown(title, hasValidator, initialStringValue);
    } else if (_isFile()) {
      return _buildFile(title, hasValidator);
    } else if (_isDate()) {
      return _buildDate(context, title, hasValidator, initialStringValue);
    } else if (_isDateTime()) {
      return _buildDateTime(context, title, hasValidator, initialStringValue);
    } else {
      return _buildText(title, hasValidator, initialStringValue);
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

  bool _isDropdown() =>
      uiSchema?.widget == UiType.select ||
      (uiSchema?.widget == null && jsonSchema.enumValue != null);

  Widget _buildDropdown(
    String? title,
    bool hasValidator,
    String? initialValue,
  ) {
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
            _onFieldChangedWithValidator<String>(field, value);
          },
        );
      },
    );
  }

  bool _isRadioGroup() => uiSchema?.widget == UiType.radio;

  Widget _buildRadioGroup(
    String? title,
    bool hasValidator,
    String? initialValue,
  ) {
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
            _onFieldChangedWithValidator<String>(field, value);
          },
        );
      },
    );
  }

  bool _isRadio() => jsonSchema.type == JsonType.boolean;

  Widget _buildRadio(
    String? title,
    bool hasValidator,
    bool? initialValue,
  ) {
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
            _onFieldChangedWithValidator<bool>(field, value);
          },
        );
      },
    );
  }

  bool _isCheckboxGroup() => uiSchema?.widget == UiType.checkboxes;

  Widget _buildCheckboxGroup(
    String? title,
    bool hasValidator,
    List<String> initialValues,
  ) {
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
            _onFieldChangedWithValidator<List<String>>(field, value);
          },
        );
      },
    );
  }

  bool _isTextArea() => uiSchema?.widget == UiType.textarea;

  Widget _buildTextArea(
    String? title,
    bool hasValidator,
    String? initialValue,
  ) {
    return _CustomTextFormField(
      onChanged: _onFieldChanged,
      hasRequiredValidator: hasValidator,
      labelText: "$title${hasValidator ? '*' : ''}",
      minLines: 4,
      maxLines: null,
      defaultValue: initialValue,
      emptyValue: uiSchema?.emptyValue,
      placeholder: uiSchema?.placeholder,
      helperText: uiSchema?.help,
      autofocus: uiSchema?.autofocus,
    );
  }

  bool _isUpDown() => uiSchema?.widget == UiType.updown;

  Widget _buildUpDown(String? title, bool hasValidator, String? initialValue) {
    return _CustomTextFormField(
      onChanged: _onFieldChanged,
      hasRequiredValidator: hasValidator,
      labelText: "$title${hasValidator ? '*' : ''}",
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      defaultValue: initialValue,
      emptyValue: uiSchema?.emptyValue,
      placeholder: uiSchema?.placeholder,
      helperText: uiSchema?.help,
      autofocus: uiSchema?.autofocus,
    );
  }

  bool _isFile() => jsonSchema.format == JsonSchemaFormat.dataUrl;

  Widget _buildFile(
    String? title,
    bool hasValidator,
  ) {
    final acceptedExtensions =
        (uiSchema?.options?.containsKey(UiOptions.accept.name) ?? false)
            ? (uiSchema?.options?[UiOptions.accept.name] as String?)?.split(',')
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
  }

  bool _isDate() => uiSchema?.widget == UiType.date;

  Widget _buildDate(
    BuildContext context,
    String? title,
    bool hasValidator,
    String? initialValue,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        onChanged: _onFieldChanged,
        labelText: "$title${hasValidator ? '*' : ''}",
        defaultValue: initialValue,
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
        readOnly: true,
        canRequestFocus: false,
        mouseCursor: SystemMouseCursors.click,
        hasRequiredValidator: hasValidator,
        onTap: () async {
          final minDate = DateTime(1900);
          final maxDate = DateTime(9999, 12, 31);
          final datePicked = await showDatePicker(
            context: context,
            firstDate: minDate,
            lastDate: maxDate,
          );

          if (datePicked != null) {
            return DateFormat('dd/MM/yyyy').format(datePicked);
          }

          return null;
        },
      ),
    );
  }

  bool _isDateTime() => uiSchema?.widget == UiType.dateTime;

  Widget _buildDateTime(
    BuildContext context,
    String? title,
    bool hasValidator,
    String? initialValue,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        onChanged: _onFieldChanged,
        labelText: "$title${hasValidator ? '*' : ''}",
        defaultValue: initialValue,
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
        readOnly: true,
        canRequestFocus: false,
        mouseCursor: SystemMouseCursors.click,
        hasRequiredValidator: hasValidator,
        onTap: () async {
          final minDate = DateTime(1900);
          final maxDate = DateTime(9999, 12, 31);
          final datePicked = await showOmniDateTimePicker(
            context: context,
            firstDate: minDate,
            lastDate: maxDate,
          );

          if (datePicked != null) {
            return DateFormat('dd/MM/yyyy HH:mm').format(datePicked);
          }

          return null;
        },
      ),
    );
  }

  Widget _buildText(String? title, bool hasValidator, String? initialValue) {
    final isEmailTextFormField = jsonSchema.format == JsonSchemaFormat.email;

    final minLengthValidator = jsonSchema.minLength == null
        ? null
        : (String? value) {
            if (value != null && value.length > jsonSchema.minLength!) {
              return 'Must have at least ${jsonSchema.minLength} characters';
            }

            return null;
          };

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        onChanged: _onFieldChanged,
        labelText: "$title${hasValidator ? '*' : ''}",
        defaultValue: initialValue,
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
        keyboardType: isEmailTextFormField ? TextInputType.emailAddress : null,
        hasRequiredValidator: hasValidator,
        validator: isEmailTextFormField
            ? (value) {
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (value != null &&
                    value.isNotEmpty &&
                    !emailRegex.hasMatch(value.trim())) {
                  return 'Invalid email';
                }

                if (minLengthValidator != null) {
                  return minLengthValidator(value);
                }

                return null;
              }
            : minLengthValidator,
      ),
    );
  }

  void _onFieldChanged<T>(T value) {
    _setValueInFormData(value);
    _rebuildFormIfHasDependants();
  }

  void _onFieldChangedWithValidator<T>(FormFieldState<T>? field, T value) {
    field?.didChange(value);
    if (field?.isValid ?? true) {
      _onFieldChanged(value);
    }
    _rebuildFormIfHasDependants();
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
}
