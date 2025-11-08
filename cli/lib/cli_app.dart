import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'storage/token_storage.dart';
import 'ui/menu_item.dart';
import 'ui/menus/register_menu_item.dart';
import 'ui/menus/login_menu_item.dart';
import 'ui/menus/logout_menu_item.dart';
import 'ui/menus/exit_menu_item.dart';
import 'ui/utils.dart';

class CliApp {
  final ApiClient client;
  final AuthApi authApi;
  final TokenStorage storage;
  late final List<MenuItem> menuItems;

  CliApp({String? baseUrl})
      : client = ApiClient(baseUrl: baseUrl ?? 'http://localhost:3000'),
        authApi = AuthApi(ApiClient(baseUrl: baseUrl ?? 'http://localhost:3000')),
        storage = TokenStorage() {
    menuItems = [
      RegisterMenuItem(authApi, storage, client),
      LoginMenuItem(authApi, storage, client),
      LogoutMenuItem(storage, client),
      ExitMenuItem(),
    ];
  }

  Future<void> run() async {
    await _init();

    while (true) {
      final choice = await _showMainMenu();

      await menuItems[choice].execute();

      if (menuItems[choice] is ExitMenuItem) {
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

    final options = menuItems.map((item) => item.label).toList();

    return selectMenu(options, statusText: statusText);
  }
}
