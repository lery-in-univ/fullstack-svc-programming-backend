import 'dart:io';
import '../menu_item.dart';
import '../../api/execution_api.dart';
import '../../storage/token_storage.dart';
import '../utils.dart';

class RunCodeMenuItem implements MenuItem {
  final ExecutionApi executionApi;
  final TokenStorage storage;

  RunCodeMenuItem(this.executionApi, this.storage);

  @override
  String get label => '코드 실행';

  @override
  Future<void> execute() async {
    if (!storage.isLoggedIn()) {
      printError('로그인이 필요합니다');
      waitForEnter();
      return;
    }

    printHeader('코드 실행');

    final filePath = readLine('\n실행할 Dart 파일 경로 (예: ./hello.dart): ');

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
      printError('.dart 파일만 실행할 수 있습니다');
      waitForEnter();
      return;
    }

    try {
      printInfo('파일 업로드 중...');
      final job = await executionApi.submitCode(file);

      print('${bluePen('작업 ID')}: ${job.id}');

      String lastStatus = '';
      printInfo('실행 중...');

      final result = await executionApi.pollUntilComplete(
        job.id,
        onStatusUpdate: (job) {
          if (job.status != lastStatus) {
            lastStatus = job.status;
            final statusDisplay = _formatStatus(job.status);
            print('${grayPen('상태')}: $statusDisplay');
          }
        },
      );

      print('');
      if (result.isSuccess) {
        printSuccess('실행 완료!');
        if (result.output != null && result.output!.isNotEmpty) {
          print('\n${greenPen('=== 출력 ===')}');
          print(result.output);
          print(greenPen('=' * 50));
        }
        if (result.exitCode != null) {
          print('${grayPen('종료 코드')}: ${result.exitCode}');
        }
      } else {
        printError('실행 실패');
        if (result.error != null && result.error!.isNotEmpty) {
          print('\n${redPen('=== 에러 ===')}');
          print(result.error);
          print(redPen('=' * 50));
        }
        if (result.exitCode != null) {
          print('${grayPen('종료 코드')}: ${result.exitCode}');
        }
      }

      waitForEnter();
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('401')) {
        printError('인증이 만료되었습니다. 다시 로그인해주세요');
      } else if (errorMsg.contains('400')) {
        printError('잘못된 요청입니다. 파일을 확인해주세요');
      } else if (errorMsg.contains('timeout') || errorMsg.contains('Polling timeout')) {
        printError('실행 시간이 초과되었습니다 (60초)');
      } else {
        printError('오류 발생: $errorMsg');
      }
      waitForEnter();
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'QUEUED':
        return yellowPen('대기 중');
      case 'READY':
        return cyanPen('준비 완료');
      case 'RUNNING':
        return bluePen('실행 중');
      case 'FINISHED_WITH_SUCCESS':
        return greenPen('성공');
      case 'FINISHED_WITH_ERROR':
        return redPen('에러 발생');
      case 'FAILED':
        return redPen('실패');
      default:
        return grayPen(status);
    }
  }
}
