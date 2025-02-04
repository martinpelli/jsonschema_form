part of '../jsonschema_form_builder.dart';

class _CustomTextFormField extends StatefulWidget {
  const _CustomTextFormField({
    required this.formFieldKey,
    required this.onChanged,
    this.labelText,
    this.helperText,
    this.keyboardType,
    this.inputFormatters,
    this.minLines,
    this.maxLines = 1,
    this.defaultValue,
    this.emptyValue,
    this.placeholder,
    this.autofocus = false,
    this.hasRequiredValidator = false,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.canRequestFocus = true,
    this.mouseCursor,
  });

  final GlobalKey<FormFieldState<dynamic>> formFieldKey;
  final void Function(String) onChanged;
  final String? labelText;
  final String? helperText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines;
  final int? maxLines;
  final String? defaultValue;
  final String? emptyValue;
  final String? placeholder;
  final bool? autofocus;
  final bool hasRequiredValidator;
  final String? Function(String?)? validator;
  final bool readOnly;
  final FutureOr<String?> Function()? onTap;
  final bool canRequestFocus;
  final MouseCursor? mouseCursor;

  @override
  State<_CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<_CustomTextFormField> {
  final _controller = TextEditingController();

  @override
  void initState() {
    if (widget.defaultValue != null) _controller.text = widget.defaultValue!;

    if (_controller.text.isEmpty && widget.emptyValue != null) {
      _controller.text = widget.emptyValue!;
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant _CustomTextFormField oldWidget) {
    if (widget.defaultValue == null) {
      /// When oneOf has changed, it will rebuild the whole form so that all
      /// controllers get cleared
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.clear());
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: widget.formFieldKey,
      canRequestFocus: !widget.readOnly,
      mouseCursor: widget.mouseCursor,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus ?? false,
      controller: _controller,
      decoration: InputDecoration(
        hoverColor: widget.readOnly ? Colors.transparent : null,
        fillColor: widget.readOnly
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
            : null,
        filled: widget.readOnly,
        labelText: widget.labelText,
        hintText: widget.placeholder,
        helperText: widget.helperText,
        labelStyle: widget.hasRequiredValidator
            ? const TextStyle(fontWeight: FontWeight.bold)
            : null,
      ),
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      onChanged: (value) {
        if (value.isEmpty && widget.emptyValue != null) {
          _controller.text = widget.emptyValue!;
        }
        widget.onChanged(value);
      },
      validator: widget.hasRequiredValidator
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }

              if (widget.validator != null) {
                return widget.validator!(value);
              }

              return null;
            }
          : widget.validator,
      onTap: widget.onTap == null
          ? null
          : () async {
              final result = await widget.onTap!();
              _controller.text = result ?? '';
            },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
