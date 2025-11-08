import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient({String baseUrl = 'http://localhost:3000'})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
          },
        )) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => print('[API] $obj'),
    ));
  }

  Future<Response> post(String path, dynamic data) async {
    try {
      return await dio.post(path, data: data);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }

  void _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw Exception('요청 시간이 초과되었습니다');
    } else if (e.type == DioExceptionType.connectionError) {
      throw Exception('서버에 연결할 수 없습니다');
    }
  }
}
