import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api";
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // ================= LOGIN =================
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode({"name": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        await _storage.write(key: "token", value: body["access_token"]);
        await _storage.write(key: "role", value: body["role"]);
        return Map<String, dynamic>.from(body);
      } else {
        print("Login échoué : ${response.body}");
        return null;
      }
    } catch (e) {
      print("Erreur login: $e");
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
        print("Erreur getRapports: data n’est pas une liste (${data.runtimeType})");
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

      print("UPDATE RAPPORT STATUS: ${response.statusCode}");
      print("UPDATE RAPPORT BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("Erreur updateRapport: $e");
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

      print("DELETE RAPPORT STATUS: ${response.statusCode}");
      print("DELETE RAPPORT BODY: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Erreur deleteRapport: $e");
      return false;
    }
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    await _storage.delete(key: "token");
    await _storage.delete(key: "role");
  }
}
