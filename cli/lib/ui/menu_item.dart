abstract class MenuItem {
  String get label;

  Future<void> execute();
}
