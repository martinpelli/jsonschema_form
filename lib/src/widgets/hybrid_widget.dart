part of '../jsonschema_form_builder.dart';

/// Allows easly wrapping a widget in a state or stateless widget, this to avoid
/// calling _FormSection multiple times
class _HybridWidget extends StatelessWidget {
  const _HybridWidget.stateful({
    required this.buildFormSection,
    required this.jsonKey,
    required this.stateKey,
    required this.stateKeys,
  })  : isStateful = true,
        formSection = null;

  const _HybridWidget.stateless({
    required this.formSection,
  })  : isStateful = false,
        stateKey = null,
        jsonKey = null,
        buildFormSection = null,
        stateKeys = null;

  final bool isStateful;
  final _FormSection? formSection;
  final Widget Function()? buildFormSection;
  final String? jsonKey;
  final GlobalKey<_StatefulWrapperState>? stateKey;
  final List<GlobalKey<_StatefulWrapperState>>? stateKeys;

  @override
  Widget build(BuildContext context) {
    return isStateful
        ? _StatefulWrapper(
            key: stateKey,
            stateKeys: stateKeys!,
            buildFormSection: buildFormSection!,
            jsonKey: jsonKey,
          )
        : formSection!;
  }
}

class _StatefulWrapper extends StatefulWidget {
  const _StatefulWrapper({
    required this.stateKeys,
    required this.buildFormSection,
    required this.jsonKey,
    super.key,
  });

  final List<GlobalKey<_StatefulWrapperState>> stateKeys;
  final Widget Function() buildFormSection;
  final String? jsonKey;

  @override
  State<_StatefulWrapper> createState() => _StatefulWrapperState();
}

class _StatefulWrapperState extends State<_StatefulWrapper> {
  @override
  void dispose() {
    widget.stateKeys.removeWhere(
      (stateKey) =>
          stateKey.currentState != null &&
          stateKey.currentState!.widget.jsonKey == widget.jsonKey,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.buildFormSection();
  }

  void rebuildFormSection() {
    setState(() {});
  }
}
