part of '../jsonschema_form_builder.dart';

class _CustomRadioGroup<T> extends StatefulWidget {
  const _CustomRadioGroup({
    required this.jsonKey,
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onRadioValueSelected,
  });

  final String? label;
  final List<T> items;
  final String Function(int index, T item) itemLabel;
  final void Function(String, T) onRadioValueSelected;
  final String jsonKey;

  @override
  State<_CustomRadioGroup<T>> createState() => _CustomRadioGroupState<T>();
}

class _CustomRadioGroupState<T> extends State<_CustomRadioGroup<T>> {
  T? _selectedItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) Text(widget.label!),
        Wrap(
          children: widget.items
              .mapIndexed(
                (index, item) => RadioListTile(
                  value: _selectedItem == item,
                  groupValue: true,
                  title: Text(widget.itemLabel(index, item)),
                  onChanged: (_) {
                    _selectedItem = item;
                    widget.onRadioValueSelected(widget.jsonKey, item);
                    setState(() {});
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
