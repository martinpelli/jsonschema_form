part of '../jsonschema_form_builder.dart';

class _CustomRadioGroup<T> extends StatefulWidget {
  const _CustomRadioGroup({
    required this.label,
    required this.sublabel,
    required this.labelStyle,
    required this.items,
    required this.initialItem,
    required this.itemLabel,
    required this.onRadioValueSelected,
    required this.readOnly,
    required this.isVertical,
  });

  final String? label;
  final String? sublabel;
  final TextStyle? labelStyle;
  final List<T> items;
  final T? initialItem;
  final String Function(int index, T item) itemLabel;
  final void Function(T) onRadioValueSelected;
  final bool readOnly;
  final bool isVertical;

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
  void didUpdateWidget(covariant _CustomRadioGroup<T> oldWidget) {
    _selectedItem = widget.initialItem;

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItems();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(widget.label!, style: widget.labelStyle),
          ),
        if (widget.sublabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              widget.sublabel!,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        if (widget.isVertical)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          )
        else
          Wrap(children: items),
      ],
    );
  }

  List<Widget> _getItems() => widget.items
      .mapIndexed(
        (index, item) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio(
              hoverColor: widget.readOnly ? Colors.transparent : null,
              fillColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.1);
                }
                return Theme.of(context).colorScheme.primary;
              }),
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
            if (!widget.isVertical) const SizedBox(width: 5),
          ],
        ),
      )
      .toList();
}
