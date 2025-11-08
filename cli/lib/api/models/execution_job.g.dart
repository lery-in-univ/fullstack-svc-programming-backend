// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'execution_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExecutionJob _$ExecutionJobFromJson(Map<String, dynamic> json) => ExecutionJob(
  id: json['id'] as String,
  status: json['status'] as String,
  filePath: json['filePath'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  output: json['output'] as String?,
  error: json['error'] as String?,
  exitCode: (json['exitCode'] as num?)?.toInt(),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$ExecutionJobToJson(ExecutionJob instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'filePath': instance.filePath,
      'createdAt': instance.createdAt.toIso8601String(),
      'output': instance.output,
      'error': instance.error,
      'exitCode': instance.exitCode,
      'completedAt': instance.completedAt?.toIso8601String(),
    };
