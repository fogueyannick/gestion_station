import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ReportSummaryScreen extends StatefulWidget {
  const ReportSummaryScreen({super.key});

  @override
  State<ReportSummaryScreen> createState() => _ReportSummaryScreenState();
}

class _ReportSummaryScreenState extends State<ReportSummaryScreen> {
  static const String baseUrl = "http://10.0.2.2:8000/api";
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

  // ================= ENVOI =================
  Future<bool> sendReport() async {
    final token = await storage.read(key: "token");
    if (token == null) return false;

    final request =
        http.MultipartRequest("POST", Uri.parse("$baseUrl/reports"));

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
        formattedDate =
            DateTime.parse(raw).toIso8601String().split("T")[0];
      }
    } catch (_) {
      return false;
    }

    // -------- CHAMPS --------
    request.fields.addAll({
      "station_id": "1",
      "date": formattedDate,

      "super1_index": data["super1"].toString(),
      "super2_index": data["super2"].toString(),
      "super3_index": data["super3"].toString(),

      "gazoil1_index": data["gaz1"].toString(),
      "gazoil2_index": data["gaz2"].toString(),
      "gazoil3_index": data["gaz3"].toString(),

      "stock_sup_9000": data["stock_sup_9000"].toString(),
      "stock_sup_10000": data["stock_sup_10000"].toString(),
      "stock_sup_14000": data["stock_sup_14000"].toString(),
      "stock_gaz_10000": data["stock_gaz_10000"].toString(),
      "stock_gaz_6000": data["stock_gaz_6000"].toString(),

      "versement": data["depot_banque"].toString(),

    });

    final depenses = data["depenses"] as List<dynamic>? ?? [];
    for (int i = 0; i < depenses.length; i++) {
      request.fields["depenses[$i][nom]"] =
          depenses[i]["nom"].toString();
      request.fields["depenses[$i][montant]"] =
          depenses[i]["montant"].toString();
    }

    final autresVentes = data["autres_ventes"] as List<dynamic>? ?? [];
    for (int i = 0; i < autresVentes.length; i++) {
      request.fields["autres_ventes[$i][nom]"] =
          autresVentes[i]["nom"].toString();
      request.fields["autres_ventes[$i][montant]"] =
          autresVentes[i]["montant"].toString();
    }

    final commandes = data["commandes"] as List<dynamic>? ?? [];
    for (int i = 0; i < commandes.length; i++) {
      request.fields["commandes[$i][produit]"] =
          commandes[i]["produit"].toString();
      request.fields["commandes[$i][quantite]"] =
          commandes[i]["quantite"].toString();
      request.fields["commandes[$i][livraison]"] =
          commandes[i]["livraison"].toString();
    }

    // -------- PHOTOS --------
    final photos = data["photos"] as Map<String, dynamic>? ?? {};
    for (final entry in photos.entries) {
      final file = entry.value;
      if (file is File && file.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "photos[${entry.key}]",
            file.path,
          ),
        );
      }
    }

    // -------- ENVOI --------
    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint("❌ ${response.statusCode} => $body");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Exception => $e");
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
