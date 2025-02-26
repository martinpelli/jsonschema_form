part of '../jsonschema_form_builder.dart';

/// Allows easly wrapping a widget in a state or stateless widget, this to avoid
/// calling _FormSection multiple times
class _HybridWidget extends StatelessWidget {
  const _HybridWidget.stateful({
    required this.buildFormSection,
    required this.id,
  })  : isStateful = true,
        formSection = null;

  const _HybridWidget.stateless({
    required this.formSection,
  })  : isStateful = false,
        id = null,
        buildFormSection = null;

  final bool isStateful;
  final _FormSection? formSection;
  final Widget Function()? buildFormSection;
  final String? id;

  static void rebuildFormSection(BuildContext context, String id) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<_InheritedProvider>();

    final state = provider?.data?.getState(id);

    state?.rebuildFormSection();
  }

  @override
  Widget build(BuildContext context) {
    return isStateful
        ? _StatefulWrapper(
            buildFormSection: buildFormSection!,
            id: id!,
          )
        : formSection!;
  }
}

class _StatefulWrapper extends StatefulWidget {
  const _StatefulWrapper({
    required this.buildFormSection,
    required this.id,
  });

  final Widget Function() buildFormSection;
  final String id;

  @override
  State<_StatefulWrapper> createState() => _StatefulWrapperState();
}

class _StatefulWrapperState extends State<_StatefulWrapper> {
  static final Map<String, _StatefulWrapperState> _instances = {};

  @override
  void initState() {
    super.initState();
    _instances[widget.id] = this;
  }

  @override
  void dispose() {
    _instances.remove(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProvider(data: this, child: widget.buildFormSection());
  }

  void rebuildFormSection() {
    setState(() {});
  }

  _StatefulWrapperState? getState(String id) {
    return _instances[id];
  }
}

class _InheritedProvider extends InheritedWidget {
  const _InheritedProvider({
    required super.child,
    required this.data,
  });

  final _StatefulWrapperState? data;

  @override
  bool updateShouldNotify(_InheritedProvider oldWidget) => true;
}
