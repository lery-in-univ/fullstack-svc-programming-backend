import '../menu_item.dart';
import '../../storage/token_storage.dart';
import '../../api/api_client.dart';
import '../utils.dart';

class LogoutMenuItem implements MenuItem {
  final TokenStorage storage;
  final ApiClient client;

  LogoutMenuItem(this.storage, this.client);

  @override
  String get label => '로그아웃';

  @override
  Future<void> execute() async {
    if (await storage.isLoggedIn()) {
      await storage.deleteToken();
      client.clearAuthToken();
      printSuccess('로그아웃되었습니다');
    } else {
      printError('로그인되어 있지 않습니다');
    }
    waitForEnter();
  }
}
