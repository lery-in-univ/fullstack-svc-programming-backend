import 'package:json_annotation/json_annotation.dart';

part 'execution_job_created.g.dart';

@JsonSerializable()
class ExecutionJobCreated {
  final String id;
  final String status;
  final DateTime createdAt;

  ExecutionJobCreated({
    required this.id,
    required this.status,
    required this.createdAt,
  });

  factory ExecutionJobCreated.fromJson(Map<String, dynamic> json) =>
      _$ExecutionJobCreatedFromJson(json);

  Map<String, dynamic> toJson() => _$ExecutionJobCreatedToJson(this);
}
