import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'storage/token_storage.dart';
import 'ui/auth_menu.dart';
import 'ui/utils.dart';

class CliApp {
  final ApiClient client;
  final AuthApi authApi;
  final TokenStorage storage;
  late final AuthMenu authMenu;

  CliApp({String? baseUrl})
      : client = ApiClient(baseUrl: baseUrl ?? 'http://localhost:3000'),
        authApi = AuthApi(ApiClient(baseUrl: baseUrl ?? 'http://localhost:3000')),
        storage = TokenStorage() {
    authMenu = AuthMenu(authApi, storage, client);
  }

  Future<void> run() async {
    await _init();

    while (true) {
      final choice = await _showMainMenu();

      switch (choice) {
        case 0: // 회원가입
          await authMenu.showRegister();
          break;
        case 1: // 로그인
          await authMenu.showLogin();
          break;
        case 2: // 로그아웃
          if (await storage.isLoggedIn()) {
            await authMenu.showLogout();
          } else {
            printError('로그인되어 있지 않습니다');
            waitForEnter();
          }
          break;
        case 3: // 종료
          printInfo('프로그램을 종료합니다...');
          return;
      }
    }
  }

  Future<void> _init() async {
    final token = await storage.getToken();
    if (token != null) {
      client.setAuthToken(token);
    }
  }

  Future<int> _showMainMenu() async {
    final isLoggedIn = await storage.isLoggedIn();
    String? statusText;

    if (isLoggedIn) {
      final email = await storage.getEmail();
      statusText = '${greenPen('● 로그인됨')}: ${cyanPen(email!)}';
    } else {
      statusText = redPen('○ 로그인 필요');
    }

    final options = [
      '회원가입',
      '로그인',
      '로그아웃',
      '종료',
    ];

    return selectMenu(options, statusText: statusText);
  }
}
