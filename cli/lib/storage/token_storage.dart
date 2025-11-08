import 'dart:io';
import 'package:path/path.dart' as path;

class TokenStorage {
  late final String _tokenPath;
  String? _cachedToken;
  String? _cachedEmail;

  TokenStorage() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    final configDir = path.join(home, '.fullstack_cli');
    _tokenPath = path.join(configDir, 'token');

    Directory(configDir).createSync(recursive: true);
  }

  Future<void> saveToken(String token, String email) async {
    final file = File(_tokenPath);
    await file.writeAsString('$token\n$email');
    _cachedToken = token;
    _cachedEmail = email;
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    final file = File(_tokenPath);
    if (!await file.exists()) return null;

    final lines = await file.readAsLines();
    if (lines.isEmpty) return null;

    _cachedToken = lines[0];
    if (lines.length > 1) {
      _cachedEmail = lines[1];
    }
    return _cachedToken;
  }

  Future<String?> getEmail() async {
    if (_cachedEmail != null) return _cachedEmail;

    final file = File(_tokenPath);
    if (!await file.exists()) return null;

    final lines = await file.readAsLines();
    if (lines.length < 2) return null;

    _cachedEmail = lines[1];
    return _cachedEmail;
  }

  Future<void> deleteToken() async {
    final file = File(_tokenPath);
    if (await file.exists()) {
      await file.delete();
    }
    _cachedToken = null;
    _cachedEmail = null;
  }

  Future<bool> isLoggedIn() async {
    return await getToken() != null;
  }
}
