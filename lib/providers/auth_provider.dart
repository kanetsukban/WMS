import 'dart:convert'; // ✅ ใช้เข้ารหัส cookies เป็น JSON
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
  static const _kCookiesKey = 'auth_cookies_json'; // ✅ เก็บ cookie

  Future<bool> login(String username, String password) async {
    final u = await _api.login(username, password); // ถ้าพลาดจะ throw ApiException
    _user = u;

    // ✅ เก็บ token + โปรไฟล์พื้นฐาน
    await _storage.write(key: _kTokenKey, value: u.token);
    await _storage.write(key: _kUsernameKey, value: u.username);
    await _storage.write(key: _kEmailKey, value: u.email);

    // ✅ เก็บ cookies
    final cookies = _api.cookiesSnapshot();
    await _storage.write(key: _kCookiesKey, value: jsonEncode(cookies));

    notifyListeners();
    return true;
  }

  /// Auto-login: โหลด token + cookie จาก storage แล้วลอง /me
  Future<bool> restoreSession() async {
    final token = await _storage.read(key: _kTokenKey);
    final username = await _storage.read(key: _kUsernameKey);
    final email = await _storage.read(key: _kEmailKey);
    final cookiesJson = await _storage.read(key: _kCookiesKey);

    if (token == null || username == null) return false;

    // ✅ โหลด cookie กลับเข้า ApiService
    if (cookiesJson != null && cookiesJson.isNotEmpty) {
      try {
        final Map<String, dynamic> m = jsonDecode(cookiesJson);
        _api.loadCookies(m.map((k, v) => MapEntry(k, v.toString())));
      } catch (_) {
        // ถ้า parse ไม่ได้ ก็ข้ามไป
      }
    }

    // สร้าง user ชั่วคราวก่อน
    _user = User(
      username: username,
      firstName: '',
      lastName: '',
      email: email ?? '',
      token: token,
    );
    notifyListeners();

    // ✅ เรียก /me เพื่อยืนยัน token + ดึงข้อมูลล่าสุด
    try {
      final me = await _api.getMeWithBearer(token);
      _user = me;

      // อัปเดต email/username เผื่อเปลี่ยน และอัปเดต cookies ล่าสุด
      await _storage.write(key: _kUsernameKey, value: me.username);
      await _storage.write(key: _kEmailKey, value: me.email);
      await _storage.write(key: _kCookiesKey, value: jsonEncode(_api.cookiesSnapshot()));

      notifyListeners();
      return true;
    } catch (_) {
      await logout(); // token/cookie ใช้ไม่ได้แล้ว
      return false;
    }
  }

  Future<void> refreshMe() async {
    if (_user == null) return;
    final me = await _api.getMeWithBearer(_user!.token);
    _user = me;

    // อัปเดต storage ด้วย
    await _storage.write(key: _kUsernameKey, value: me.username);
    await _storage.write(key: _kEmailKey, value: me.email);
    await _storage.write(key: _kCookiesKey, value: jsonEncode(_api.cookiesSnapshot()));

    notifyListeners();
  }

  Future<void> logout() async {
    if (_user != null) {
      await _api.logout(_user!.token);
    }
    _user = null;
    await _storage.delete(key: _kTokenKey);
    await _storage.delete(key: _kUsernameKey);
    await _storage.delete(key: _kEmailKey);
    await _storage.delete(key: _kCookiesKey); // ✅ ลบ cookies
    notifyListeners();
  }
}
