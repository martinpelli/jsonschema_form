part of '../jsonschema_form_builder.dart';

class _CustomCheckboxGroup<T> extends StatefulWidget {
  const _CustomCheckboxGroup({
    required this.jsonKey,
    required this.label,
    required this.sublabel,
    required this.labelStyle,
    required this.items,
    required this.itemLabel,
    required this.initialItems,
    required this.onCheckboxValuesSelected,
    required this.readOnly,
  });

  final String? label;
  final String? sublabel;
  final TextStyle? labelStyle;
  final List<T> items;
  final String Function(int index, T item) itemLabel;
  final List<T>? initialItems;
  final void Function(List<T>) onCheckboxValuesSelected;
  final String jsonKey;
  final bool readOnly;

  @override
  State<_CustomCheckboxGroup<T>> createState() => _CustomCheckboxGroupState();
}

class _CustomCheckboxGroupState<T> extends State<_CustomCheckboxGroup<T>> {
  late final List<T> _selectedItems;

  @override
  void initState() {
    super.initState();

    if (widget.initialItems != null) {
      _selectedItems = List<T>.from(widget.initialItems!);
    } else {
      _selectedItems = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Wrap(
          children: widget.items
              .mapIndexed(
                (index, item) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      splashRadius: 0,
                      value: _selectedItems.contains(item),
                      fillColor: WidgetStateColor.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.1);
                        }

                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(context).colorScheme.secondary;
                        }
                        return Colors.transparent;
                      }),
                      onChanged: widget.readOnly
                          ? null
                          : (value) {
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
                    Text(widget.itemLabel(index, item)),
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
