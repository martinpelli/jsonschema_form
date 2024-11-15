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
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 100),
            child: _Form(),
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

  final Map<String, dynamic> _formData = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _getJson();
  }

  Future<void> _getJson() async {
    _isLoading = true;

    _jsonschemaForm = await JsonschemaForm.fromJsonAsset('assets/array.json');

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
      formData: _formData,
      onFormSubmitted: (formData) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(formData.toString()),
          backgroundColor: Colors.green,
        ));
      },
    );
  }
}
