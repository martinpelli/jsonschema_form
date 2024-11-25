part of '../jsonschema_form_builder.dart';

class _CustomRadioGroup<T> extends StatefulWidget {
  const _CustomRadioGroup({
    required this.jsonKey,
    required this.label,
    required this.items,
    required this.initialItem,
    required this.itemLabel,
    required this.onRadioValueSelected,
  });

  final String? label;
  final List<T> items;
  final T? initialItem;
  final String Function(int index, T item) itemLabel;
  final void Function(T) onRadioValueSelected;
  final String jsonKey;

  @override
  State<_CustomRadioGroup<T>> createState() => _CustomRadioGroupState<T>();
}

class _CustomRadioGroupState<T> extends State<_CustomRadioGroup<T>> {
  T? _selectedItem;

  @override
  void initState() {
    super.initState();

    _selectedItem = widget.initialItem;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(widget.label!),
          ),
        Wrap(
          children: widget.items
              .mapIndexed(
                (index, item) => Row(
                  children: [
                    Radio(
                      splashRadius: 0,
                      value: _selectedItem == item,
                      groupValue: true,
                      onChanged: (_) {
                        _selectedItem = item;
                        widget.onRadioValueSelected(item);
                        setState(() {});
                      },
                    ),
                    Text(widget.itemLabel(index, item)),
                  ],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 5),
      ],
    );
  }
}
