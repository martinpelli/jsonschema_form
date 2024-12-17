part of '../jsonschema_form_builder.dart';

class _CustomRadioGroup<T> extends StatefulWidget {
  const _CustomRadioGroup({
    required this.label,
    required this.labelStyle,
    required this.items,
    required this.initialItem,
    required this.itemLabel,
    required this.onRadioValueSelected,
    required this.readOnly,
  });

  final String? label;
  final TextStyle? labelStyle;
  final List<T> items;
  final T? initialItem;
  final String Function(int index, T item) itemLabel;
  final void Function(T) onRadioValueSelected;
  final bool readOnly;

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
            child: Text(widget.label!, style: widget.labelStyle),
          ),
        Wrap(
          children: widget.items
              .mapIndexed(
                (index, item) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio(
                      splashRadius: 0,
                      value: _selectedItem == item,
                      groupValue: true,
                      onChanged: widget.readOnly
                          ? null
                          : (_) {
                              _selectedItem = item;
                              widget.onRadioValueSelected(item);
                              setState(() {});
                            },
                    ),
                    Text(widget.itemLabel(index, item)),
                    const SizedBox(width: 5),
                  ],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
