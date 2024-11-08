part of '../jsonschema_form_builder.dart';

class _CustomTextFormField extends StatelessWidget {
  const _CustomTextFormField({this.labelText});

  final String? labelText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: labelText),
    );
  }
}
