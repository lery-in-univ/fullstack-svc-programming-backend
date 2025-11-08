import 'package:dio/dio.dart';
import 'api_client.dart';
import 'models/user.dart';
import 'models/auth_response.dart';

class AuthApi {
  final ApiClient client;

  AuthApi(this.client);

  Future<User> register(String email, String password) async {
    try {
      final response = await client.post('/users', {
        'email': email,
        'password': password,
      });

      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data['message'] is List) {
          throw Exception(data['message'].join(', '));
        }
        throw Exception(data['message'] ?? '회원가입에 실패했습니다');
      }
      rethrow;
    }
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await client.post('/login', {
        'email': email,
        'password': password,
      });

      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        throw Exception('이메일 또는 비밀번호가 올바르지 않습니다');
      }
      rethrow;
    }
  }
}
