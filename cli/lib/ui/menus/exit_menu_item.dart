import '../menu_item.dart';
import '../utils.dart';

class ExitMenuItem implements MenuItem {
  @override
  String get label => '종료';

  @override
  Future<void> execute() async {
    printInfo('프로그램을 종료합니다...');
  }
}
