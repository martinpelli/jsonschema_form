part of '../jsonschema_form_builder.dart';

class _CustomPhoneFormField extends StatefulWidget {
  const _CustomPhoneFormField({
    required this.formFieldKey,
    required this.onChanged,
    this.labelText,
    this.helperText,
    this.defaultValue,
    this.emptyValue,
    this.placeholder,
    this.autofocus = false,
    this.hasRequiredValidator = false,
    this.enabled = false,
  });

  final GlobalKey<FormFieldState<dynamic>>? formFieldKey;
  final void Function(PhoneNumber) onChanged;
  final String? labelText;
  final String? helperText;
  final String? defaultValue;
  final String? emptyValue;
  final String? placeholder;
  final bool? autofocus;
  final bool hasRequiredValidator;
  final bool enabled;

  @override
  State<_CustomPhoneFormField> createState() => _CustomPhoneFormFieldState();
}

class _CustomPhoneFormFieldState extends State<_CustomPhoneFormField> {
  final _controller = PhoneController();

  @override
  void initState() {
    if (widget.defaultValue != null) {
      _controller.value = PhoneNumber.parse(widget.defaultValue!);
    }

    if (_controller.value.international.isEmpty && widget.emptyValue != null) {
      _controller.value = PhoneNumber.parse(widget.emptyValue!);
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant _CustomPhoneFormField oldWidget) {
    if (widget.defaultValue == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.formFieldKey?.currentState?.reset(),
      );
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.value = PhoneNumber.parse(widget.defaultValue!);
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFormField(
      autovalidateMode: AutovalidateMode.disabled,
      key: widget.formFieldKey,
      enabled: widget.enabled,
      autofocus: widget.autofocus ?? false,
      controller: _controller,
      decoration: InputDecoration(
        hoverColor: widget.enabled ? null : Colors.transparent,
        fillColor: widget.enabled
            ? null
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        filled: !widget.enabled,
        labelText: widget.labelText,
        hintText: widget.placeholder,
        helperText: widget.helperText,
        labelStyle: widget.hasRequiredValidator
            ? const TextStyle(fontWeight: FontWeight.bold)
            : null,
      ),
      onChanged: (value) {
        if (value.international.isEmpty && widget.emptyValue != null) {
          _controller.value = PhoneNumber.parse(widget.emptyValue!);
        }
        widget.onChanged(value);
      },
      validator: PhoneValidator.compose([
        if (widget.hasRequiredValidator) PhoneValidator.required(context),
        PhoneValidator.validMobile(context),
      ]),
      countrySelectorNavigator: const CountrySelectorNavigator.bottomSheet(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
