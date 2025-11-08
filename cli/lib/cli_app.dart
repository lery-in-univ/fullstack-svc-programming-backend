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
      clearScreen();
      await _showMainMenu();
      final choice = readLine('\n선택: ');

      switch (choice) {
        case '1':
          await authMenu.showRegister();
          break;
        case '2':
          await authMenu.showLogin();
          break;
        case '3':
          if (await storage.isLoggedIn()) {
            await authMenu.showLogout();
          } else {
            printError('로그인되어 있지 않습니다');
            waitForEnter();
          }
          break;
        case '4':
        case 'q':
        case 'Q':
          printInfo('프로그램을 종료합니다...');
          return;
        default:
          printError('잘못된 선택입니다');
          waitForEnter();
      }
    }
  }

  Future<void> _init() async {
    final token = await storage.getToken();
    if (token != null) {
      client.setAuthToken(token);
    }
  }

  Future<void> _showMainMenu() async {
    printHeader('Full Stack Service CLI');

    final isLoggedIn = await storage.isLoggedIn();
    if (isLoggedIn) {
      final email = await storage.getEmail();
      printStatusLoggedIn(email!);
    } else {
      printStatusLoggedOut();
    }

    print('\n메뉴를 선택하세요:');
    printMenuItem('1', '회원가입');
    printMenuItem('2', '로그인');
    printMenuItem('3', '로그아웃');
    printMenuItem('4', '종료');
  }
}
