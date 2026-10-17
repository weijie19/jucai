import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WebDavConfig {
  final String baseUrl;
  final String username;
  final String password;

  const WebDavConfig({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  String get backupUrl {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    return '$base/jucai/backup.json';
  }
}

const _kBaseUrl = 'webdav_base_url';
const _kUser = 'webdav_user';
const _kPassword = 'webdav_password';

Future<void> saveWebDavConfig(WebDavConfig cfg) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kBaseUrl, cfg.baseUrl);
  await prefs.setString(_kUser, cfg.username);
  await prefs.setString(_kPassword, cfg.password);
}

Future<WebDavConfig?> loadWebDavConfig() async {
  final prefs = await SharedPreferences.getInstance();
  final baseUrl = prefs.getString(_kBaseUrl);
  final user = prefs.getString(_kUser);
  final password = prefs.getString(_kPassword);
  if (baseUrl == null || baseUrl.isEmpty) return null;
  return WebDavConfig(baseUrl: baseUrl, username: user ?? '', password: password ?? '');
}

Future<void> uploadBackup(WebDavConfig cfg, String jsonBody) async {
  final headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Authorization': 'Basic ${base64Encode(utf8.encode('${cfg.username}:${cfg.password}'))}',
  };
  final resp = await http.put(Uri.parse(cfg.backupUrl), headers: headers, body: jsonBody);
  if (resp.statusCode >= 300) {
    throw Exception('上传失败：HTTP ${resp.statusCode}');
  }
}

Future<String> downloadBackup(WebDavConfig cfg) async {
  final headers = {
    'Authorization': 'Basic ${base64Encode(utf8.encode('${cfg.username}:${cfg.password}'))}',
  };
  final resp = await http.get(Uri.parse(cfg.backupUrl), headers: headers);
  if (resp.statusCode >= 300) {
    throw Exception('下载失败：HTTP ${resp.statusCode}');
  }
  return utf8.decode(resp.bodyBytes);
}
