class TokenStorage {
  String? _token;
  String? _email;

  void saveToken(String token, String email) {
    _token = token;
    _email = email;
  }

  String? getToken() {
    return _token;
  }

  String? getEmail() {
    return _email;
  }

  void deleteToken() {
    _token = null;
    _email = null;
  }

  bool isLoggedIn() {
    return _token != null;
  }
}
