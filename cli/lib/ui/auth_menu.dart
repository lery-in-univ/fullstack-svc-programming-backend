import '../api/auth_api.dart';
import '../storage/token_storage.dart';
import '../api/api_client.dart';
import 'utils.dart';

class AuthMenu {
  final AuthApi authApi;
  final TokenStorage storage;
  final ApiClient client;

  AuthMenu(this.authApi, this.storage, this.client);

  Future<void> showRegister() async {
    printHeader('회원가입');

    String email;
    while (true) {
      email = readLine('\n이메일: ');
      if (isValidEmail(email)) {
        break;
      }
      printError('올바른 이메일 형식이 아닙니다');
    }

    String password = readPassword('비밀번호: ');

    try {
      printInfo('회원가입 중...');
      final user = await authApi.register(email, password);

      printSuccess('회원가입 성공!');
      print('   사용자 ID: ${user.id}');
      print('   이메일: ${user.email}');

      waitForEnter();
    } catch (e) {
      printError('회원가입 실패: ${e.toString().replaceAll('Exception: ', '')}');
      waitForEnter();
    }
  }

  Future<bool> showLogin() async {
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
      return true;
    } catch (e) {
      printError('로그인 실패: ${e.toString().replaceAll('Exception: ', '')}');
      waitForEnter();
      return false;
    }
  }

  Future<void> showLogout() async {
    storage.deleteToken();
    client.clearAuthToken();
    printSuccess('로그아웃되었습니다');
    waitForEnter();
  }
}
