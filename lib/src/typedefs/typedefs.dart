import 'package:flutter/material.dart';
import 'package:jsonschema_form/src/models/json_schema.dart';
import 'package:jsonschema_form/src/models/ui_schema.dart';

/// Definition for method that allows recursive form building
typedef BuildJsonschemaForm = Widget Function(
  JsonSchema jsonSchema,
  String? jsonKey,
  UiSchema? uiSchema,
  dynamic formData, {
  JsonSchema? previousSchema,
  String? previousJsonKey,
  UiSchema? previousUiSchema,
  int? arrayIndex,
});
