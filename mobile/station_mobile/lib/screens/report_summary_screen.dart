import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'dart:io';
import 'package:image_picker/image_picker.dart';


class ReportSummaryScreen extends StatefulWidget {
  const ReportSummaryScreen({super.key});

  @override
  State<ReportSummaryScreen> createState() => _ReportSummaryScreenState();
}

class _ReportSummaryScreenState extends State<ReportSummaryScreen> {
  static const String baseUrl = "https://gestion-station-backend-1.onrender.com/api";
  //static const String baseUrl = "http://10.0.2.2:8000/api";
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  late Map<String, dynamic> data;
  bool isSending = false;

  double totalDepenses = 0;
  double totalAutresVentes = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    data = args is Map ? _forceStringKeys(args) : {};

    totalDepenses = (data["depenses"] as List<dynamic>?)
            ?.fold(
                0.0,
                (s, e) =>
                    s! + (double.tryParse(e["montant"].toString()) ?? 0.0)) ??
        0.0;

    totalAutresVentes = (data["autres_ventes"] as List<dynamic>?)
            ?.fold(
                0.0,
                (s, e) =>
                    s! + (double.tryParse(e["montant"].toString()) ?? 0.0)) ??
        0.0;
  }

  Map<String, dynamic> _forceStringKeys(Map<dynamic, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = _forceStringKeys(value);
      } else if (value is List) {
        result[key.toString()] =
            value.map((e) => e is Map ? _forceStringKeys(e) : e).toList();
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }


  Future<Object> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = p.join(
      dir.path,
      "${DateTime.now().millisecondsSinceEpoch}.jpg",
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60, // 🔥 clé ici (50–70 recommandé)
    );

    return result ?? file;
  }

  Future<bool> sendReport() async {
    final token = await storage.read(key: "token");
    if (token == null) return false;

    final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/reports"));
    request.headers.addAll({
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    // -------- DATE --------
    String formattedDate;
    try {
      final raw = data["date"].toString();
      if (raw.contains("/")) {
        final p = raw.split("/");
        formattedDate = DateTime(
          int.parse(p[2]),
          int.parse(p[1]),
          int.parse(p[0]),
        ).toIso8601String().split("T")[0];
      } else {
        formattedDate = DateTime.parse(raw).toIso8601String().split("T")[0];
      }
    } catch (e) {
      debugPrint("❌ Erreur parsing date: $e");
      return false;
    }

    // -------- CHAMPS --------
    request.fields.addAll({
      "station_id": "1",
      "date": formattedDate,
      "super1_index": data["super1"]?.toString() ?? '',
      "super2_index": data["super2"]?.toString() ?? '',
      "super3_index": data["super3"]?.toString() ?? '',
      "gazoil1_index": data["gaz1"]?.toString() ?? '',
      "gazoil2_index": data["gaz2"]?.toString() ?? '',
      "gazoil3_index": data["gaz3"]?.toString() ?? '',
      "stock_sup_9000": data["stock_sup_9000"]?.toString() ?? '',
      "stock_sup_10000": data["stock_sup_10000"]?.toString() ?? '',
      "stock_sup_14000": data["stock_sup_14000"]?.toString() ?? '',
      "stock_gaz_10000": data["stock_gaz_10000"]?.toString() ?? '',
      "stock_gaz_6000": data["stock_gaz_6000"]?.toString() ?? '',
      "versement": data["depot_banque"]?.toString() ?? '',
    });

    // -------- LISTES --------
    void addListField(String name, List<dynamic> items) {
      for (int i = 0; i < items.length; i++) {
        items[i].forEach((key, value) {
          request.fields["$name[$i][$key]"] = value?.toString() ?? '';
        });
      }
    }

    addListField("depenses", data["depenses"] ?? []);
    addListField("autres_ventes", data["autres_ventes"] ?? []);
    addListField("commandes", data["commandes"] ?? []);

    // -------- PHOTOS --------
    final photos = data["photos"] as Map<String, dynamic>? ?? {};
    int i = 0;

    for (final entry in photos.entries) {
      final compressed = await compressImage(entry.value);

      File file;
      if (compressed is File) {
        file = compressed;
      } else if (compressed is XFile) {
        file = File(compressed.path);
      } else {
        file = File((compressed as dynamic).path);
      }

      if (!file.existsSync()) continue;

      try {
        // 1️⃣ Récupérer signed URL PUT depuis le backend
        final urlResponse = await http.post(
          Uri.parse("$baseUrl/signed-url"),
          headers: {
            "Authorization": "Bearer $token",
            "Accept": "application/json",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "key": entry.key,
            "extension": "jpg",
          }),
        );

        if (urlResponse.statusCode != 200) {
          debugPrint("❌ Erreur signed URL pour ${entry.key}");
          return false;
        }

        final jsonData = Map<String, dynamic>.from(jsonDecode(urlResponse.body));
        final uploadUrl = jsonData["upload_url"] as String? ?? '';
        final publicUrl = jsonData["public_url"] as String? ?? '';

        if (uploadUrl.isEmpty) {
          debugPrint("❌ uploadUrl vide pour ${entry.key}");
          return false;
        }

        // 2️⃣ Upload direct sur GCS
        final uploadResponse = await http.put(
          Uri.parse(uploadUrl),
          headers: {"Content-Type": "image/jpeg"},
          body: await file.readAsBytes(),
        );

        if (uploadResponse.statusCode != 200 &&
            uploadResponse.statusCode != 201) {
          debugPrint(
              "❌ Erreur upload ${entry.key} : ${uploadResponse.statusCode}");
          return false;
        }

        // 3️⃣ Ajouter URL publique dans le multipart request
        request.fields["photos_keys[$i]"] = entry.key;
        request.fields["photos_urls[$i]"] = publicUrl;
        i++;
      } catch (e) {
        debugPrint("❌ Exception upload photo ${entry.key}: $e");
        return false;
      }
    }

    // -------- ENVOI FINAL --------
    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();

      debugPrint("📦 STATUS: ${response.statusCode}");
      debugPrint("📦 BODY: $body");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("❌ Exception lors de l'envoi: $e");
      return false;
    }
  }

  // ================= UI =================
  Widget buildRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          value is File
              ? Image.file(value, width: 50, height: 50, fit: BoxFit.cover)
              : Text("$value",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget buildCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final photos = data["photos"] as Map<String, dynamic>? ?? {};
    final commandes = data["commandes"] as List<dynamic>? ?? [];
    final autresVentes = data["autres_ventes"] as List<dynamic>? ?? [];
    final depenses = data["depenses"] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Résumé du rapport")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildCard("INDEX SUPER", [
              buildRow("Super 1", photos["super1"] ?? data["super1"]),
              buildRow("Super 2", photos["super2"] ?? data["super2"]),
              buildRow("Super 3", photos["super3"] ?? data["super3"]),
            ]),
            buildCard("INDEX GAZOIL", [
              buildRow("Gazoil 1", photos["gaz1"] ?? data["gaz1"]),
              buildRow("Gazoil 2", photos["gaz2"] ?? data["gaz2"]),
              buildRow("Gazoil 3", photos["gaz3"] ?? data["gaz3"]),
            ]),
            buildCard("STOCKS", [
              buildRow("Sup 9000 L", data["stock_sup_9000"]),
              buildRow("Sup 10000 L", data["stock_sup_10000"]),
              buildRow("Sup 14000 L", data["stock_sup_14000"]),
              buildRow("Gaz 10000 L", data["stock_gaz_10000"]),
              buildRow("Gaz 6000 L", data["stock_gaz_6000"]),
            ]),
            buildCard(
              "COMMANDES PRODUITS",
              commandes.isEmpty
                  ? [const Text("Aucune commande")]
                  : commandes.map((c) {
                      return ListTile(
                        title: Text(
                          "${c["produit"]} - ${c["quantite"]} L",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Livraison : ${c["livraison"]}"),
                      );
                    }).toList(),
            ),
            buildCard(
              "AUTRES VENTES",
              autresVentes.isEmpty
                  ? [const Text("Aucune autre vente")]
                  : [
                      ...autresVentes.map((v) => ListTile(
                            title: Text(v["nom"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            trailing: Text("${v["montant"]} FCFA"),
                          )),
                      const Divider(),
                      buildRow(
                          "TOTAL",
                          "${totalAutresVentes.toStringAsFixed(2)} FCFA"),
                    ],
            ),
            buildCard(
              "DÉPENSES",
              depenses.isEmpty
                  ? [const Text("Aucune dépense")]
                  : [
                      ...depenses.map((d) => ListTile(
                            title: Text(d["nom"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            trailing: Text("${d["montant"]} FCFA"),
                          )),
                      const Divider(),
                      buildRow(
                          "TOTAL",
                          "${totalDepenses.toStringAsFixed(2)} FCFA"),
                    ],
            ),
            buildCard("FINANCES", [
              buildRow("Dépôt banque", "${data["depot_banque"]} FCFA"),
            ]),
            const SizedBox(height: 20),

            // 🔥 BOUTON ENVOYER 🔥
            ElevatedButton(
              onPressed: isSending
                  ? null
                  : () async {
                      setState(() => isSending = true);
                      final ok = await sendReport();
                      setState(() => isSending = false);

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok
                              ? "Rapport envoyé avec succès"
                              : "Erreur lors de l'envoi"),
                        ),
                      );

                      if (ok) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, "/login", (_) => false);
                      }
                    },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Text(isSending ? "Envoi..." : "Envoyer le rapport"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
