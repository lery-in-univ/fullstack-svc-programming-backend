import '../menu_item.dart';
import '../../api/auth_api.dart';
import '../../storage/token_storage.dart';
import '../../api/api_client.dart';
import '../utils.dart';

class RegisterMenuItem implements MenuItem {
  final AuthApi authApi;
  final TokenStorage storage;
  final ApiClient client;

  RegisterMenuItem(this.authApi, this.storage, this.client);

  @override
  String get label => '회원가입';

  @override
  Future<void> execute() async {
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
}
