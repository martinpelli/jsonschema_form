import 'dart:async';
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
  JsonschemaForm _jsonschemaForm = JsonschemaForm(schemaJson: {}, uiJson: {});

  bool _isLoading = false;

  Map<String, dynamic>? _decodedJsonSchema;
  Map<String, dynamic>? _decodedUiSchema;
  Map<String, dynamic>? _decodedFormData;

  final _fileNames = [
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
    "problem_and_root_cause",
    "jobsite_images",
    "permanent_materials_request",
    "site_safety",
    "permanent_solution"
  ];

  String? selectedFileName;

  final _jsonschemaFormKey = GlobalKey<JsonschemaFormBuilderState>();

  @override
  void initState() {
    super.initState();

    selectedFileName = _fileNames.first;
    try {
      _loadJson();
    } catch (e) {
      log(e.toString());
    }
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

    _decodedJsonSchema = decodedJson["jsonSchema"] as Map<String, dynamic>?;
    _decodedUiSchema = decodedJson["uiSchema"] as Map<String, dynamic>?;
    _decodedFormData = decodedJson["formData"] as Map<String, dynamic>?;

    _jsonschemaForm = JsonschemaForm(
      schemaJson: _decodedJsonSchema ?? {},
      uiJson: _decodedUiSchema ?? {},
      formData: _decodedFormData ?? {},
    );

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
                child: Column(
                  children: [
                    Expanded(
                      child: JsonschemaFormBuilder(
                          key: _jsonschemaFormKey,
                          jsonSchemaForm: _jsonschemaForm,
                          createArrayItemAs: CreateArrayItemAs.dialog,
                          suffixFormDataMapper: (current, old) {
                            if (current is Map &&
                                current.containsKey('jobsiteImages') &&
                                old != null) {
                              for (int i = 0;
                                  i < (current['jobsiteImages'].length);
                                  i++) {
                                var currentImage = current['jobsiteImages'][i];
                                var oldImage = old['jobsiteImages'][i];

                                // If the file in current is a URL (starts with "http" or "https"), replace it with the "id" from old
                                if (currentImage['file']
                                    .toString()
                                    .startsWith('http')) {
                                  // Replace the URL with the id from the old image
                                  currentImage['file'] =
                                      "s3file:${oldImage['file']['id']}";
                                }
                              }
                            }
                            return current;
                          },
                          prefixFormDataMapper: (key, data) {
                            if (key == 'file' && data is Map) {
                              return data['getUrl'];
                            }
                            return data;
                          }),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        final clearedFormData =
                            _jsonschemaFormKey.currentState?.submit();

                        if (clearedFormData != null) {
                          _decodedFormData = clearedFormData;
                          log(clearedFormData.toString());
                        }
                      },
                      child: const Text('Submit'),
                    ),
                  ],
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
