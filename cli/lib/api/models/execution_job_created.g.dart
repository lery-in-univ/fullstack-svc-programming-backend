// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_job_created.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExecutionJobCreated _$ExecutionJobCreatedFromJson(Map<String, dynamic> json) =>
    ExecutionJobCreated(
      id: json['id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ExecutionJobCreatedToJson(
  ExecutionJobCreated instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
};
