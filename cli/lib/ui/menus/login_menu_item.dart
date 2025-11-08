import '../menu_item.dart';
import '../../api/auth_api.dart';
import '../../storage/token_storage.dart';
import '../../api/api_client.dart';
import '../utils.dart';

class LoginMenuItem implements MenuItem {
  final AuthApi authApi;
  final TokenStorage storage;
  final ApiClient client;

  LoginMenuItem(this.authApi, this.storage, this.client);

  @override
  String get label => '로그인';

  @override
  Future<void> execute() async {
    printHeader('로그인');

    final email = readLine('\n이메일: ');
    final password = readPassword('비밀번호: ');

    try {
      printInfo('로그인 중...');
      final authResponse = await authApi.login(email, password);

      storage.saveToken(authResponse.token, email);
      client.setAuthToken(authResponse.token);

      printSuccess('로그인 성공!');
      print('   환영합니다, $email님!');

      waitForEnter();
    } catch (e) {
      printError('로그인 실패: ${e.toString().replaceAll('Exception: ', '')}');
      waitForEnter();
    }
  }
}
