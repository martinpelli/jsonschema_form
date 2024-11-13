part of '../jsonschema_form_builder.dart';

class _CustomTextFormField extends StatefulWidget {
  const _CustomTextFormField({
    required this.onChanged,
    this.labelText,
    this.keyboardType,
    this.inputFormatters,
    this.minLines,
    this.maxLines = 1,
    this.defaultValue,
    this.emptyValue,
    this.placeholder,
    this.autofocus = false,
    this.hasValidator = false,
  });

  final void Function(String) onChanged;
  final String? labelText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines;
  final int? maxLines;
  final String? defaultValue;
  final String? emptyValue;
  final String? placeholder;
  final bool? autofocus;
  final bool hasValidator;

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
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: widget.autofocus ?? false,
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.placeholder,
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
      validator: widget.hasValidator
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }

              return null;
            }
          : null,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
