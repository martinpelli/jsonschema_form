// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'json_schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JsonSchema _$JsonSchemaFromJson(Map<String, dynamic> json) => JsonSchema(
      title: json['title'] as String?,
      description: json['description'] as String?,
      defaultValue: json['default'] as String?,
      type: $enumDecodeNullable(_$JsonTypeEnumMap, json['type']),
      requiredFields: (json['required'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
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
      items: const ItemsJsonParser().fromJson(json['items']),
      additionalItems: json['additionalItems'] == null
          ? null
          : JsonSchema.fromJson(
              json['additionalItems'] as Map<String, dynamic>),
      minItems: (json['minItems'] as num?)?.toInt(),
      maxItems: (json['maxItems'] as num?)?.toInt(),
      uniqueItems: json['uniqueItems'] as bool?,
    );

const _$JsonTypeEnumMap = {
  JsonType.string: 'string',
  JsonType.number: 'number',
  JsonType.integer: 'integer',
  JsonType.boolean: 'boolean',
  JsonType.array: 'array',
  JsonType.object: 'object',
};
