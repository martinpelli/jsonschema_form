import 'dart:convert';
import 'dart:developer';

import 'package:example/json_pretifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jsonschema_form/jsonschema_form.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Jsonschema Form Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
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
  final _jsonschemaForm = JsonschemaForm();

  bool _isLoading = false;

  Map<String, dynamic>? _decodedJsonSchema;
  Map<String, dynamic>? _decodedUiSchema;
  Map<String, dynamic>? _decodedFormData;

  final _fileNames = [
    "jobsite_images",
    "simple_with_data",
    "ui_options",
    "deep_level_with_data",
    "one_of_with_data",
    "property_dependencies_with_data",
    "schema_dependencies_with_data",
    "files",
    "problem_identification_with_data",
    "site_safety_with_data",
    "temporary_steps_and_solution_with_data",
    "array_with_additional_items_with_data",
    "array_with_data",
    "array_with_min_and_max_items_with_data",
    "array_with_multiple_choice_with_data",
    "array_of_files",
    "materials_request",
    "problem_and_root_cause"
  ];

  String? selectedFileName;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    selectedFileName = _fileNames.first;

    _loadJson();
  }

  Future<void> _loadJson() async {
    if (selectedFileName == null) return;

    setState(() {
      _isLoading = true;
    });

    final jsonFileHasFormData = selectedFileName!.endsWith("data");

    final relativePath = jsonFileHasFormData
        ? "assets/with_data/$selectedFileName.json"
        : "assets/without_data/$selectedFileName.json";

    final jsonString = await rootBundle.loadString(relativePath);
    final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;

    _jsonschemaForm.initFromDecodedJson(decodedJson);

    _decodedJsonSchema = decodedJson["jsonSchema"] as Map<String, dynamic>?;
    _decodedUiSchema = decodedJson["uiSchema"] as Map<String, dynamic>?;
    _decodedFormData = decodedJson["formData"] as Map<String, dynamic>?;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        _buildButtons(context),
        const SizedBox(height: 15),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _JsonsTexts(
                jsonSchema: _decodedJsonSchema,
                uiSchema: _decodedUiSchema,
                formData: _decodedFormData,
              ),
              const SizedBox(width: 50),
              Container(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 600),
                width: MediaQuery.sizeOf(context).width * 0.4,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      JsonschemaFormBuilder(
                        jsonSchemaForm: _jsonschemaForm,
                        formKey: _formKey,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          final isFormValid =
                              _formKey.currentState?.validate() ?? false;

                          if (isFormValid && _jsonschemaForm.formData != null) {
                            final newFormData = Map<String, dynamic>.from(
                                _jsonschemaForm.formData!);

                            newFormData.removeEmptySubmaps();
                            log(newFormData.toString());
                            // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            //   content: Text(newFormData.toString()),
                            //   backgroundColor: Colors.green,
                            // ));
                          }
                        },
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Wrap _buildButtons(BuildContext context) {
    return Wrap(
        runSpacing: 10,
        spacing: 10,
        children: _fileNames.map((fileName) {
          final jsonFileHasFormData = fileName.endsWith("data");

          final selectedJsonName = jsonFileHasFormData
              ? fileName.replaceAll('_', ' ').substring(0, fileName.length - 9)
              : fileName.replaceAll('_', ' ');

          return ElevatedButton(
              style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(
                      selectedFileName == fileName
                          ? Theme.of(context).primaryColorLight
                          : null),
                  backgroundColor: WidgetStatePropertyAll(
                      selectedFileName == fileName
                          ? Theme.of(context).primaryColor
                          : null)),
              onPressed: () {
                selectedFileName = fileName;
                _loadJson();
              },
              child: Text(selectedJsonName));
        }).toList());
  }
}

class _JsonsTexts extends StatelessWidget {
  const _JsonsTexts({
    required this.jsonSchema,
    required this.uiSchema,
    required this.formData,
  });

  final Map<String, dynamic>? jsonSchema;
  final Map<String, dynamic>? uiSchema;
  final Map<String, dynamic>? formData;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildJsonSection("jsonSchema", jsonSchema),
          const SizedBox(height: 10),
          _buildJsonSection("uiSchema", uiSchema),
          const SizedBox(height: 10),
          _buildJsonSection("formData", formData),
        ],
      ),
    );
  }

  Widget _buildJsonSection(String title, Map<String, dynamic>? jsonData) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Flexible(
            child: Container(
                width: double.infinity,
                color: Colors.grey.shade100,
                child: JsonPrettifier(jsonInput: jsonData)),
          ),
        ],
      ),
    );
  }
}
