part of '../jsonschema_form_builder.dart';

class _CustomTextFormField extends StatelessWidget {
  const _CustomTextFormField({
    this.labelText,
    this.keyboardType,
    this.inputFormatters,
    this.minLines,
    this.maxLines = 1,
  });

  final String? labelText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: labelText),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      minLines: minLines,
      maxLines: maxLines,
    );
  }
}
