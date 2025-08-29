import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/api_errors.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  final _storage = const FlutterSecureStorage();

  AuthProvider({ApiService? api}) : _api = api ?? ApiService();

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  static const _kTokenKey = 'auth_token';
  static const _kUsernameKey = 'auth_username';
  static const _kEmailKey = 'auth_email';
  static const _kCookiesKey = 'auth_cookies_json';

  /// Login ใหม่: ใส่ username หรือ email อย่างใดอย่างหนึ่ง + password
  Future<bool> login({
    String? username,
    String? email,
    required String password,
  }) async {
    try {
      final u = await _api.loginWithCredentials(
        username: username,
        email: email,
        password: password,
      );

      _user = u;

      // เก็บ token/cookies
      await _storage.write(key: _kTokenKey, value: u.token);
      await _storage.write(key: _kUsernameKey, value: u.username);
      await _storage.write(key: _kEmailKey, value: u.email);
      await _storage.write(
        key: _kCookiesKey,
        value: jsonEncode(_api.cookiesSnapshot()),
      );

      notifyListeners();
      return true;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  /// Auto-login: restore cookie/token แล้วลอง getUser()
  Future<bool> restoreSession() async {
    final token = await _storage.read(key: _kTokenKey) ?? '';
    final username = await _storage.read(key: _kUsernameKey);
    final email = await _storage.read(key: _kEmailKey);
    final cookiesJson = await _storage.read(key: _kCookiesKey);

    if (cookiesJson != null && cookiesJson.isNotEmpty) {
      try {
        final Map<String, dynamic> m = jsonDecode(cookiesJson);
        _api.loadCookies(m.map((k, v) => MapEntry(k, v.toString())));
      } catch (_) {}
    }

    // มี cookie/token บางส่วน → ลองเรียก user
    try {
      final me = await _api.getUser(tokenHint: token);
      _user = me;

      await _storage.write(key: _kUsernameKey, value: me.username);
      await _storage.write(key: _kEmailKey, value: me.email);
      await _storage.write(
        key: _kCookiesKey,
        value: jsonEncode(_api.cookiesSnapshot()),
      );

      notifyListeners();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> refreshMe() async {
    if (_user == null) return;
    final me = await _api.getUser(tokenHint: _user!.token);
    _user = me;

    await _storage.write(key: _kUsernameKey, value: me.username);
    await _storage.write(key: _kEmailKey, value: me.email);
    await _storage.write(
      key: _kCookiesKey,
      value: jsonEncode(_api.cookiesSnapshot()),
    );
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    await _storage.delete(key: _kTokenKey);
    await _storage.delete(key: _kUsernameKey);
    await _storage.delete(key: _kEmailKey);
    await _storage.delete(key: _kCookiesKey);
    notifyListeners();
  }
}
