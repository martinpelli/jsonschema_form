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
    required this.title,
    this.readOnly = false,
  });

  final JsonSchema jsonSchema;
  final String? jsonKey;
  final UiSchema? uiSchema;
  final dynamic formData;
  final void Function() rebuildForm;
  final JsonSchema? previousSchema;
  final dynamic previousFormData;
  final int? arrayIndex;
  final String? title;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final hasUniqueItems = previousSchema?.uniqueItems ?? false;

    /// If the previous jsonSchema has uniqueItems it means that this is a
    /// multiple choice list, so it cannot have default values
    final defaultValue = hasUniqueItems ? null : _getDefaultValue();

    if (defaultValue != null) {
      _setValueInFormData(defaultValue);
    }

    /// The filed is required if the jsonSchema has its jsonKey in the required
    /// array
    /// if it a required item from an array with additional items
    /// if is an item index less than minItems from an array
    /// is required by a dependency
    final hasRequiredValidator = (previousSchema?.requiredFields?.contains(
              jsonKey,
            ) ??
            false) ||
        previousSchema?.items is List<dynamic> ||
        (previousSchema?.minItems != null &&
            arrayIndex! < previousSchema!.minItems!) ||
        _isPropertyDependantAndDependencyHasValue();

    final initialStringValue = defaultValue?.toString();

    if (_isDropdown()) {
      return _buildDropdown(hasRequiredValidator, initialStringValue);
    } else if (_isRadioGroup()) {
      return _buildRadioGroup(hasRequiredValidator, initialStringValue);
    } else if (_isRadio()) {
      final initialValue = defaultValue is String
          ? bool.tryParse(
              defaultValue,
            )
          : null;
      return _buildRadio(hasRequiredValidator, initialValue);
    } else if (_isCheckbox()) {
      final initialValue = defaultValue is String
          ? [
              bool.tryParse(
                defaultValue,
              )!,
            ]
          : null;
      return _buildCheckbox(hasRequiredValidator, initialValue);
    } else if (_isCheckboxGroup()) {
      final initialValues = (formData as List).cast<String>();
      return _buildCheckboxGroup(hasRequiredValidator, initialValues);
    } else if (_isTextArea()) {
      return _buildTextArea(hasRequiredValidator, initialStringValue);
    } else if (_isUpDown()) {
      return _buildUpDown(hasRequiredValidator, initialStringValue);
    } else if (_isFile()) {
      return _buildFile(hasRequiredValidator, initialStringValue);
    } else if (_isDate()) {
      return _buildDate(context, hasRequiredValidator, initialStringValue);
    } else if (_isDateTime()) {
      return _buildDateTime(context, hasRequiredValidator, initialStringValue);
    } else {
      return _buildText(hasRequiredValidator, initialStringValue);
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

  Future<void> _setValueInFormData(dynamic value) async {
    if (value is String && value.isEmpty) {
      if (formData is Map) {
        (formData as Map).remove(jsonKey);
      } else {
        (formData as List)[arrayIndex!] = null;
      }
    } else if (value is List<String>) {
      (formData as List).clear();
      (formData as List).addAll(value);
    } else if (value is XFile) {
      final base64File = await value.getBase64();
      if (formData is Map) {
        (formData as Map)[jsonKey!] = base64File;
      } else {
        (formData as List)[arrayIndex!] = base64File;
      }
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

  bool _isDropdown() =>
      uiSchema?.widget == UiType.select ||
      (uiSchema?.widget == null && jsonSchema.enumValue != null);

  Widget _buildDropdown(
    bool hasRequiredValidator,
    String? initialValue,
  ) {
    return _CustomFormFieldValidator<String>(
      isEnabled: hasRequiredValidator,
      initialValue: initialValue,
      isEmpty: (value) => value.isEmpty,
      childFormBuilder: (field) {
        return _CustomDropdownMenu<String>(
          readOnly: jsonSchema.readOnly ?? uiSchema?.readonly ?? readOnly,
          label: "$title${hasRequiredValidator ? '*' : ''}",
          labelStyle: hasRequiredValidator
              ? const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                )
              : null,
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
    bool hasRequiredValidator,
    String? initialValue,
  ) {
    return _CustomFormFieldValidator<String>(
      isEnabled: hasRequiredValidator,
      initialValue: initialValue,
      isEmpty: (value) => value.isEmpty,
      childFormBuilder: (field) {
        return _CustomRadioGroup<String>(
          readOnly: jsonSchema.readOnly ?? uiSchema?.readonly ?? readOnly,
          label: "$title${hasRequiredValidator ? '*' : ''}",
          labelStyle: hasRequiredValidator
              ? const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                )
              : null,
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

  bool _isRadio() =>
      uiSchema?.widget != UiType.checkbox &&
      jsonSchema.type == JsonType.boolean;

  Widget _buildRadio(
    bool hasRequiredValidator,
    bool? initialValue,
  ) {
    return _CustomFormFieldValidator<bool>(
      isEnabled: hasRequiredValidator,
      initialValue: initialValue,
      childFormBuilder: (field) {
        return _CustomRadioGroup<bool>(
          readOnly: jsonSchema.readOnly ?? uiSchema?.readonly ?? readOnly,
          label: "$title${hasRequiredValidator ? '*' : ''}",
          labelStyle: hasRequiredValidator
              ? const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                )
              : null,
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

  bool _isCheckbox() =>
      uiSchema?.widget != UiType.radio && jsonSchema.type == JsonType.boolean;

  Widget _buildCheckbox(
    bool hasRequiredValidator,
    List<bool>? initialValue,
  ) {
    return _CustomFormFieldValidator<bool>(
      isEnabled: hasRequiredValidator,
      initialValue: initialValue?.first,
      childFormBuilder: (field) {
        return _CustomCheckboxGroup<bool>(
          readOnly: jsonSchema.readOnly ?? uiSchema?.readonly ?? readOnly,
          jsonKey: jsonKey!,
          label: "$title${hasRequiredValidator ? '*' : ''}",
          labelStyle: hasRequiredValidator
              ? const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                )
              : null,
          itemLabel: (_, item) => item ? 'Yes' : 'No',
          items: const [true],
          initialItems: initialValue,
          onCheckboxValuesSelected: (value) {
            _onFieldChangedWithValidator<bool>(
              field,
              value.isNotEmpty && value.first,
            );
          },
        );
      },
    );
  }

  bool _isCheckboxGroup() => uiSchema?.widget == UiType.checkboxes;

  Widget _buildCheckboxGroup(
    bool hasRequiredValidator,
    List<String> initialValues,
  ) {
    return _CustomFormFieldValidator<List<String>>(
      isEnabled: hasRequiredValidator,
      initialValue: initialValues,
      isEmpty: (value) => value.isEmpty,
      childFormBuilder: (field) {
        return _CustomCheckboxGroup<String>(
          readOnly: jsonSchema.readOnly ?? uiSchema?.readonly ?? readOnly,
          jsonKey: jsonKey!,
          label: "$title${hasRequiredValidator ? '*' : ''}",
          labelStyle: hasRequiredValidator
              ? const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                )
              : null,
          items: jsonSchema.enumValue!,
          itemLabel: (_, item) => item,
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
    bool hasRequiredValidator,
    String? initialValue,
  ) {
    final validators = <String? Function(String?)>[];

    _addMinLengthValidator(validators);

    _addMaxLengthValidator(validators);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        readOnly: jsonSchema.readOnly ?? uiSchema?.readonly ?? readOnly,
        onChanged: _onFieldChanged,
        hasRequiredValidator: hasRequiredValidator,
        labelText: "$title${hasRequiredValidator ? '*' : ''}",
        minLines: 4,
        maxLines: null,
        defaultValue: initialValue,
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
        validator: validators.isEmpty
            ? null
            : (value) {
                for (final validator in validators) {
                  final error = validator(value);
                  if (error != null) {
                    return error;
                  }
                }
                return null;
              },
      ),
    );
  }

  bool _isUpDown() => uiSchema?.widget == UiType.updown;

  Widget _buildUpDown(bool hasRequiredValidator, String? initialValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        readOnly: jsonSchema.readOnly ?? uiSchema?.readonly ?? readOnly,
        onChanged: _onFieldChanged,
        hasRequiredValidator: hasRequiredValidator,
        labelText: "$title${hasRequiredValidator ? '*' : ''}",
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        defaultValue: initialValue,
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
      ),
    );
  }

  bool _isFile() =>
      uiSchema?.widget == UiType.file ||
      jsonSchema.format == JsonSchemaFormat.dataUrl;

  Widget _buildFile(bool hasRequiredValidator, String? initialValue) {
    final acceptedExtensions = (uiSchema?.options?.containsKey(
              UiOptions.accept.name,
            ) ??
            false)
        ? (uiSchema?.options?[UiOptions.accept.name] as String?)?.split(',')
        : null;

    final hasFilePicker = !(uiSchema?.options?.containsKey(
              UiOptions.explorer.name,
            ) ??
            true) ||
        (uiSchema?.options?[UiOptions.explorer.name] as bool? ?? true);

    final hasCameraButton = (uiSchema?.options?.containsKey(
              UiOptions.camera.name,
            ) ??
            false) &&
        (uiSchema?.options?[UiOptions.camera.name] as bool);

    final isPhotoAllowed = !(uiSchema?.options?.containsKey(
              UiOptions.photo.name,
            ) ??
            true) ||
        (uiSchema?.options?[UiOptions.photo.name] as bool? ?? true);

    final isVideoAllowed = (uiSchema?.options?.containsKey(
              UiOptions.video.name,
            ) ??
            false) &&
        (uiSchema?.options?[UiOptions.video.name] as bool);

    return _CustomFormFieldValidator<String?>(
      isEnabled: hasRequiredValidator,
      initialValue: initialValue,
      isEmpty: (value) {
        return value == null || value.isEmpty == true;
      },
      childFormBuilder: (field) {
        return _CustomFileUpload(
          readOnly: jsonSchema.readOnly ?? uiSchema?.readonly ?? readOnly,
          acceptedExtensions: acceptedExtensions,
          hasFilePicker: hasFilePicker,
          hasCameraButton: hasCameraButton,
          title: "$title${hasRequiredValidator ? '*' : ''}",
          onFileChosen: (value) async {
            await _onFieldChangedWithValidator<String?>(field, value);
          },
          isPhotoAllowed: isPhotoAllowed,
          isVideoAllowed: isVideoAllowed,
          fileData: initialValue,
        );
      },
    );
  }

  bool _isDate() => uiSchema?.widget == UiType.date;

  Widget _buildDate(
    BuildContext context,
    bool hasRequiredValidator,
    String? initialValue,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        onChanged: _onFieldChanged,
        labelText: "$title${hasRequiredValidator ? '*' : ''}",
        defaultValue: initialValue,
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
        readOnly: true,
        canRequestFocus: false,
        mouseCursor: SystemMouseCursors.click,
        hasRequiredValidator: hasRequiredValidator,
        onTap: readOnly
            ? null
            : () async {
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
    bool hasRequiredValidator,
    String? initialValue,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        onChanged: _onFieldChanged,
        labelText: "$title${hasRequiredValidator ? '*' : ''}",
        defaultValue: initialValue,
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
        readOnly: true,
        canRequestFocus: false,
        mouseCursor: SystemMouseCursors.click,
        hasRequiredValidator: hasRequiredValidator,
        onTap: readOnly
            ? null
            : () async {
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

  Widget _buildText(bool hasRequiredValidator, String? initialValue) {
    final validators = <String? Function(String?)>[];

    final isEmailTextFormField = jsonSchema.format == JsonSchemaFormat.email;

    final isNumberTextFormFiled = jsonSchema.type == JsonType.number;

    if (isEmailTextFormField) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      validators.add((value) {
        if (value != null &&
            value.isNotEmpty &&
            !emailRegex.hasMatch(value.trim())) {
          return 'Invalid email';
        }

        return null;
      });
    }

    _addMinLengthValidator(validators);

    _addMaxLengthValidator(validators);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        readOnly: jsonSchema.readOnly ?? uiSchema?.readonly ?? readOnly,
        onChanged: _onFieldChanged,
        labelText: "$title${hasRequiredValidator ? '*' : ''}",
        defaultValue: initialValue,
        emptyValue: uiSchema?.emptyValue,
        placeholder: uiSchema?.placeholder,
        helperText: uiSchema?.help,
        autofocus: uiSchema?.autofocus,
        inputFormatters: isNumberTextFormFiled
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        keyboardType: isEmailTextFormField
            ? TextInputType.emailAddress
            : isNumberTextFormFiled
                ? TextInputType.number
                : null,
        hasRequiredValidator: hasRequiredValidator,
        validator: validators.isEmpty
            ? null
            : (value) {
                for (final validator in validators) {
                  final error = validator(value);
                  if (error != null) {
                    return error;
                  }
                }
                return null;
              },
      ),
    );
  }

  Future<void> _onFieldChanged<T>(T value) async {
    await _setValueInFormData(value);
    _rebuildFormIfHasDependants();
  }

  FutureOr<void> _onFieldChangedWithValidator<T>(
    FormFieldState<T>? field,
    T value,
  ) async {
    field?.didChange(value);
    final isValid = field?.isValid ?? true;
    if (isValid) {
      await _onFieldChanged(value);
    }
    _rebuildFormIfHasDependants();
  }

  void _addMinLengthValidator(List<String? Function(String?)> validators) {
    if (jsonSchema.minLength != null) {
      validators.add((value) {
        if (value != null && value.length < jsonSchema.minLength!) {
          return 'Must have at least ${jsonSchema.minLength} characters';
        }

        return null;
      });
    }
  }

  void _addMaxLengthValidator(List<String? Function(String? p1)> validators) {
    if (jsonSchema.maxLength != null) {
      validators.add((value) {
        if (value != null && value.length > jsonSchema.maxLength!) {
          return 'Must have ${jsonSchema.minLength} characters as much';
        }

        return null;
      });
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
}
