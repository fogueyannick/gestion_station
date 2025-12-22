import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import 'log_service.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Timeout pour les requêtes
  static const Duration _timeout = Duration(seconds: 30);

  // ================= LOGIN =================
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");

    try {
      LogService.api('POST', '/auth/login');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode({"name": username, "password": password}),
      ).timeout(_timeout);

      LogService.api('POST', '/auth/login', statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        await _storage.write(key: "token", value: body["access_token"]);
        await _storage.write(key: "role", value: body["role"]);
        LogService.info("Login réussi pour l'utilisateur: $username");
        return Map<String, dynamic>.from(body);
      } else {
        LogService.warning("Login échoué: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e, stackTrace) {
      LogService.error("Erreur lors du login", e, stackTrace);
      return null;
    }
  }

  // ================= GET RAPPORTS =================
  static Future<List<Map<String, dynamic>>> getRapports() async {
    final token = await _storage.read(key: "token");
    if (token == null) throw Exception("Token manquant");

    final url = Uri.parse("$baseUrl/reports");

    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Vérifie que c’est bien une liste
      if (data is List) {
        return data.map<Map<String, dynamic>>((r) {
          if (r is Map) return Map<String, dynamic>.from(r);
          return {}; // si l’élément n’est pas une Map
        }).toList();
      } else {
        LogService.error("getRapports: data n'est pas une liste (${data.runtimeType})");
        return [];
      }
    }

    throw Exception("Erreur getRapports: ${response.statusCode}");
  }

  // ================= UPDATE RAPPORT =================
  static Future<bool> updateRapport({
    required int id,
    required Map<String, dynamic> payload,
  }) async {
    final token = await _storage.read(key: "token");
    if (token == null) return false;

    final url = Uri.parse("$baseUrl/reports/$id");

    try {
      final response = await http.put(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      LogService.api('PUT', '/reports/$id', statusCode: response.statusCode);
      LogService.debug("UPDATE RAPPORT BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      LogService.error("Erreur updateRapport", e, stackTrace);
      return false;
    }
  }

  // ================= DELETE RAPPORT =================
  static Future<bool> deleteRapport({required int id}) async {
    final token = await _storage.read(key: "token");
    if (token == null) return false;

    final url = Uri.parse("$baseUrl/reports/$id");

    try {
      final response = await http.delete(url, headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      LogService.api('DELETE', '/reports/$id', statusCode: response.statusCode);
      LogService.debug("DELETE RAPPORT BODY: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e, stackTrace) {
      LogService.error("Erreur deleteRapport", e, stackTrace);
      return false;
    }
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    await _storage.delete(key: "token");
    await _storage.delete(key: "role");
  }
}
