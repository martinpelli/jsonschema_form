// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'json_schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JsonSchema _$JsonSchemaFromJson(Map<String, dynamic> json) => JsonSchema(
      title: json['title'] as String?,
      type: $enumDecodeNullable(_$JsonTypeEnumMap, json['type']),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, JsonSchema.fromJson(e as Map<String, dynamic>)),
      ),
      enumValue:
          (json['enum'] as List<dynamic>?)?.map((e) => e as String).toList(),
      constValue: json['const'] as String?,
      dependencies: (json['dependencies'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, JsonDependency.fromJson(e as Map<String, dynamic>)),
      ),
      items: json['items'] == null
          ? null
          : JsonSchema.fromJson(json['items'] as Map<String, dynamic>),
    );

const _$JsonTypeEnumMap = {
  JsonType.string: 'string',
  JsonType.number: 'number',
  JsonType.boolean: 'boolean',
  JsonType.array: 'array',
  JsonType.object: 'object',
};
