part of '../jsonschema_form_builder.dart';

class _CustomDropdownMenu<T> extends StatefulWidget {
  const _CustomDropdownMenu({
    required this.label,
    required this.labelStyle,
    required this.itemLabel,
    required this.items,
    required this.onDropdownValueSelected,
    required this.readOnly,
    this.selectedItem,
  });

  final String? label;
  final TextStyle? labelStyle;
  final String Function(int index, T item) itemLabel;
  final List<T> items;
  final void Function(T) onDropdownValueSelected;
  final bool readOnly;
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
  void didUpdateWidget(covariant _CustomDropdownMenu<T> oldWidget) {
    _selectedItem = widget.selectedItem;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 5),
      child: DropdownMenu<T>(
        expandedInsets: EdgeInsets.zero,
        inputDecorationTheme: InputDecorationTheme(
          filled: widget.readOnly,
          fillColor: widget.readOnly
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
              : null,
        ),
        enabled: !widget.readOnly,
        enableSearch: false,
        requestFocusOnTap: true,
        label: widget.label == null ? null : Text(widget.label!),
        initialSelection: _selectedItem,
        onSelected: (T? item) {
          if (item != null) {
            if (item == _selectedItem) {
              return;
            }

            _selectedItem = item;
            widget.onDropdownValueSelected(item);
          }
        },
        dropdownMenuEntries:
            widget.items.mapIndexed<DropdownMenuEntry<T>>((int index, T item) {
          return DropdownMenuEntry<T>(
            enabled: !widget.readOnly,
            value: item,
            label: widget.itemLabel(index, item),
            labelWidget: Text(
              widget.itemLabel(index, item),
              style: widget.labelStyle,
            ),
            style: MenuItemButton.styleFrom(alignment: Alignment.center),
          );
        }).toList(),
      ),
    );
  }
}
