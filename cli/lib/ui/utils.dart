import 'dart:io';
import 'package:ansicolor/ansicolor.dart';
import 'package:dart_console/dart_console.dart';

// ANSI 색상 펜 정의
final greenPen = AnsiPen()..green(bold: true);
final redPen = AnsiPen()..red(bold: true);
final bluePen = AnsiPen()..blue(bold: true);
final cyanPen = AnsiPen()..cyan(bold: true);
final yellowPen = AnsiPen()..yellow(bold: true);
final magentaPen = AnsiPen()..magenta(bold: true);
final grayPen = AnsiPen()..gray(level: 0.5);
final whiteBoldPen = AnsiPen()..white(bold: true);

String readLine(String prompt) {
  stdout.write(cyanPen(prompt));
  return stdin.readLineSync() ?? '';
}

String readPassword(String prompt) {
  stdout.write(cyanPen(prompt));
  stdin.echoMode = false;
  final password = stdin.readLineSync() ?? '';
  stdin.echoMode = true;
  stdout.writeln();
  return password;
}

void printSuccess(String message) {
  print('\n${greenPen('✅ $message')}');
}

void printError(String message) {
  print('\n${redPen('❌ $message')}');
}

void printInfo(String message) {
  print('\n${bluePen('ℹ️  $message')}');
}

void printHeader(String title) {
  final divider = '=' * 50;
  print('\n${magentaPen(divider)}');
  final padding = (50 - title.length) ~/ 2;
  print(magentaPen('${' ' * padding}$title'));
  print(magentaPen(divider));
}

void printDivider() {
  print(grayPen('-' * 50));
}

void waitForEnter() {
  print(grayPen('\n계속하려면 Enter를 누르세요...'));
  stdin.readLineSync();
}

void printMenuItem(String number, String text) {
  print('${yellowPen(number)}. ${whiteBoldPen(text)}');
}

void printStatusLoggedIn(String email) {
  print('\n${greenPen('● 로그인됨')}: ${cyanPen(email)}');
}

void printStatusLoggedOut() {
  print('\n${redPen('○ 로그인 필요')}');
}

int selectMenu(List<String> options, {String? statusText}) {
  final console = Console();
  int selectedIndex = 0;

  void render() {
    console.clearScreen();
    console.resetCursorPosition();

    print(magentaPen('Full Stack Service CLI'));
    print('');

    if (statusText != null) {
      print(statusText);
      print('');
    }

    print(grayPen('화살표 키로 이동, Enter로 선택\n'));

    for (int i = 0; i < options.length; i++) {
      if (i == selectedIndex) {
        // 선택된 항목 - 화살표와 함께 표시
        print('${cyanPen('▶')} ${whiteBoldPen(options[i])}');
      } else {
        // 일반 항목
        print('  ${grayPen(options[i])}');
      }
    }
  }

  render();

  while (true) {
    final key = console.readKey();

    if (key.controlChar == ControlCharacter.arrowUp) {
      selectedIndex = (selectedIndex - 1) % options.length;
      if (selectedIndex < 0) selectedIndex = options.length - 1;
      render();
    } else if (key.controlChar == ControlCharacter.arrowDown) {
      selectedIndex = (selectedIndex + 1) % options.length;
      render();
    } else if (key.controlChar == ControlCharacter.enter) {
      console.clearScreen();
      console.resetCursorPosition();
      return selectedIndex;
    } else if (key.char == 'q' || key.char == 'Q') {
      console.clearScreen();
      console.resetCursorPosition();
      return options.length - 1; // 종료 옵션 선택
    }
  }
}

void clearScreen() {
  if (Platform.isWindows) {
    print(Process.runSync("cls", [], runInShell: true).stdout);
  } else {
    print(Process.runSync("clear", [], runInShell: true).stdout);
  }
}

bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

bool isValidPassword(String password) {
  return password.length >= 8;
}
