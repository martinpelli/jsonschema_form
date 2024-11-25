part of '../jsonschema_form_builder.dart';

class _CustomDropdownMenu<T> extends StatefulWidget {
  const _CustomDropdownMenu({
    required this.label,
    required this.itemLabel,
    required this.items,
    required this.onDropdownValueSelected,
    this.selectedItem,
  });

  final String? label;
  final String Function(int index, T item) itemLabel;
  final List<T> items;
  final void Function(T) onDropdownValueSelected;
  final T? selectedItem;

  @override
  State<_CustomDropdownMenu<T>> createState() => _CustomDropdownMenuState<T>();
}

class _CustomDropdownMenuState<T> extends State<_CustomDropdownMenu<T>> {
  T? _selectedItem;

  @override
  void initState() {
    if (widget.selectedItem != null) {
      _selectedItem = widget.selectedItem;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: LayoutBuilder(
        builder: (context, contraints) {
          return DropdownMenu<T>(
            width: contraints.maxWidth,
            enableSearch: false,
            requestFocusOnTap: true,
            label: widget.label == null ? null : Text(widget.label!),
            initialSelection: _selectedItem,
            onSelected: (T? item) {
              if (item != null) {
                if (item == _selectedItem) {
                  return;
                }

                widget.onDropdownValueSelected(item);
              }

              setState(() {
                _selectedItem = item;
              });
            },
            dropdownMenuEntries: widget.items
                .mapIndexed<DropdownMenuEntry<T>>((int index, T item) {
              return DropdownMenuEntry<T>(
                value: item,
                label: widget.itemLabel(index, item),
                style: MenuItemButton.styleFrom(alignment: Alignment.center),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
