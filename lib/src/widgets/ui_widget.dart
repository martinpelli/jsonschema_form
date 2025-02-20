part of '../jsonschema_form_builder.dart';

class _UiWidget extends StatefulWidget {
  const _UiWidget(
    this.jsonSchema,
    this.jsonKey,
    this.uiSchema,
    this.formData, {
    required this.previousSchema,
    required this.previousJsonKey,
    required this.previousFormData,
    required this.arrayIndex,
    required this.getTitle,
    required this.getDescription,
    required this.getDefaultValue,
    required this.getIsRequired,
    required this.getReadOnly,
    required this.formFieldKeys,
    this.cameraResolution = CameraResolution.max,
    this.rebuildDependencies,
  });

  final JsonSchema jsonSchema;
  final String? jsonKey;
  final UiSchema? uiSchema;
  final dynamic formData;
  final JsonSchema? previousSchema;
  final String? previousJsonKey;
  final dynamic previousFormData;
  final int? arrayIndex;
  final String? Function() getTitle;
  final String? Function() getDescription;
  final dynamic Function() getDefaultValue;
  final bool Function() getIsRequired;
  final bool Function() getReadOnly;
  final CameraResolution cameraResolution;
  final List<GlobalKey<FormFieldState<dynamic>>>? formFieldKeys;
  final void Function(String?)? rebuildDependencies;

  @override
  State<_UiWidget> createState() => _UiWidgetState();
}

class _UiWidgetState extends State<_UiWidget> {
  late final GlobalKey<FormFieldState<dynamic>>? _formFieldKey;

  @override
  void initState() {
    super.initState();

    if (widget.formFieldKeys != null) {
      _formFieldKey = GlobalKey<FormFieldState<dynamic>>();
      widget.formFieldKeys!.add(_formFieldKey!);
    } else {
      _formFieldKey = null;
    }
  }

  @override
  void dispose() {
    widget.formFieldKeys?.removeLast();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultValue = widget.getDefaultValue();

    if (defaultValue != null) {
      _setValueInFormData(defaultValue);
    }

    final initialStringValue = defaultValue?.toString();

    if (_isDropdown()) {
      return _buildDropdown(initialStringValue);
    } else if (_isRadioGroup()) {
      return _buildRadioGroup(initialStringValue);
    } else if (_isRadio()) {
      final initialValue = widget.getDefaultValue is String
          ? bool.tryParse(widget.getDefaultValue as String)
          : null;
      return _buildRadio(initialValue);
    } else if (_isCheckbox()) {
      final initialValue = widget.getDefaultValue is String
          ? [bool.tryParse(widget.getDefaultValue as String)!]
          : null;
      return _buildCheckbox(initialValue);
    } else if (_isCheckboxGroup()) {
      final initialValues = (widget.formData as List).cast<String>();
      return _buildCheckboxGroup(initialValues);
    } else if (_isTextArea()) {
      return _buildTextArea(initialStringValue);
    } else if (_isUpDown()) {
      return _buildUpDown(initialStringValue);
    } else if (_isFile()) {
      return _buildFile(initialStringValue);
    } else if (_isDate()) {
      return _buildDate(context, initialStringValue);
    } else if (_isDateTime()) {
      return _buildDateTime(context, initialStringValue);
    } else if (_isPhone()) {
      return _buildPhoneText(initialStringValue);
    } else {
      return _buildText(initialStringValue);
    }
  }

  Future<void> _setValueInFormData(dynamic value) async {
    if (value is String && value.isEmpty) {
      if (widget.formData is Map) {
        (widget.formData as Map).remove(widget.jsonKey);
      } else {
        (widget.formData as List)[widget.arrayIndex!] = null;
      }
    } else if (value is List<String>) {
      (widget.formData as List).clear();
      (widget.formData as List).addAll(value);
    } else if (value is XFile) {
      final base64File = await value.getBase64();
      if (widget.formData is Map) {
        (widget.formData as Map)[widget.jsonKey!] = base64File;
      } else {
        (widget.formData as List)[widget.arrayIndex!] = base64File;
      }
    } else {
      if (widget.formData is Map) {
        (widget.formData as Map)[widget.jsonKey!] = value;
      } else {
        (widget.formData as List)[widget.arrayIndex!] = value;
      }
    }
  }

  bool _isDropdown() =>
      widget.uiSchema?.widget == UiType.select ||
      (widget.uiSchema?.widget == null && widget.jsonSchema.enumValue != null);

  Widget _buildDropdown(String? initialValue) {
    final title = widget.getTitle();

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: _CustomFormFieldValidator<String>(
        formFieldKey: _formFieldKey,
        isEnabled: widget.getIsRequired(),
        initialValue: initialValue,
        isEmpty: (value) => value.isEmpty,
        childFormBuilder: (field) {
          return _CustomDropdownMenu<String>(
            readOnly: widget.getReadOnly(),
            label: title != null
                ? "$title${widget.getIsRequired() ? '*' : ''}"
                : null,
            labelStyle: widget.getIsRequired()
                ? const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  )
                : null,
            itemLabel: (_, item) => item,
            items: widget.jsonSchema.enumValue!,
            selectedItem: initialValue,
            onDropdownValueSelected: (value) {
              _onFieldChangedWithValidator<String>(field, value);
            },
          );
        },
      ),
    );
  }

  bool _isRadioGroup() => widget.uiSchema?.widget == UiType.radio;

  Widget _buildRadioGroup(
    String? initialValue,
  ) {
    final title = widget.getTitle();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _CustomFormFieldValidator<String>(
        formFieldKey: _formFieldKey,
        isEnabled: widget.getIsRequired(),
        initialValue: initialValue,
        isEmpty: (value) => value.isEmpty,
        childFormBuilder: (field) {
          return _CustomRadioGroup<String>(
            readOnly: widget.getReadOnly(),
            label: title != null
                ? "$title${widget.getIsRequired() ? '*' : ''}"
                : null,
            labelStyle: widget.getIsRequired()
                ? const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  )
                : null,
            sublabel: widget.getDescription(),
            itemLabel: (_, item) => item,
            items: widget.jsonSchema.enumValue!,
            initialItem: initialValue,
            onRadioValueSelected: (value) {
              _onFieldChangedWithValidator<String>(field, value);
            },
          );
        },
      ),
    );
  }

  bool _isRadio() =>
      widget.uiSchema?.widget != UiType.checkbox &&
      widget.jsonSchema.type == JsonType.boolean;

  Widget _buildRadio(
    bool? initialValue,
  ) {
    final title = widget.getTitle();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _CustomFormFieldValidator<bool>(
        formFieldKey: _formFieldKey,
        isEnabled: widget.getIsRequired(),
        initialValue: initialValue,
        childFormBuilder: (field) {
          return _CustomRadioGroup<bool>(
            readOnly: widget.getReadOnly(),
            label: title != null
                ? "$title${widget.getIsRequired() ? '*' : ''}"
                : null,
            labelStyle: widget.getIsRequired()
                ? const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  )
                : null,
            sublabel: widget.getDescription(),
            itemLabel: (_, item) => item ? 'Yes' : 'No',
            items: const [false, true],
            initialItem: initialValue,
            onRadioValueSelected: (value) {
              _onFieldChangedWithValidator<bool>(field, value);
            },
          );
        },
      ),
    );
  }

  bool _isCheckbox() =>
      widget.uiSchema?.widget != UiType.radio &&
      widget.jsonSchema.type == JsonType.boolean;

  Widget _buildCheckbox(
    List<bool>? initialValue,
  ) {
    final title = widget.getTitle();

    return _CustomFormFieldValidator<bool>(
      formFieldKey: _formFieldKey,
      isEnabled: widget.getIsRequired(),
      initialValue: initialValue?.first,
      childFormBuilder: (field) {
        return _CustomCheckboxGroup<bool>(
          readOnly: widget.getReadOnly(),
          jsonKey: widget.jsonKey!,
          label: null,
          labelStyle: widget.getIsRequired()
              ? const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                )
              : null,
          sublabel: widget.getDescription(),
          itemLabel: (_, item) => title != null
              ? "$title${widget.getIsRequired() ? '*' : ''}"
              : (item ? 'Yes' : 'No'),
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

  bool _isCheckboxGroup() => widget.uiSchema?.widget == UiType.checkboxes;

  Widget _buildCheckboxGroup(
    List<String> initialValues,
  ) {
    final title = widget.getTitle();

    return _CustomFormFieldValidator<List<String>>(
      formFieldKey: _formFieldKey,
      isEnabled: widget.getIsRequired(),
      initialValue: initialValues,
      isEmpty: (value) => value.isEmpty,
      childFormBuilder: (field) {
        return _CustomCheckboxGroup<String>(
          readOnly: widget.getReadOnly(),
          jsonKey: widget.jsonKey!,
          label: title != null
              ? "$title${widget.getIsRequired() ? '*' : ''}"
              : null,
          labelStyle: widget.getIsRequired()
              ? const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                )
              : null,
          sublabel: widget.getDescription(),
          items: widget.jsonSchema.enumValue!,
          itemLabel: (_, item) => item,
          initialItems: initialValues,
          onCheckboxValuesSelected: (value) {
            _onFieldChangedWithValidator<List<String>>(field, value);
          },
        );
      },
    );
  }

  bool _isTextArea() => widget.uiSchema?.widget == UiType.textarea;

  Widget _buildTextArea(
    String? initialValue,
  ) {
    final validators = <String? Function(String?)>[];

    _addMinLengthValidator(validators);

    _addMaxLengthValidator(validators);

    final title = widget.getTitle();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        formFieldKey: _formFieldKey,
        readOnly: widget.getReadOnly(),
        onChanged: _onFieldChanged,
        hasRequiredValidator: widget.getIsRequired(),
        labelText:
            title != null ? "$title${widget.getIsRequired() ? '*' : ''}" : null,
        minLines: 4,
        maxLines: null,
        defaultValue: initialValue,
        emptyValue: widget.uiSchema?.emptyValue,
        placeholder: widget.uiSchema?.placeholder,
        helperText: widget.uiSchema?.help,
        autofocus: widget.uiSchema?.autofocus,
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

  bool _isUpDown() => widget.uiSchema?.widget == UiType.updown;

  Widget _buildUpDown(String? initialValue) {
    final title = widget.getTitle();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        formFieldKey: _formFieldKey,
        readOnly: widget.getReadOnly(),
        onChanged: _onFieldChanged,
        hasRequiredValidator: widget.getIsRequired(),
        labelText:
            title != null ? "$title${widget.getIsRequired() ? '*' : ''}" : null,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        defaultValue: initialValue,
        emptyValue: widget.uiSchema?.emptyValue,
        placeholder: widget.uiSchema?.placeholder,
        helperText: widget.uiSchema?.help,
        autofocus: widget.uiSchema?.autofocus,
      ),
    );
  }

  bool _isFile() =>
      widget.uiSchema?.widget == UiType.file ||
      widget.jsonSchema.format == JsonSchemaFormat.dataUrl;

  Widget _buildFile(String? initialValue) {
    final acceptedExtensions = (widget.uiSchema?.options?.containsKey(
              UiOptions.accept.name,
            ) ??
            false)
        ? (widget.uiSchema?.options?[UiOptions.accept.name] as String?)
            ?.split(',')
        : null;

    final hasFilePicker = !(widget.uiSchema?.options?.containsKey(
              UiOptions.explorer.name,
            ) ??
            true) ||
        (widget.uiSchema?.options?[UiOptions.explorer.name] as bool? ?? true);

    final hasCameraButton = (widget.uiSchema?.options?.containsKey(
              UiOptions.camera.name,
            ) ??
            false) &&
        (widget.uiSchema?.options?[UiOptions.camera.name] as bool);

    final isPhotoAllowed = !(widget.uiSchema?.options?.containsKey(
              UiOptions.photo.name,
            ) ??
            true) ||
        (widget.uiSchema?.options?[UiOptions.photo.name] as bool? ?? true);

    final isVideoAllowed = (widget.uiSchema?.options?.containsKey(
              UiOptions.video.name,
            ) ??
            false) &&
        (widget.uiSchema?.options?[UiOptions.video.name] as bool);

    final resolution = (widget.uiSchema?.options?.containsKey(
              UiOptions.resolution.name,
            ) ??
            false)
        ? (widget.uiSchema?.options?['resolution'] as String?).cameraResolution
        : widget.cameraResolution;

    final title = widget.getTitle();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _CustomFormFieldValidator<String?>(
        formFieldKey: _formFieldKey,
        isEnabled: widget.getIsRequired(),
        initialValue: initialValue,
        isEmpty: (value) {
          return value == null || value.isEmpty == true;
        },
        childFormBuilder: (field) {
          return _CustomFileUpload(
            readOnly: widget.getReadOnly(),
            acceptedExtensions: acceptedExtensions,
            hasFilePicker: hasFilePicker,
            hasCameraButton: hasCameraButton,
            title: title != null
                ? "$title${widget.getIsRequired() ? '*' : ''}"
                : null,
            onFileChosen: (value) async {
              await _onFieldChangedWithValidator<String?>(field, value);
            },
            isPhotoAllowed: isPhotoAllowed,
            isVideoAllowed: isVideoAllowed,
            fileData: initialValue,
            resolution: resolution ?? widget.cameraResolution,
          );
        },
      ),
    );
  }

  bool _isDate() => widget.uiSchema?.widget == UiType.date;

  Widget _buildDate(
    BuildContext context,
    String? initialValue,
  ) {
    final isReadOnly = widget.getReadOnly();

    final title = widget.getTitle();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        formFieldKey: _formFieldKey,
        onChanged: _onFieldChanged,
        labelText: title != null
            ? "$title${widget.getIsRequired() ? '*' : ''}"
            : title,
        defaultValue: initialValue,
        emptyValue: widget.uiSchema?.emptyValue,
        placeholder: widget.uiSchema?.placeholder,
        helperText: widget.uiSchema?.help,
        autofocus: widget.uiSchema?.autofocus,
        readOnly: true,
        canRequestFocus: false,
        mouseCursor:
            isReadOnly ? SystemMouseCursors.text : SystemMouseCursors.click,
        hasRequiredValidator: widget.getIsRequired(),
        onTap: isReadOnly
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

  bool _isDateTime() => widget.uiSchema?.widget == UiType.dateTime;

  Widget _buildDateTime(
    BuildContext context,
    String? initialValue,
  ) {
    final isReadOnly = widget.getReadOnly();

    final title = widget.getTitle();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        formFieldKey: _formFieldKey,
        onChanged: _onFieldChanged,
        labelText:
            title != null ? "$title${widget.getIsRequired() ? '*' : ''}" : null,
        defaultValue: initialValue,
        emptyValue: widget.uiSchema?.emptyValue,
        placeholder: widget.uiSchema?.placeholder,
        helperText: widget.uiSchema?.help,
        autofocus: widget.uiSchema?.autofocus,
        readOnly: true,
        canRequestFocus: false,
        mouseCursor:
            isReadOnly ? SystemMouseCursors.text : SystemMouseCursors.click,
        hasRequiredValidator: widget.getIsRequired(),
        onTap: isReadOnly
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

  bool _isPhone() =>
      (widget.uiSchema?.options?.containsKey(UiOptions.inputType.name) ??
          false) &&
      widget.uiSchema!.options![UiOptions.inputType.name] == InputType.tel;

  Widget _buildPhoneText(String? initialValue) {
    final title = widget.getTitle();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomPhoneFormField(
        formFieldKey: _formFieldKey,
        enabled: !widget.getReadOnly(),
        onChanged: _onFieldChanged,
        labelText:
            title != null ? "$title${widget.getIsRequired() ? '*' : ''}" : null,
        defaultValue: initialValue,
        emptyValue: widget.uiSchema?.emptyValue,
        placeholder: widget.uiSchema?.placeholder,
        helperText: widget.uiSchema?.help,
        autofocus: widget.uiSchema?.autofocus,
        hasRequiredValidator: widget.getIsRequired(),
      ),
    );
  }

  Widget _buildText(String? initialValue) {
    final validators = <String? Function(String?)>[];

    final isEmailTextFormField =
        widget.jsonSchema.format == JsonSchemaFormat.email;

    final isNumberTextFormFiled = widget.jsonSchema.type == JsonType.number;

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

    final title = widget.getTitle();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _CustomTextFormField(
        formFieldKey: _formFieldKey,
        readOnly: widget.getReadOnly(),
        onChanged: _onFieldChanged,
        labelText:
            title != null ? "$title${widget.getIsRequired() ? '*' : ''}" : null,
        defaultValue: initialValue,
        emptyValue: widget.uiSchema?.emptyValue,
        helperText: widget.uiSchema?.help,
        autofocus: widget.uiSchema?.autofocus,
        maxLines: widget.uiSchema?.maxLines == 0
            ? null
            : widget.uiSchema?.maxLines ?? 1,
        inputFormatters: isNumberTextFormFiled
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        keyboardType: isEmailTextFormField
            ? TextInputType.emailAddress
            : isNumberTextFormFiled
                ? TextInputType.number
                : null,
        hasRequiredValidator: widget.getIsRequired(),
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
    _rebuildFormIfHasOneOfDependencies<T>(value);
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
  }

  void _addMinLengthValidator(List<String? Function(String?)> validators) {
    if (widget.jsonSchema.minLength != null) {
      validators.add((value) {
        if (value != null && value.length < widget.jsonSchema.minLength!) {
          return 'Must have at least ${widget.jsonSchema.minLength} characters';
        }

        return null;
      });
    }
  }

  void _addMaxLengthValidator(List<String? Function(String? p1)> validators) {
    if (widget.jsonSchema.maxLength != null) {
      validators.add((value) {
        if (value != null && value.length > widget.jsonSchema.maxLength!) {
          return 'Must have ${widget.jsonSchema.minLength} characters as much';
        }

        return null;
      });
    }
  }

  void _rebuildFormIfHasOneOfDependencies<T>(T value) {
    final hasDependencies = widget.previousSchema?.dependencies != null &&
        widget.previousSchema!.dependencies!.keys.contains(widget.jsonKey);

    if (hasDependencies) {
      widget.rebuildDependencies?.call(widget.previousJsonKey);
    }
  }
}
