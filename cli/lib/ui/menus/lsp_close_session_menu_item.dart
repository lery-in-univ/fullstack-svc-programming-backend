import '../menu_item.dart';
import '../../storage/token_storage.dart';
import '../../lsp/lsp_session_manager.dart';
import '../utils.dart';

class LspCloseSessionMenuItem implements MenuItem {
  final TokenStorage storage;
  final LspSessionManager sessionManager;

  LspCloseSessionMenuItem(this.storage, this.sessionManager);

  @override
  String get label => 'LSP 세션 닫기';

  @override
  Future<void> execute() async {
    if (!storage.isLoggedIn()) {
      printError('로그인이 필요합니다');
      waitForEnter();
      return;
    }

    if (!sessionManager.hasActiveConnection()) {
      printInfo('열려있는 LSP 세션이 없습니다');
      waitForEnter();
      return;
    }

    printHeader('LSP 세션 닫기');

    try {
      final sessionId = sessionManager.currentSessionId;
      printInfo('LSP 연결 종료 중...');

      await sessionManager.disconnect();

      printSuccess('LSP 세션이 성공적으로 닫혔습니다!');
      print('${grayPen('종료된 세션 ID')}: $sessionId');

      waitForEnter();
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      printError('세션 종료 중 오류 발생: $errorMsg');
      waitForEnter();
    }
  }
}
