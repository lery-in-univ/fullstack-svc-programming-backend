import 'dart:io';
import 'package:ansicolor/ansicolor.dart';

// ANSI 색상 펜 정의
final _greenPen = AnsiPen()..green(bold: true);
final _redPen = AnsiPen()..red(bold: true);
final _bluePen = AnsiPen()..blue(bold: true);
final _cyanPen = AnsiPen()..cyan(bold: true);
final _yellowPen = AnsiPen()..yellow(bold: true);
final _magentaPen = AnsiPen()..magenta(bold: true);
final _grayPen = AnsiPen()..gray(level: 0.5);
final _whiteBoldPen = AnsiPen()..white(bold: true);

String readLine(String prompt) {
  stdout.write(_cyanPen(prompt));
  return stdin.readLineSync() ?? '';
}

String readPassword(String prompt) {
  stdout.write(_cyanPen(prompt));
  stdin.echoMode = false;
  final password = stdin.readLineSync() ?? '';
  stdin.echoMode = true;
  stdout.writeln();
  return password;
}

void printSuccess(String message) {
  print('\n${_greenPen('✅ $message')}');
}

void printError(String message) {
  print('\n${_redPen('❌ $message')}');
}

void printInfo(String message) {
  print('\n${_bluePen('ℹ️  $message')}');
}

void printHeader(String title) {
  final divider = '=' * 50;
  print('\n${_magentaPen(divider)}');
  final padding = (50 - title.length) ~/ 2;
  print(_magentaPen('${' ' * padding}$title'));
  print(_magentaPen(divider));
}

void printDivider() {
  print(_grayPen('-' * 50));
}

void waitForEnter() {
  print(_grayPen('\n계속하려면 Enter를 누르세요...'));
  stdin.readLineSync();
}

void printMenuItem(String number, String text) {
  print('${_yellowPen(number)}. ${_whiteBoldPen(text)}');
}

void printStatusLoggedIn(String email) {
  print('\n${_greenPen('● 로그인됨')}: ${_cyanPen(email)}');
}

void printStatusLoggedOut() {
  print('\n${_redPen('○ 로그인 필요')}');
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
