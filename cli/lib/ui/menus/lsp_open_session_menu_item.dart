import '../menu_item.dart';
import '../../api/lsp_api.dart';
import '../../storage/token_storage.dart';
import '../../lsp/lsp_client.dart';
import '../../lsp/lsp_session_manager.dart';
import '../utils.dart';

class LspOpenSessionMenuItem implements MenuItem {
  final LspApi lspApi;
  final TokenStorage storage;
  final String serverUrl;
  final LspSessionManager sessionManager;

  LspOpenSessionMenuItem(
    this.lspApi,
    this.storage,
    this.serverUrl,
    this.sessionManager,
  );

  @override
  String get label => 'LSP 세션 열기';

  @override
  Future<void> execute() async {
    if (!storage.isLoggedIn()) {
      printError('로그인이 필요합니다');
      waitForEnter();
      return;
    }

    if (sessionManager.hasActiveConnection()) {
      printInfo('이미 활성화된 LSP 세션이 있습니다');
      print('현재 세션 ID: ${sessionManager.currentSessionId}');
      waitForEnter();
      return;
    }

    printHeader('LSP 세션 열기');

    try {
      printInfo('LSP 세션 생성 중...');
      final sessionId = await lspApi.createSession();
      print('${bluePen('세션 ID')}: $sessionId');

      final token = storage.getToken()!;
      final lspClient = LspClient(serverUrl, token);

      lspClient.statusStream.listen((status) {
        print(grayPen('  → $status'));
      });

      printInfo('LSP 서버에 연결 중...');
      await lspClient.connect(sessionId);

      printInfo('LSP 서버 초기화 중...');
      // Use a generic workspace root for now
      await lspClient.initialize('file:///workspace');

      // Store session and client in manager
      sessionManager.currentSessionId = sessionId;
      sessionManager.activeClient = lspClient;

      // Start automatic session renewal
      sessionManager.startRenewal(lspApi);

      printSuccess('LSP 세션이 성공적으로 열렸습니다!');
      print('${grayPen('세션 ID')}: $sessionId');
      print('${grayPen('자동 갱신')}: 5분마다');
      print('');
      print('이제 "Go to Definition" 명령을 사용할 수 있습니다.');
      print('작업이 끝나면 "LSP 세션 닫기"를 실행하세요.');

      waitForEnter();
    } catch (e) {
      // Clean up on error
      sessionManager.currentSessionId = null;
      sessionManager.activeClient = null;

      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('401')) {
        printError('인증이 만료되었습니다. 다시 로그인해주세요');
      } else if (errorMsg.contains('404')) {
        printError('LSP 컨테이너를 찾을 수 없습니다. 잠시 후 다시 시도해주세요');
      } else if (errorMsg.contains('timeout') || errorMsg.contains('타임아웃')) {
        printError('요청 시간이 초과되었습니다');
      } else {
        printError('오류 발생: $errorMsg');
      }
      waitForEnter();
    }
  }
}
