import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';


Future<void> exportCsv(BuildContext context, List<Map<String, dynamic>> rapports) async {
  List<List<dynamic>> rows = [];

  // En-têtes CSV
  rows.add([
    "Date",
    "Rapporteur",
    "Super1",
    "Super2",
    "Super3",
    "Gaz1",
    "Gaz2",
    "Gaz3",
    "Versement",
    "Total Dépenses"
  ]);

  for (var r in rapports) {
    final totalDepenses = (r["depenses"] as List<dynamic>)
        .fold(0, (sum, d) => sum + (d["montant"] as int));
    rows.add([
      r["date"],
      r["rapporteur"],
      r["index_super"]["super1"],
      r["index_super"]["super2"],
      r["index_super"]["super3"],
      r["index_gaz"]["gaz1"],
      r["index_gaz"]["gaz2"],
      r["index_gaz"]["gaz3"],
      r["versement"],
      totalDepenses
    ]);
  }

  String csv = const ListToCsvConverter().convert(rows);

  final directory = await getApplicationDocumentsDirectory();
  final path = "${directory.path}/rapport_export.csv";
  final file = File(path);
  await file.writeAsString(csv);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("CSV exporté : $path")),
  );
}
