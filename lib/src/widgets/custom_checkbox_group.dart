part of '../jsonschema_form_builder.dart';

class _CustomCheckboxGroup extends StatefulWidget {
  const _CustomCheckboxGroup({
    required this.jsonKey,
    required this.label,
    required this.items,
    required this.initialItems,
    required this.onCheckboxValuesSelected,
  });

  final String? label;
  final List<String> items;
  final List<String>? initialItems;
  final void Function(List<String>) onCheckboxValuesSelected;
  final String jsonKey;

  @override
  State<_CustomCheckboxGroup> createState() => _CustomCheckboxGroupState();
}

class _CustomCheckboxGroupState extends State<_CustomCheckboxGroup> {
  late final List<String> _selectedItems;

  @override
  void initState() {
    super.initState();

    if (widget.initialItems != null) {
      _selectedItems = List<String>.from(widget.initialItems!);
    } else {
      _selectedItems = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Wrap(
        children: widget.items
            .map(
              (item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    splashRadius: 0,
                    value: _selectedItems.contains(item),
                    onChanged: (value) {
                      if (value ?? false) {
                        _selectedItems.add(item);
                      } else {
                        _selectedItems
                            .removeWhere((element) => element == item);
                      }

                      widget.onCheckboxValuesSelected(
                        _selectedItems,
                      );

                      setState(() {});
                    },
                  ),
                  Text(item),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
