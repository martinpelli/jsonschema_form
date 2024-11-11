part of '../jsonschema_form_builder.dart';

class _CustomRadioGroup extends StatefulWidget {
  const _CustomRadioGroup({
    required this.jsonKey,
    required this.label,
    required this.items,
    required this.onRadioValueSelected,
  });

  final String? label;
  final List<String> items;
  final void Function(String, String) onRadioValueSelected;
  final String jsonKey;

  @override
  State<_CustomRadioGroup> createState() => _CustomRadioGroupState();
}

class _CustomRadioGroupState extends State<_CustomRadioGroup> {
  String? _selectedItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) Text(widget.label!),
        Wrap(
          children: widget.items
              .map(
                (item) => RadioListTile(
                  value: _selectedItem == item,
                  groupValue: true,
                  title: Text(item),
                  onChanged: (_) {
                    _selectedItem = item;
                    widget.onRadioValueSelected(widget.jsonKey, item);
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
