part of '../jsonschema_form_builder.dart';

class _CustomFormFieldValidator<T> extends StatelessWidget {
  const _CustomFormFieldValidator({
    required this.isEmpty,
    required this.childFormBuilder,
    required this.isEnabled,
  });

  final Widget Function(FormFieldState<T>?) childFormBuilder;

  final bool Function(T) isEmpty;

  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) {
      return childFormBuilder(null);
    }

    return FormField<T>(validator: (value) {
      if (value == null || isEmpty(value)) {
        return 'This field is required';
      }

      return null;
    }, builder: (field) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          childFormBuilder(field),
          if (field.hasError)
            Text(
              field.errorText!,
              style: const TextStyle(color: Colors.red),
            ),
        ],
      );
    });
  }
}
