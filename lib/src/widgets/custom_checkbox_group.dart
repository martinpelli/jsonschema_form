part of '../jsonschema_form_builder.dart';

class _CustomCheckboxGroup extends StatefulWidget {
  const _CustomCheckboxGroup({
    required this.jsonKey,
    required this.label,
    required this.items,
    required this.onCheckboxValuesSelected,
  });

  final String? label;
  final List<String> items;
  final void Function(String, List<String>) onCheckboxValuesSelected;
  final String jsonKey;

  @override
  State<_CustomCheckboxGroup> createState() => _CustomCheckboxGroupState();
}

class _CustomCheckboxGroupState extends State<_CustomCheckboxGroup> {
  final List<String> _selectedItems = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) Text(widget.label!),
        Wrap(
          children: widget.items
              .map(
                (item) => CheckboxListTile(
                  value: _selectedItems.contains(item),
                  title: Text(item),
                  onChanged: (value) {
                    if (value ?? false) {
                      _selectedItems.add(item);
                    } else {
                      _selectedItems.removeWhere((element) => element == item);
                    }

                    widget.onCheckboxValuesSelected(
                      widget.jsonKey,
                      _selectedItems,
                    );
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
