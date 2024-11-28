import 'package:flutter/material.dart';
import 'package:jsonschema_form/jsonschema_form.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: const _Form())),
          ),
        ));
  }
}

class _Form extends StatefulWidget {
  const _Form();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  JsonschemaForm? _jsonschemaForm;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _getJson();
  }

  Future<void> _getJson() async {
    _isLoading = true;

    _jsonschemaForm = JsonschemaForm();

    await _jsonschemaForm!
        .initFromJsonAsset('assets/without_data/ui_options.json');

    _isLoading = false;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    if (_jsonschemaForm == null) {
      return const Text("Error while parsing json");
    }

    return JsonschemaFormBuilder(
      jsonSchemaForm: _jsonschemaForm!,
      onFormSubmitted: (formData) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(formData.toString()),
          backgroundColor: Colors.green,
        ));
      },
    );
  }
}
