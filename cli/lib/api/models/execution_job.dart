import 'package:json_annotation/json_annotation.dart';

part 'execution_job.g.dart';

@JsonSerializable()
class ExecutionJob {
  final String id;
  final String status;
  final String filePath;
  final DateTime createdAt;
  final String? output;
  final String? error;
  final int? exitCode;
  final DateTime? completedAt;

  ExecutionJob({
    required this.id,
    required this.status,
    required this.filePath,
    required this.createdAt,
    this.output,
    this.error,
    this.exitCode,
    this.completedAt,
  });

  factory ExecutionJob.fromJson(Map<String, dynamic> json) =>
      _$ExecutionJobFromJson(json);

  Map<String, dynamic> toJson() => _$ExecutionJobToJson(this);

  bool get isTerminal =>
      status == 'FINISHED_WITH_SUCCESS' ||
      status == 'FINISHED_WITH_ERROR' ||
      status == 'FAILED';

  bool get isSuccess => status == 'FINISHED_WITH_SUCCESS';
}
