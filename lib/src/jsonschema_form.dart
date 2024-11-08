import 'dart:convert';
import 'dart:io';

import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/ui_schema.dart';

/// {@template jsonschema_form}
/// A Flutter package capable of using JSON Schema to declaratively build and
/// customize Flutter forms
/// {@endtemplate}
class JsonschemaForm {
  /// {@macro jsonschema_form}
  JsonschemaForm() {
    String fixture(String name) => File(
          '/Users/martinpelli/Development/sandobx/flutter_jsonschema_form/packages/jsonschema_form/jsons/$name.json',
        ).readAsStringSync();

    final decodedJson =
        json.decode(fixture('first_form_example')) as Map<String, dynamic>;

    jsonSchema =
        JsonSchema.fromJson(decodedJson['jsonSchema'] as Map<String, dynamic>);

    uiSchema =
        UiSchema.fromJson(decodedJson['uiSchema'] as Map<String, dynamic>);
  }

  /// Contains the decoded Json Schema that tells how to build the layout
  late final JsonSchema jsonSchema;

  /// Contains the decoded UI Schema that tells how to build the UI
  late final UiSchema uiSchema;
}
