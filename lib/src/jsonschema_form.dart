import 'dart:convert';
import 'dart:io';

import 'package:jsonschema_form/src/models/json_schema.dart';

/// {@template jsonschema_form}
/// A Flutter package capable of using JSON Schema to declaratively build and
/// customize Flutter forms
/// {@endtemplate}
class JsonschemaForm {
  /// {@macro jsonschema_form}
  JsonschemaForm() {
    String fixture(String name) =>
        File('packages/jsonschema_form/jsons/$name.json').readAsStringSync();

    final decodedJson =
        json.decode(fixture('first_form_example')) as Map<String, dynamic>;

    schema =
        JsonSchema.fromJson(decodedJson['jsonSchema'] as Map<String, dynamic>);
  }

  /// Contains the decoded Json Schema that tells how to build the layout
  late final JsonSchema schema;
}
