import 'dart:io';
import '../menu_item.dart';
import '../../api/lsp_api.dart';
import '../../storage/token_storage.dart';
import '../../lsp/lsp_session_manager.dart';
import '../utils.dart';

class LspGotoDefinitionMenuItem implements MenuItem {
  final LspApi lspApi;
  final TokenStorage storage;
  final LspSessionManager sessionManager;

  LspGotoDefinitionMenuItem(this.lspApi, this.storage, this.sessionManager);

  @override
  String get label => 'Go to Definition';

  @override
  Future<void> execute() async {
    if (!storage.isLoggedIn()) {
      printError('로그인이 필요합니다');
      waitForEnter();
      return;
    }

    if (!sessionManager.hasActiveConnection()) {
      printError('활성화된 LSP 세션이 없습니다');
      print('먼저 "LSP 세션 열기"를 실행하세요.');
      waitForEnter();
      return;
    }

    printHeader('LSP Go to Definition');

    final filePath = readLine('\n실행할 Dart 파일 경로 (예: ./example.dart): ');

    if (filePath.trim().isEmpty) {
      printError('파일 경로를 입력해주세요');
      waitForEnter();
      return;
    }

    final file = File(filePath);

    if (!file.existsSync()) {
      printError('파일을 찾을 수 없습니다: $filePath');
      waitForEnter();
      return;
    }

    if (!filePath.endsWith('.dart')) {
      printError('.dart 파일만 사용할 수 있습니다');
      waitForEnter();
      return;
    }

    final content = await file.readAsString();

    print('\n파일 내용:');
    print(grayPen('=' * 50));
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      print('${grayPen('${i.toString().padLeft(3)}:')} ${lines[i]}');
    }
    print(grayPen('=' * 50));

    final lineStr = readLine('\nDefinition을 찾을 라인 번호 (0-based): ');
    final line = int.tryParse(lineStr);
    if (line == null) {
      printError('올바른 숫자를 입력해주세요');
      waitForEnter();
      return;
    }

    final charStr = readLine('컬럼 번호 (0-based): ');
    final character = int.tryParse(charStr);
    if (character == null) {
      printError('올바른 숫자를 입력해주세요');
      waitForEnter();
      return;
    }

    try {
      final lspClient = sessionManager.activeClient!;
      final sessionId = sessionManager.currentSessionId!;

      // Upload file to LSP server
      printInfo('파일 업로드 중...');
      final uploadResult = await lspApi.uploadFile(sessionId, file);
      final containerFilePath = uploadResult['filePath']!;

      // Use container-local path as URI
      final uri = 'file://$containerFilePath';

      printInfo('문서 열기 중...');
      await lspClient.openDocument(uri, content);

      printInfo('Definition 조회 중...');
      final definitions = await lspClient.goToDefinition(uri, line, character);

      print('');
      if (definitions == null || definitions.isEmpty) {
        printError('Definition을 찾을 수 없습니다');
      } else {
        printSuccess('Definition을 찾았습니다!');
        print('');
        for (int i = 0; i < definitions.length; i++) {
          final def = definitions[i] as Map<String, dynamic>;

          // Handle both Location and LocationLink
          String targetUri;
          Map<String, dynamic>? range;

          if (def.containsKey('targetUri')) {
            // LocationLink format
            targetUri = def['targetUri'] as String;
            range = def['targetSelectionRange'] as Map<String, dynamic>?;
          } else if (def.containsKey('uri')) {
            // Location format
            targetUri = def['uri'] as String;
            range = def['range'] as Map<String, dynamic>?;
          } else {
            continue;
          }

          print('${yellowPen('[$i]')} ${cyanPen(targetUri)}');

          if (range != null) {
            final start = range['start'] as Map<String, dynamic>;
            final end = range['end'] as Map<String, dynamic>;
            print(
              '    ${grayPen('위치')}: Line ${start['line']}, Character ${start['character']} ~ Line ${end['line']}, Character ${end['character']}',
            );
          }
        }
      }

      waitForEnter();
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('401')) {
        printError('인증이 만료되었습니다. 다시 로그인해주세요');
      } else if (errorMsg.contains('404')) {
        printError('LSP 컨테이너를 찾을 수 없습니다');
        print('세션이 만료되었을 수 있습니다. LSP 세션을 다시 여세요.');
      } else if (errorMsg.contains('timeout') || errorMsg.contains('타임아웃')) {
        printError('요청 시간이 초과되었습니다');
      } else {
        printError('오류 발생: $errorMsg');
      }
      waitForEnter();
    }
  }
}
