import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  String baseUrl = 'http://172.20.10.3:8000';
  String? _token;
  Map<String, dynamic>? currentUser;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    baseUrl = prefs.getString('baseUrl') ?? baseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', url);
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  String? get token => _token;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({bool withAuth = false}) {
    final headers = {HttpHeaders.acceptHeader: 'application/json'};
    if (withAuth && _token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/login'),
      headers: _headers(),
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] ?? data['access_token'];
      if (token is String) {
        await _saveToken(token);
      }
      currentUser = data['user'] is Map<String, dynamic>
          ? data['user'] as Map<String, dynamic>
          : null;
      return data;
    }
    throw HttpException('Login gagal (${response.statusCode})');
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      _uri('/api/register'),
      headers: _headers(),
      body: {'name': name, 'email': email, 'password': password},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    }
    throw HttpException('Register gagal (${response.statusCode})');
  }

  Future<Map<String, dynamic>> registerFace({required File file}) async {
    final request = http.MultipartRequest('POST', _uri('/api/register-face'))
      ..headers.addAll(_headers(withAuth: true))
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw HttpException('Register face gagal (${response.statusCode})');
  }

  Future<Map<String, dynamic>> verifyFace({required File file}) async {
    final request = http.MultipartRequest('POST', _uri('/api/verify-face'))
      ..headers.addAll(_headers(withAuth: true))
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final bodyString = response.body;
    Map<String, dynamic>? json;
    try {
      json = jsonDecode(bodyString) as Map<String, dynamic>;
    } catch (_) {}

    // Return response jika ada valid JSON (baik 200 OK maupun error response)
    if (json != null) {
      return json;
    }

    // Jika tidak ada valid JSON response
    final friendly = 'Layanan verifikasi wajah bermasalah. Coba lagi.';
    throw HttpException(friendly);
  }

  Future<void> logout() async {
    _token = null;
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<List<Map<String, dynamic>>> fetchAttendances() async {
    final response = await http.get(
      _uri('/api/attendances'),
      headers: _headers(withAuth: true),
    );

    if (response.statusCode != 200) {
      final msg = 'Gagal memuat data absensi (${response.statusCode})';
      throw HttpException(msg);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) return data.cast<Map<String, dynamic>>();
    }
    throw HttpException('Format data absensi tidak dikenali');
  }

  Future<Map<String, dynamic>?> fetchTodayAttendance() async {
    try {
      final response = await http.get(
        _uri('/api/attendances/today'),
        headers: _headers(withAuth: true),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded['data'] as Map<String, dynamic>?;
        }
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('check_in')) {
          return decoded;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
