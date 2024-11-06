// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'json_dependency.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JsonDependency _$JsonDependencyFromJson(Map<String, dynamic> json) =>
    JsonDependency(
      oneOf: (json['oneOf'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$JsonDependencyToJson(JsonDependency instance) =>
    <String, dynamic>{
      'oneOf': instance.oneOf,
    };
