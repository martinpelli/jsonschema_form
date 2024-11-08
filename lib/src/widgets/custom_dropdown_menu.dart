part of '../jsonschema_form_builder.dart';

class _CustomDropdownMenu extends StatefulWidget {
  const _CustomDropdownMenu({
    required this.jsonKey,
    required this.label,
    required this.items,
    required this.onDropdownValueSelected,
  });

  final String jsonKey;
  final String? label;
  final List<String> items;
  final void Function(String, String) onDropdownValueSelected;

  @override
  State<_CustomDropdownMenu> createState() => _CustomDropdownMenuState();
}

class _CustomDropdownMenuState extends State<_CustomDropdownMenu> {
  final TextEditingController colorController = TextEditingController();
  final TextEditingController iconController = TextEditingController();
  String? selectedItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: DropdownMenu<String>(
        enableSearch: false,
        width: double.infinity,
        controller: colorController,
        requestFocusOnTap: true,
        label: widget.label == null ? null : Text(widget.label!),
        onSelected: (String? item) {
          if (item != null) {
            widget.onDropdownValueSelected(widget.jsonKey, item);
          }
          setState(() {
            selectedItem = item;
          });
        },
        dropdownMenuEntries:
            widget.items.map<DropdownMenuEntry<String>>((String item) {
          return DropdownMenuEntry<String>(
            value: item,
            label: item,
            style: MenuItemButton.styleFrom(),
          );
        }).toList(),
      ),
    );
  }
}
