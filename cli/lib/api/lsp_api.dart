import 'dart:io';
import 'package:dio/dio.dart';

class LspApi {
  final Dio dio;

  LspApi(this.dio);

  Future<String> createSession() async {
    final response = await dio.post('/language-server/sessions');
    return response.data['sessionId'] as String;
  }

  Future<void> renewSession(String sessionId) async {
    await dio.post('/language-server/sessions/$sessionId/renew');
  }

  Future<Map<String, String>> uploadFile(String sessionId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });

    final response = await dio.post(
      '/language-server/sessions/$sessionId/files',
      data: formData,
    );

    return {
      'filePath': response.data['filePath'] as String,
      'originalName': response.data['originalName'] as String,
    };
  }
}
