import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/user.dart';
import 'api_errors.dart';

class ApiService {
  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ===== Cookie Jar แบบง่าย =====
  final Map<String, String> _cookieJar = {};
  Map<String, String> cookiesSnapshot() => Map<String, String>.from(_cookieJar);
  void loadCookies(Map<String, String> cookies) {
    _cookieJar
      ..clear()
      ..addAll(cookies);
  }

  String? _cookieHeader() {
    if (_cookieJar.isEmpty) return null;
    return _cookieJar.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  void _updateCookiesFromResponse(http.Response resp) {
    final setCookie = resp.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) return;

    // split แบบง่าย
    final parts = setCookie.split(',');
    for (final raw in parts) {
      final seg = raw.split(';').first.trim();
      final idx = seg.indexOf('=');
      if (idx > 0) {
        final name = seg.substring(0, idx).trim();
        final value = seg.substring(idx + 1).trim();
        if (name.isNotEmpty && value.isNotEmpty) {
          _cookieJar[name] = value;
        }
      }
    }
  }
  Future<void> _warmupCsrf() async {
    // ไป GET หน้าใดหน้าหนึ่งที่ปล่อย csrftoken (เลือก /api/auth/login/ ตรง ๆ)
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/auth/login/');
    try {
      final resp = await _client.get(uri, headers: {
        'Accept': 'application/json',
        if (_cookieHeader() != null) 'Cookie': _cookieHeader()!,
      }).timeout(const Duration(seconds: 10));
      _updateCookiesFromResponse(resp); // จะได้ csrftoken, sessionid ถ้ามี
    } catch (_) {/* ignore */}
  }

  String? _csrfFromCookie() {
    return _cookieJar['csrftoken'] ?? _cookieJar['csrf'] ?? _cookieJar['csrf_token'];
  }
  // ========= NEW AUTH FLOW =========

  /// Login แบบใหม่ (API auth): ส่ง username หรือ email + password
  /// ถ้า response ไม่มี token จะคืน token เป็น '' แล้วใช้ session cookie เป็นหลัก
  /// Login ใหม่: ส่งแบบฟอร์ม + CSRF
  Future<User> loginWithCredentials({
    String? username,
    String? email,            // ยังรับไว้เพื่อไม่พัง signature แต่จะไม่ใช้แล้ว
    required String password,
  }) async {
    final id = (username ?? '').trim();   // ✅ ใช้เฉพาะ username
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/auth/login/');

    try {
      final request = http.MultipartRequest('POST', uri);
      request.fields.addAll({
        'username': id,                   // ✅ ส่ง username เท่านั้น
        'password': password.trim(),
      });
      // ไม่ส่ง Cookie ตอน login
      final streamed = await request.send().timeout(const Duration(seconds: 15));

      // อัปเดต cookie จาก response
      final setCookieHeader = streamed.headers['set-cookie'];
      if (setCookieHeader != null && setCookieHeader.isNotEmpty) {
        final parts = setCookieHeader.split(',');
        for (final raw in parts) {
          final seg = raw.split(';').first.trim();
          final idx = seg.indexOf('=');
          if (idx > 0) {
            _cookieJar[seg.substring(0, idx).trim()] =
                seg.substring(idx + 1).trim();
          }
        }
      }

      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        String token = '';
        try {
          if (body.isNotEmpty) {
            final data = jsonDecode(body) as Map<String, dynamic>;
            token = (data['token'] ?? data['key'] ?? '').toString();
          }
        } catch (_) {}
        return await getUser(tokenHint: token);
      } else if (streamed.statusCode == 400 || streamed.statusCode == 401) {
        throw ApiException('Invalid credentials', statusCode: streamed.statusCode);
      } else {
        throw ApiException('Login failed (${streamed.statusCode}): $body',
            statusCode: streamed.statusCode);
      }
    } on SocketException {
      throw ApiException('Network error: cannot reach ${uri.host}.');
    } on TimeoutException {
      throw ApiException('Request timeout: $uri');
    } on HandshakeException {
      throw ApiException('TLS/Handshake error.');
    }
  }

  /// ดึงข้อมูลผู้ใช้ปัจจุบัน: GET /api/auth/user/
  Future<User> getUser({String tokenHint = ''}) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/auth/user/');
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      final cookie = _cookieHeader();
      if (cookie != null) headers['Cookie'] = cookie;
      if (tokenHint.isNotEmpty) headers['Authorization'] = 'Bearer $tokenHint';

      final resp = await _client.get(uri, headers: headers).timeout(
            const Duration(seconds: 12),
          );

      _updateCookiesFromResponse(resp);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return User(
          username: (data['username'] ?? '').toString(),
          firstName: (data['first_name'] ?? '').toString(),
          lastName: (data['last_name'] ?? '').toString(),
          email: (data['email'] ?? '').toString(),
          token: tokenHint, // อาจว่างได้
        );
      } else if (resp.statusCode == 401) {
        throw ApiException('Unauthorized (need login)', statusCode: 401);
      } else {
        throw ApiException(
          'Get user failed (${resp.statusCode}): ${resp.body}',
          statusCode: resp.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('Network error: cannot reach ${uri.host}.');
    } on TimeoutException {
      throw ApiException('Request timeout: $uri');
    } on HandshakeException {
      throw ApiException('TLS/Handshake error.');
    }
  }

  /// Logout: POST /api/auth/logout/ (หรือลอง GET ถ้าจำเป็น)
  Future<void> logout() async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/auth/logout/');
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };
      final cookie = _cookieHeader();
      if (cookie != null) headers['Cookie'] = cookie;

      final resp = await _client
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      _updateCookiesFromResponse(resp);
      // ไม่ว่า status อะไร เราจะล้าง cookie ฝั่ง client อยู่ดี
    } catch (_) {
      // ignore network error ตอน logout ฝั่ง client
    } finally {
      _cookieJar.clear();
    }
  }
}
