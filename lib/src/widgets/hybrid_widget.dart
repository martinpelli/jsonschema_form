part of '../jsonschema_form_builder.dart';

/// Allows easly wrapping a widget in a state or stateless widget, this to avoid
/// calling _FormSection multiple times
class _HybridWidget extends StatelessWidget {
  const _HybridWidget.stateful({
    required this.buildFormSection,
    required this.jsonKey,
  })  : isStateful = true,
        formSection = null;

  const _HybridWidget.stateless({
    required this.formSection,
  })  : isStateful = false,
        jsonKey = null,
        buildFormSection = null;

  final bool isStateful;
  final _FormSection? formSection;
  final Widget Function()? buildFormSection;
  final String? jsonKey;

  static void rebuildFormSection(BuildContext context, String? jsonKey) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<_InheritedProvider>();

    final state = provider?.data?.getState(jsonKey);

    state?.rebuildFormSection();
  }

  @override
  Widget build(BuildContext context) {
    return isStateful
        ? _StatefulWrapper(
            buildFormSection: buildFormSection!,
            jsonKey: jsonKey,
          )
        : formSection!;
  }
}

class _StatefulWrapper extends StatefulWidget {
  const _StatefulWrapper({
    required this.buildFormSection,
    required this.jsonKey,
  });

  final Widget Function() buildFormSection;
  final String? jsonKey;

  @override
  State<_StatefulWrapper> createState() => _StatefulWrapperState();
}

class _StatefulWrapperState extends State<_StatefulWrapper> {
  static final Map<String, _StatefulWrapperState> _instances = {};

  @override
  void initState() {
    super.initState();
    _instances[widget.jsonKey.toString()] = this;
  }

  @override
  void dispose() {
    _instances.remove(widget.jsonKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProvider(data: this, child: widget.buildFormSection());
  }

  void rebuildFormSection() {
    setState(() {});
  }

  _StatefulWrapperState? getState(String? jsonKey) {
    return _instances[jsonKey.toString()];
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
