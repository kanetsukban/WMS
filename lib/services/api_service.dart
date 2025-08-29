import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../core/constants.dart';
import 'api_errors.dart';

class ApiService {
  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Cookie jar แบบง่าย
  final Map<String, String> _cookieJar = {};

  // ใช้ใน AuthProvider เพื่อบันทึก cookie ลง storage
  Map<String, String> cookiesSnapshot() => Map<String, String>.from(_cookieJar);

  // ใช้ใน AuthProvider เพื่อ restore cookie จาก storage
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

  String _basicAuthHeader(String username, String password) {
    final raw = '$username:$password';
    final token = base64Encode(utf8.encode(raw));
    return 'Basic $token';
  }

  Future<String> _getTokenByBasicAuth({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/user/token/');

    try {
      final headers = <String, String>{
        'Authorization': _basicAuthHeader(username, password),
        'Accept': 'application/json',
      };
      final cookie = _cookieHeader();
      if (cookie != null) headers['Cookie'] = cookie;

      // ✅ กลับมาใช้ GET ตาม backend
      final resp = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 12));

      _updateCookiesFromResponse(resp);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token == null || token.isEmpty) {
          throw ApiException('Token not found in response', statusCode: 200);
        }
        return token;
      } else if (resp.statusCode == 401) {
        throw ApiException('Invalid credentials', statusCode: 401);
      } else {
        throw ApiException(
          'Token request failed (${resp.statusCode}): ${resp.body}',
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

  Future<User> _getMeWithBearer(String bearerToken) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/api/user/me/');
    try {
      final headers = <String, String>{
        'Authorization': 'Bearer $bearerToken',
        'Accept': 'application/json',
      };
      final cookie = _cookieHeader();
      if (cookie != null) headers['Cookie'] = cookie;

      final resp = await _client.get(uri, headers: headers).timeout(
            const Duration(seconds: 12),
          );

      _updateCookiesFromResponse(resp);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final username = (data['username'] ?? '') as String;
        final firstName = (data['first_name'] ?? '') as String;
        final lastName = (data['last_name'] ?? '') as String;
        final email = (data['email'] ?? '') as String;
        print('DEBUG /me -> username=$username, first=$firstName, last=$lastName, email=$email');
        print('$resp.body');
        print('$data');
        return User(
          username: username,
          firstName: firstName,
          lastName: lastName,
          email: email,
          token: bearerToken,
        );
      } else if (resp.statusCode == 401) {
        throw ApiException('Token invalid or expired', statusCode: 401);
      } else {
        throw ApiException(
          'Get /me failed (${resp.statusCode}): ${resp.body}',
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

  Future<User> getMeWithBearer(String bearerToken) async {
    return _getMeWithBearer(bearerToken);
  }

  Future<User> login(String username, String password) async {
    final token = await _getTokenByBasicAuth(username: username, password: password);
    final user = await _getMeWithBearer(token);
    return user;
  }

  Future<void> logout(String bearerToken) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _cookieJar.clear();
  }
}
