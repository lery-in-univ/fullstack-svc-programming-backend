import 'dart:io';
import 'package:dio/dio.dart';
import 'models/execution_job.dart';
import 'models/execution_job_created.dart';

class ExecutionApi {
  final Dio dio;

  ExecutionApi(this.dio);

  Future<ExecutionJobCreated> submitCode(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final response = await dio.post(
      '/execution-jobs',
      data: formData,
    );

    return ExecutionJobCreated.fromJson(response.data);
  }

  Future<ExecutionJob> getJobStatus(String jobId) async {
    final response = await dio.get('/execution-jobs/$jobId');
    return ExecutionJob.fromJson(response.data);
  }

  Future<ExecutionJob> pollUntilComplete(
    String jobId, {
    Duration interval = const Duration(seconds: 1),
    int maxAttempts = 60,
    void Function(ExecutionJob)? onStatusUpdate,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      final job = await getJobStatus(jobId);

      if (onStatusUpdate != null) {
        onStatusUpdate(job);
      }

      if (job.isTerminal) {
        return job;
      }

      await Future.delayed(interval);
    }

    throw Exception('Polling timeout: 실행 시간이 초과되었습니다 (60초)');
  }
}
