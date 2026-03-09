import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = kIsWeb
      ? 'http://localhost:8000'
      : 'http://10.0.2.2:8000'; // Standard Android Emulator loopback
  final _storage = const FlutterSecureStorage();

  Future<String?> get _token async => await _storage.read(key: 'jwt_token');

  Future<Map<String, String>> _getHeaders() async {
    final token = await _token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: await _getHeaders());
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.put(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
  }

  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.delete(url, headers: await _getHeaders());
  }

  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.patch(
      url,
      headers: await _getHeaders(),
      body: jsonEncode(data),
    );
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }
}
