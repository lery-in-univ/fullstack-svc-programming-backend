import 'api/api_client.dart';
import 'api/auth_api.dart';
import 'api/execution_api.dart';
import 'api/lsp_api.dart';
import 'storage/token_storage.dart';
import 'lsp/lsp_session_manager.dart';
import 'ui/menu_item.dart';
import 'ui/menus/register_menu_item.dart';
import 'ui/menus/login_menu_item.dart';
import 'ui/menus/logout_menu_item.dart';
import 'ui/menus/run_code_menu_item.dart';
import 'ui/menus/lsp_open_session_menu_item.dart';
import 'ui/menus/lsp_close_session_menu_item.dart';
import 'ui/menus/lsp_goto_definition_menu_item.dart';
import 'ui/menus/exit_menu_item.dart';
import 'ui/exit_action.dart';
import 'ui/utils.dart';

class CliApp {
  final TokenStorage storage;
  final ApiClient client;
  final String baseUrl;
  late final AuthApi authApi;
  late final ExecutionApi executionApi;
  late final LspApi lspApi;
  late final LspSessionManager lspSessionManager;
  late final List<MenuItem> menuItems;

  CliApp({String? baseUrl})
    : baseUrl = baseUrl ?? 'http://localhost:3000',
      storage = TokenStorage(),
      client = ApiClient(baseUrl: baseUrl ?? 'http://localhost:3000') {
    authApi = AuthApi(client);
    executionApi = ExecutionApi(client.dio);
    lspApi = LspApi(client.dio);
    lspSessionManager = LspSessionManager();

    menuItems = [
      RegisterMenuItem(authApi, storage, client),
      LoginMenuItem(authApi, storage, client),
      RunCodeMenuItem(executionApi, storage),
      LspOpenSessionMenuItem(lspApi, storage, this.baseUrl, lspSessionManager),
      LspGotoDefinitionMenuItem(lspApi, storage, lspSessionManager),
      LspCloseSessionMenuItem(storage, lspSessionManager),
      LogoutMenuItem(storage, client),
      ExitMenuItem(),
    ];
  }

  Future<void> run() async {
    await _init();

    try {
      while (true) {
        try {
          final choice = await _showMainMenu();
          await menuItems[choice].execute();
        } on ExitAction {
          break;
        }
      }
    } finally {
      // Clean up LSP session manager on exit
      lspSessionManager.dispose();
    }
  }

  Future<void> _init() async {
    final token = storage.getToken();
    if (token != null) {
      client.setAuthToken(token);
    }
  }

  Future<int> _showMainMenu() async {
    final isLoggedIn = storage.isLoggedIn();
    String? statusText;

    if (isLoggedIn) {
      final email = storage.getEmail();
      statusText = '${greenPen('● 로그인됨')}: ${cyanPen(email!)}';
    } else {
      statusText = redPen('○ 로그인 필요');
    }

    final options = menuItems.map((item) => item.label).toList();

    return selectMenu(options, statusText: statusText);
  }
}
