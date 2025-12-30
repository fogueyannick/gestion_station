/* */
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:station_mobile/screens/login_screen.dart';

import '../../services/api.dart';
import '../utils/date_utils.dart'; // pour formatDate

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final storage = const FlutterSecureStorage();

  static const double prixSuper = 840;
  static const double prixGazoil = 828;

  Future<List<Map<String, dynamic>>>? futureRapports;

  List<Map<String, dynamic>> filteredDayForPDF = [];

  String? selectedMonth;
  String? selectedDay;

  double round2(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  @override
  void initState() {
    super.initState();
    futureRapports = ApiService.getRapports();
  }

  // ==================== UTILITAIRES ====================
  DateTime parseDate(dynamic date) {
    if (date == null) throw Exception("Date invalide : null");
    if (date is DateTime) return date;
    if (date is int || date is double) {
      final epoch = DateTime(1899, 12, 30);
      return epoch.add(Duration(days: date.toInt()));
    }
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (_) {
        try {
          return DateFormat('d/M/yyyy').parse(date);
        } catch (_) {
          try {
            return DateFormat('dd/MM/yyyy').parse(date);
          } catch (e) {
            throw FormatException("Date invalide : $date");
          }
        }
      }
    }
    throw Exception("Format de date inconnu : $date");
  }

  double parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  //double diff(double a, double b) => a < b ? 0.0 : a - b;

  double diff(dynamic a, dynamic b) {
  final da = parseDouble(a);
  final db = parseDouble(b);
  return da < db ? 0.0 : da - db;
}


  List<dynamic> _decodeList(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      try {
        return jsonDecode(value) as List<dynamic>;
      } catch (_) {
        return [];
      }
    }
    if (value is List) return value;
    return [];
  }

  double _sumMontants(dynamic value) {
    final list = _decodeList(value);
    return list.fold<double>(
      0.0,
      (sum, e) => sum + parseDouble(e['montant']),
    );
  }

  Map<String, dynamic> _decodeMap(dynamic value) {
    if (value == null) return {};
    if (value is String) {
      try {
        return jsonDecode(value) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    }
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }


  String monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);
  String monthLabel(String key) => formatDate(DateTime.parse('$key-01'), 'MMMM yyyy', locale: 'fr');

  // ==================== Graphique journalier ====================
  Widget buildDailyChart(List<Map<String, dynamic>> chartData) {
    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  int idx = value.toInt();
                  if (idx < 0 || idx >= chartData.length) return const SizedBox.shrink();
                  return Text(chartData[idx]['label'], style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: chartData.asMap().entries.map((e) {
                //return FlSpot(e.key.toDouble(), e.value['venteFcfa'].toDouble());
                return FlSpot(e.key.toDouble(),parseDouble(e.value['venteFcfa']),);
              }).toList(),
              isCurved: true,
              barWidth: 3,
              dotData: FlDotData(show: true),
              color: Colors.indigo,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Colors.indigo.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBorder: BorderSide(color: Colors.indigo),
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipColor: (LineBarSpot touchedSpot) => Colors.indigo.shade700,
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.spotIndex;
                  //final vente = chartData[idx]['venteFcfa'];
                  //final ecart = chartData[idx]['ecartBanque'];

                  final vente = parseDouble(chartData[idx]['venteFcfa']);
                  final ecart = parseDouble(chartData[idx]['ecartBanque']);

                  return LineTooltipItem(
                    'Vente: ${vente.toStringAsFixed(0)} FCFA\nÉcart: ${ecart.toStringAsFixed(0)} FCFA',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }


  Widget indexWithPhoto({
  required String label,
  required dynamic value,
  String? photoUrl,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label : $value L"),
        if (photoUrl != null && photoUrl.isNotEmpty) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: InteractiveViewer(
                    child: Image.network(photoUrl),
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                height: 90,
                width: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

  // ==================== Export PDF ====================
  Future<void> exportPDFComplet(List<Map<String, dynamic>> filteredDay) async {
  final pdf = pw.Document();

  for (var r in filteredDay) {
    final dateStr = formatDate(parseDate(r['date']), 'dd/MM/yyyy', locale: 'fr');

    final superTotal = diff(r['super1_index'], 0) +
        diff(r['super2_index'], 0) +
        diff(r['super3_index'], 0);
    final gazTotal = diff(r['gazoil1_index'], 0) +
        diff(r['gazoil2_index'], 0) +
        diff(r['gazoil3_index'], 0);

    final venteSuper = superTotal * prixSuper;
    final venteGazoil = gazTotal * prixGazoil;
    final autresVentes = _sumMontants(r['autres_ventes']);
    final totalVentes = venteSuper + venteGazoil + autresVentes;

    final depenses = _sumMontants(r['depenses']);
    final versement = parseDouble(r['versement']);
    final theorique = totalVentes - depenses;


    List<pw.Widget> photoWidgets = [];

    final photos = _decodeList(r['photos']); 
    // photos = [{key: super1, path: reports/1/xxx.jpg}, ...]

    for (final p in photos) {
      final path = p['path'];

      if (path != null && path.toString().isNotEmpty) {
        try {
          final image = await networkImage(
            '${ApiService.baseUrl}/storage/$path',
          );

          photoWidgets.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  p['key'].toString().toUpperCase(),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Image(
                  image,
                  width: 120,
                  height: 90,
                  fit: pw.BoxFit.cover,
                ),
                pw.SizedBox(height: 8),
              ],
            ),
          );
        } catch (_) {
          // ignore image errors
        }
      }
    }


    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Rapport du $dateStr', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),

            pw.Text('Ventes carburant :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: 'Super1 index : ${r['super1_index']} L'),
            pw.Bullet(text: 'Super2 index : ${r['super2_index']} L'),
            pw.Bullet(text: 'Super3 index : ${r['super3_index']} L'),
            pw.Bullet(text: 'Vente total super : ${venteSuper.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),

            pw.Bullet(text: 'Gazoil1 index : ${r['gazoil1_index']} L'),
            pw.Bullet(text: 'Gazoil2 index : ${r['gazoil2_index']} L'),
            pw.Bullet(text: 'Gazoil3 index : ${r['gazoil3_index']} L'),
            pw.Bullet(text: 'Vente total super : ${venteGazoil.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

            pw.SizedBox(height: 8),


            if (photoWidgets.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                'Photos justificatives :',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),

              pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: photoWidgets,
              ),

              pw.SizedBox(height: 12),
            ],


            if ((r['autres_ventes'] as List).isNotEmpty)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Autres ventes :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ...List<pw.Widget>.from((r['autres_ventes'] as List).map((v) =>
                      pw.Bullet(text: "${v['nom']} : ${v['montant']} FCFA"))),
                  pw.SizedBox(height: 8),
                ],
              ),

            pw.Text('Total des ventes : ${totalVentes.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),

            if ((r['depenses'] as List).isNotEmpty)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Dépenses :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ...List<pw.Widget>.from((r['depenses'] as List).map((v) =>
                      pw.Bullet(text: "${v['nom']} : ${v['montant']} FCFA"))),
                  pw.SizedBox(height: 8),
                ],
              ),

            if ((r['commandes'] as List).isNotEmpty)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Commandes :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ...List<pw.Widget>.from((r['commandes'] as List).map((v) =>
                      pw.Bullet(text: "${v['produit']} - Quantité : ${v['quantite']} (Livraison : ${v['livraison']})"))),
                  pw.SizedBox(height: 8),
                ],
              ),

            pw.Text('Stocks : ${r['stocks'] ?? 0}'),
            pw.Text('Versement en banque : ${r['versement'] ?? 0} FCFA'),
            pw.Text('Théorique banque : ${theorique.toStringAsFixed(0)} FCFA',
                style: pw.TextStyle(
                  color: theorique > versement ? PdfColor.fromInt(0xFFB00020) : PdfColor.fromInt(0xFF00A000),
                )),
          ],
        ),
      ),
    );
  }

  await Printing.layoutPdf(onLayout: (_) => pdf.save());
}



  // ==================== Export Excel ====================
  Future<void> exportExcel(double ventesTotale, double depenses, double versement) async {
    final excel = Excel.createExcel();
    final sheet = excel['Rapport'];

    sheet.appendRow([TextCellValue('Vente totale'), DoubleCellValue(ventesTotale)]);
    sheet.appendRow([TextCellValue('Dépenses'), DoubleCellValue(depenses)]);
    sheet.appendRow([TextCellValue('Théorique banque'), DoubleCellValue(ventesTotale - depenses)]);
    sheet.appendRow([TextCellValue('Versement'), DoubleCellValue(versement)]);

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/rapport.xlsx');
    await file.writeAsBytes(excel.encode()!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excel exporté : ${file.path}')),
    );
  }

  // ==================== Dialog Modifier ====================
  Future<void> showInteractiveEditDialog(Map<String, dynamic> rapport) async {
    final super1Controller = TextEditingController(text: rapport['super1_index'].toString());
    final super2Controller = TextEditingController(text: rapport['super2_index'].toString());
    final super3Controller = TextEditingController(text: rapport['super3_index'].toString());
    final gaz1Controller = TextEditingController(text: rapport['gazoil1_index'].toString());
    final gaz2Controller = TextEditingController(text: rapport['gazoil2_index'].toString());
    final gaz3Controller = TextEditingController(text: rapport['gazoil3_index'].toString());
    //final depController = TextEditingController(text: (rapport['depenses'] ?? 0).toString());

    final depController = TextEditingController(text: _sumMontants(rapport['depenses']).toStringAsFixed(0),);

    final versementController = TextEditingController(text: (rapport['versement'] ?? 0).toString());

    double ventesTotal = 0;
    double ecart = 0;

    void recalc() {
      final superL = (double.tryParse(super1Controller.text) ?? 0) +
          (double.tryParse(super2Controller.text) ?? 0) +
          (double.tryParse(super3Controller.text) ?? 0);
      final gazL = (double.tryParse(gaz1Controller.text) ?? 0) +
          (double.tryParse(gaz2Controller.text) ?? 0) +
          (double.tryParse(gaz3Controller.text) ?? 0);

      ventesTotal = (superL * prixSuper + gazL * prixGazoil).toDouble();
      ecart = ventesTotal - (double.tryParse(depController.text) ?? 0) - (double.tryParse(versementController.text) ?? 0);
    }

    recalc();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          super1Controller.addListener(() => setStateDialog(recalc));
          super2Controller.addListener(() => setStateDialog(recalc));
          super3Controller.addListener(() => setStateDialog(recalc));
          gaz1Controller.addListener(() => setStateDialog(recalc));
          gaz2Controller.addListener(() => setStateDialog(recalc));
          gaz3Controller.addListener(() => setStateDialog(recalc));
          depController.addListener(() => setStateDialog(recalc));
          versementController.addListener(() => setStateDialog(recalc));

          return AlertDialog(
            title: const Text('Modifier le rapport'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: super1Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Super 1 (L)')),
                  TextField(controller: super2Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Super 2 (L)')),
                  TextField(controller: super3Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Super 3 (L)')),
                  TextField(controller: gaz1Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gazoil 1 (L)')),
                  TextField(controller: gaz2Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gazoil 2 (L)')),
                  TextField(controller: gaz3Controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Gazoil 3 (L)')),
                  TextField(controller: depController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Dépenses (FCFA)')),
                  TextField(controller: versementController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Versement (FCFA)')),
                  const SizedBox(height: 12),
                  Text('Ventes totales : ${ventesTotal.toStringAsFixed(0)} FCFA'),
                  Text('Écart bancaire : ${ecart.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ecart >= 0 ? Colors.green : Colors.red,
                      )),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  await ApiService.updateRapport(
                    id: rapport['id'],
                    payload: {
                      'super1_index': double.tryParse(super1Controller.text) ?? 0,
                      'super2_index': double.tryParse(super2Controller.text) ?? 0,
                      'super3_index': double.tryParse(super3Controller.text) ?? 0,
                      'gazoil1_index': double.tryParse(gaz1Controller.text) ?? 0,
                      'gazoil2_index': double.tryParse(gaz2Controller.text) ?? 0,
                      'gazoil3_index': double.tryParse(gaz3Controller.text) ?? 0,
                      'depenses': double.tryParse(depController.text) ?? 0,
                      'versement': double.tryParse(versementController.text) ?? 0,
                    },
                  );

                  Navigator.pop(ctx);
                  setState(() {
                    futureRapports = ApiService.getRapports();
                  });
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        });
      },
    );
  }

  // ==================== Dialog Supprimer ====================
  Future<void> showDeleteDialog(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le rapport'),
        content: const Text('Voulez-vous vraiment supprimer ce rapport ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await ApiService.deleteRapport(id: id);
        if (success) {
          setState(() {
            futureRapports = futureRapports!.then((list) => list.where((r) => r['id'] != id).toList());
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rapport supprimé avec succès')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de supprimer le rapport')));
        }
      } catch (e) {
        print("Erreur suppression : $e");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la suppression')));
      }
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
/*       appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await storage.deleteAll();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ), */
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter PDF',
            onPressed: () async {
              if (filteredDayForPDF.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Aucun rapport sélectionné pour le PDF")),
                );
                return;
              }
              await exportPDFComplet(filteredDayForPDF);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await storage.deleteAll();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureRapports,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final rapports = snapshot.data!;

          // Décoder JSON si nécessaire
          for (var r in rapports) {
            r['depenses'] = _decodeList(r['depenses']);
            r['commandes'] = _decodeList(r['commandes']);
            r['autres_ventes'] = _decodeList(r['autres_ventes']);
          
            //r['photos'] = _decodeList(r['photos']);
            //r['photos'] = _decodeMap(r['photos']);
            r['photos'] = _decodeList(r['photos']);


            print(r);
          }

          final months = rapports.map((r) => monthKey(parseDate(r['date']))).toSet().toList()..sort();
          selectedMonth ??= months.isNotEmpty ? months.last : null;

          final filteredMonth = rapports.where((r) => selectedMonth != null && monthKey(parseDate(r['date'])) == selectedMonth).toList();
          final days = filteredMonth.map((r) => DateFormat('yyyy-MM-dd').format(parseDate(r['date']))).toSet().toList()..sort();

          filteredMonth.sort((a, b) => parseDate(a['date']).compareTo(parseDate(b['date'])));
          selectedDay = (selectedDay != null && days.contains(selectedDay)) ? selectedDay : (days.isNotEmpty ? days.last : null);
          final filteredDay = filteredMonth.where((r) => selectedDay != null && DateFormat('yyyy-MM-dd').format(parseDate(r['date'])) == selectedDay).toList();
          filteredDay.sort((a, b) => parseDate(a['date']).compareTo(parseDate(b['date'])));

          
          filteredDayForPDF = filteredDay;


          // ===== Indicateurs journaliers =====
          double ventesFcfa = 0;
          for (var r in filteredDay) {
            Map<String, dynamic>? prev;
            final rDateStr = DateFormat('yyyy-MM-dd').format(parseDate(r['date']));
            for (int j = filteredMonth.indexOf(r) - 1; j >= 0; j--) {
              final prevDateStr = DateFormat('yyyy-MM-dd').format(parseDate(filteredMonth[j]['date']));
              if (prevDateStr != rDateStr) {  
                prev = filteredMonth[j];
                break;
              }
            }

            //final superL = diff(r['super1_index'], prev?['super1_index'] ?? 0) +
                //diff(r['super2_index'], prev?['super2_index'] ?? 0) +
                //diff(r['super3_index'], prev?['super3_index'] ?? 0);


            final superL =
              diff(parseDouble(r['super1_index']), parseDouble(prev?['super1_index'])) +
              diff(parseDouble(r['super2_index']), parseDouble(prev?['super2_index'])) +
              diff(parseDouble(r['super3_index']), parseDouble(prev?['super3_index']));

            //final gazL = diff(r['gazoil1_index'], prev?['gazoil1_index'] ?? 0) +
                //diff(r['gazoil2_index'], prev?['gazoil2_index'] ?? 0) +
                //diff(r['gazoil3_index'], prev?['gazoil3_index'] ?? 0);

            final gazL =
                diff(parseDouble(r['gazoil1_index']), parseDouble(prev?['gazoil1_index'])) +
                diff(parseDouble(r['gazoil2_index']), parseDouble(prev?['gazoil2_index'])) +
                diff(parseDouble(r['gazoil3_index']), parseDouble(prev?['gazoil3_index']));


            ventesFcfa += (superL * prixSuper) + (gazL * prixGazoil);
          }

          
          final depenses = filteredDay.fold<double>(
            0,
            (s, r) => s + _sumMontants(r['depenses']),
          );

          final totalAutresVentes = filteredDay.fold<double>(
            0,
            (s, r) => s + _sumMontants(r['autres_ventes']),
          );

          final versement = filteredDay.fold<double>(0, (s, r) => s + parseDouble(r['versement']));

          final totalDesVentes = ventesFcfa + totalAutresVentes;

          final theorique = totalDesVentes - depenses;

          final alert = versement < theorique;


          
          // Graphique journalier
          List<Map<String, dynamic>> chartData = [];
          for (int i = 1; i < filteredMonth.length; i++) {
            final r = filteredMonth[i];
            final prev = i > 0 ? filteredMonth[i - 1] : null;
            
            final superL =
                diff(parseDouble(r['super1_index']), parseDouble(prev?['super1_index'])) +
                diff(parseDouble(r['super2_index']), parseDouble(prev?['super2_index'])) +
                diff(parseDouble(r['super3_index']), parseDouble(prev?['super3_index']));

            final gazL =
                diff(parseDouble(r['gazoil1_index']), parseDouble(prev?['gazoil1_index'])) +
                diff(parseDouble(r['gazoil2_index']), parseDouble(prev?['gazoil2_index'])) +
                diff(parseDouble(r['gazoil3_index']), parseDouble(prev?['gazoil3_index']));
 
            //final vente = (superL * prixSuper) + (gazL * prixGazoil);
             
            final vente = round2(((superL * prixSuper) + (gazL * prixGazoil)).toDouble());

            //final dep = parseDouble(r['depenses']);

            final dep = _sumMontants(r['depenses']);

            final vers = parseDouble(r['versement']);
            chartData.add({
              'label': formatDate(parseDate(r['date']), 'dd/MM', locale: 'fr'),
              'venteFcfa': vente,
              'ecartBanque': vente - dep - vers,
            });


          }
            
                
          // ======== ListView complet ========
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                // Filtres mois/jour
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButton<String>(
                          value: selectedMonth,
                          isExpanded: true,
                          hint: const Text('Sélectionner le mois'),
                          items: months.map((m) => DropdownMenuItem(value: m, child: Text(monthLabel(m)))).toList(),
                          onChanged: (v) => setState(() { selectedMonth = v; selectedDay = null; }),
                        ),
                      ),
                    ),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedDay,
                        isExpanded: true,
                        hint: const Text('Sélectionner le jour'),
                        items: days.map((d) => DropdownMenuItem(value: d, child: Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(d))))).toList(),
                        onChanged: (v) => setState(() { selectedDay = v; }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cartes indicateurs
                Card(
                  child: ListTile(
                    title: const Text('Vente totale'),
                    trailing: Text('${totalDesVentes.toStringAsFixed(0)} FCFA'),
                    onTap: () {
                      // Affiche détail ventes du jour
                      double superTotal = 0, super1 = 0, super2 = 0, super3 = 0, CAgazoilTotal = 0, CAsuperTotal = 0;
                      double gazTotal = 0, gaz1 = 0, gaz2 = 0, gaz3 = 0;
                      for (var r in filteredDay) {
                        Map<String, dynamic>? prev;
                        final rDateStr = DateFormat('yyyy-MM-dd').format(parseDate(r['date']));
                        for (int j = filteredMonth.indexOf(r) - 1; j >= 0; j--) {
                          final prevDateStr = DateFormat('yyyy-MM-dd').format(parseDate(filteredMonth[j]['date']));
                          if (prevDateStr != rDateStr) { prev = filteredMonth[j]; break; }
                        }
                        //final photos = r['photos'] as Map<String, dynamic>? ?? {};

                        final photosMap = { for (var p in r['photos']) p['key'] : p['path'] };
   
                        super1 = round2(diff(r['super1_index'], prev?['super1_index'] ?? 0));
                        super2 = round2(diff(r['super2_index'], prev?['super2_index'] ?? 0));
                        super3 = round2(diff(r['super3_index'], prev?['super3_index'] ?? 0));
                        superTotal += round2(super1 + super2 + super3);

                        CAsuperTotal = round2(superTotal * prixSuper);

                        gaz1 = round2(diff(r['gazoil1_index'], prev?['gazoil1_index'] ?? 0));
                        gaz2 = round2(diff(r['gazoil2_index'], prev?['gazoil2_index'] ?? 0));
                        gaz3 = round2(diff(r['gazoil3_index'], prev?['gazoil3_index'] ?? 0));
                        gazTotal += round2(gaz1 + gaz2 + gaz3);

                        CAgazoilTotal = round2(gazTotal * prixGazoil);
 

                        indexWithPhoto(
                          label: "Super 1",
                          value: r['super1_index'],
                          photoUrl: photosMap['super1'],
                        );



                      }

                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Détail des ventes'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Super1 : $super1 L'),
                              Text('Super2 : $super2 L'),
                              Text('Super3 : $super3 L'),
                              Text('Super total : $superTotal L → $CAsuperTotal FCFA'),
                              Text('Gazoil1 : $gaz1 L'),
                              Text('Gazoil2 : $gaz2 L'),
                              Text('Gazoil3 : $gaz3 L'),
                              Text('Gazoil total : $gazTotal L → $CAgazoilTotal FCFA'),

                              Text('Total_autres_ventes : ${totalAutresVentes.toStringAsFixed(0)} FCFA'),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Dépense totale'),
                    trailing: Text('${totalAutresVentes.toStringAsFixed(0)} FCFA'),
                  ),
                ),
                Card(
                  color: alert ? Colors.red[100] : Colors.green[100],
                  child: ListTile(
                    title: const Text('Versement banque'),
                    trailing: Text('${versement.toStringAsFixed(0)} FCFA'),
                    subtitle: alert ? const Text('⚠️ Versement insuffisant') : const Text('Versement conforme'),
                  ),
                ),
                

                const SizedBox(height: 20),
                const Text('Évolution cumulée des ventes', style: TextStyle(fontWeight: FontWeight.bold)),
                buildDailyChart(chartData),

                // Détails journaliers
                ...filteredDay.map((r) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rapport du ${formatDate(parseDate(r['date']), 'dd/MM/yyyy', locale: 'fr')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(),
                          Text('Super1 index : ${r['super1_index']} L'),
                          Text('Super2 index : ${r['super2_index']} L'),
                          Text('Super3 index : ${r['super3_index']} L'),
                          Text('Gazoil1 index : ${r['gazoil1_index']} L'),
                          Text('Gazoil2 index : ${r['gazoil2_index']} L'),
                          Text('Gazoil3 index : ${r['gazoil3_index']} L'),
                          const SizedBox(height: 12),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Autres ventes
                              if ((r['autres_ventes'] as List).isNotEmpty) ...[
                                const Text('Autres ventes du jour :', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...List<Widget>.from((r['autres_ventes'] as List).map((v) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Text("${v['nom']} : ${v['montant']} FCFA"),
                                    ))),
                                const SizedBox(height: 8),
                              ],

                              // Dépenses
                              if ((r['depenses'] as List).isNotEmpty) ...[
                                const Text('Dépenses :', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...List<Widget>.from((r['depenses'] as List).map((v) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Text("${v['nom']} : ${v['montant']} FCFA"),
                                    ))),
                                const SizedBox(height: 8),
                              ],

                              // Commandes
                              if ((r['commandes'] as List).isNotEmpty) ...[
                                const Text('Commandes :', style: TextStyle(fontWeight: FontWeight.bold)),
                                ...List<Widget>.from((r['commandes'] as List).map((v) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Text("${v['produit']} - Quantité : ${v['quantite']} (Livraison : ${v['livraison']})"),
                                    ))),
                                const SizedBox(height: 8),
                              ],

                              //final photos = r['photos'] as Map<String, dynamic>;

                              // Photos
                              if ((r['photos'].isNotEmpty)) ...[
                                const Text(
                                  'Photos justificatives :',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: r['photos'].length,
                                    itemBuilder: (context, index) {
                                      //final imageUrl = r['photos'][index];
                                      //final imageUrl = r['photos'].values.elementAt(index);
                                      //final imageUrl = r['photos'][index]['url'];
                                      final imageUrl = '${ApiService.baseUrl}/storage/${r['photos'][index]['path']}';

                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: GestureDetector(
                                          onTap: () {
                                            // zoom plein écran
                                            showDialog(
                                              context: context,
                                              builder: (_) => Dialog(
                                                child: InteractiveViewer(
                                                  child: Image.network(imageUrl),
                                                ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              imageUrl,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (c, w, p) =>
                                                  p == null ? w : const CircularProgressIndicator(),
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Stocks et Versement
                              Text('Stocks : ${r['stocks'] ?? 0}'),
                              Text('Versement en banque : ${r['versement'] ?? 0} FCFA'),
                            ],
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => showInteractiveEditDialog(r),
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                label: const Text('Modifier', style: TextStyle(color: Colors.blue)),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => showDeleteDialog(r['id']),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}



 /*2ème Version
 import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:station_mobile/screens/login_screen.dart';
import '../../services/api.dart';
import '../utils/date_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final storage = const FlutterSecureStorage();

  static const double prixSuper = 840;
  static const double prixGazoil = 828;

  Future<List<Map<String, dynamic>>>? futureRapports;
  List<Map<String, dynamic>> filteredDayForPDF = [];

  String? selectedMonth;
  String? selectedDay;

  @override
  void initState() {
    super.initState();
    futureRapports = ApiService.getRapports();
  }

  // ==================== UTILITAIRES ====================
  DateTime parseDate(dynamic date) {
    if (date == null) throw Exception("Date invalide : null");
    if (date is DateTime) return date;
    if (date is int || date is double) {
      final epoch = DateTime(1899, 12, 30);
      return epoch.add(Duration(days: date.toInt()));
    }
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (_) {
        try {
          return DateFormat('d/M/yyyy').parse(date);
        } catch (_) {
          try {
            return DateFormat('dd/MM/yyyy').parse(date);
          } catch (e) {
            throw FormatException("Date invalide : $date");
          }
        }
      }
    }
    throw Exception("Format de date inconnu : $date");
  }

  double parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  double diff(dynamic a, dynamic b) {
    final da = parseDouble(a);
    final db = parseDouble(b);
    return da < db ? 0.0 : da - db;
  }

  double round2(double value) => double.parse(value.toStringAsFixed(2));

  List<dynamic> _decodeList(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      try {
        return jsonDecode(value) as List<dynamic>;
      } catch (_) {
        return [];
      }
    }
    if (value is List) return value;
    return [];
  }

  double _sumMontants(dynamic value) {
    final list = _decodeList(value);
    return list.fold<double>(
      0.0,
      (sum, e) => sum + parseDouble(e['montant']),
    );
  }

  Map<String, dynamic> _decodeMap(dynamic value) {
    if (value == null) return {};
    if (value is String) {
      try {
        return jsonDecode(value) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    }
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  String monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);
  String monthLabel(String key) => formatDate(DateTime.parse('$key-01'), 'MMMM yyyy', locale: 'fr');

  // ==================== Graphique ====================
  Widget buildDailyChart(List<Map<String, dynamic>> chartData) {
    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  int idx = value.toInt();
                  if (idx < 0 || idx >= chartData.length) return const SizedBox.shrink();
                  return Text(chartData[idx]['label'], style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), parseDouble(e.value['venteFcfa']))).toList(),
              isCurved: true,
              barWidth: 3,
              dotData: FlDotData(show: true),
              color: Colors.indigo,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [Colors.indigo.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBorder: BorderSide(color: Colors.indigo),
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipColor: (LineBarSpot _) => Colors.indigo.shade700,
              getTooltipItems: (spots) => spots.map((spot) {
                final idx = spot.spotIndex;
                final vente = parseDouble(chartData[idx]['venteFcfa']);
                final ecart = parseDouble(chartData[idx]['ecartBanque']);
                return LineTooltipItem(
                  'Vente: ${vente.toStringAsFixed(0)} FCFA\nÉcart: ${ecart.toStringAsFixed(0)} FCFA',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== Export PDF ====================
  Future<void> exportPDFComplet(List<Map<String, dynamic>> filteredDay) async {
    final pdf = pw.Document();
    for (var r in filteredDay) {
      final dateStr = formatDate(parseDate(r['date']), 'dd/MM/yyyy', locale: 'fr');

      final superTotal = diff(r['super1_index'], 0) + diff(r['super2_index'], 0) + diff(r['super3_index'], 0);
      final gazTotal = diff(r['gazoil1_index'], 0) + diff(r['gazoil2_index'], 0) + diff(r['gazoil3_index'], 0);

      final venteSuper = superTotal * prixSuper;
      final venteGazoil = gazTotal * prixGazoil;
      final autresVentes = _sumMontants(r['autres_ventes']);
      final totalVentes = venteSuper + venteGazoil + autresVentes;
      final depenses = _sumMontants(r['depenses']);
      final versement = parseDouble(r['versement']);
      final theorique = totalVentes - depenses;

      List<pw.Widget> photoWidgets = [];
      final photos = _decodeList(r['photos']);
      for (final p in photos) {
        final path = p['path'];
        if (path != null && path.toString().isNotEmpty) {
          try {
            final image = await networkImage('${ApiService.baseUrl}/storage/$path');
            photoWidgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(p['key'].toString().toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 4),
                  pw.Image(image, width: 120, height: 90, fit: pw.BoxFit.cover),
                  pw.SizedBox(height: 8),
                ],
              ),
            );
          } catch (_) {}
        }
      }

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Rapport du $dateStr', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Ventes carburant :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'Super1 index : ${r['super1_index']} L'),
              pw.Bullet(text: 'Super2 index : ${r['super2_index']} L'),
              pw.Bullet(text: 'Super3 index : ${r['super3_index']} L'),
              pw.Bullet(text: 'Vente total super : ${venteSuper.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'Gazoil1 index : ${r['gazoil1_index']} L'),
              pw.Bullet(text: 'Gazoil2 index : ${r['gazoil2_index']} L'),
              pw.Bullet(text: 'Gazoil3 index : ${r['gazoil3_index']} L'),
              pw.Bullet(text: 'Vente total gazoil : ${venteGazoil.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if (photoWidgets.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text('Photos justificatives :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Wrap(spacing: 10, runSpacing: 10, children: photoWidgets),
                pw.SizedBox(height: 12),
              ],
              if ((r['autres_ventes'] as List).isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Autres ventes :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ...List<pw.Widget>.from((r['autres_ventes'] as List).map((v) => pw.Bullet(text: "${v['nom']} : ${v['montant']} FCFA"))),
                    pw.SizedBox(height: 8),
                  ],
                ),
              pw.Text('Total des ventes : ${totalVentes.toStringAsFixed(0)} FCFA', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              if ((r['depenses'] as List).isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Dépenses :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ...List<pw.Widget>.from((r['depenses'] as List).map((v) => pw.Bullet(text: "${v['nom']} : ${v['montant']} FCFA"))),
                    pw.SizedBox(height: 8),
                  ],
                ),
              if ((r['commandes'] as List).isNotEmpty)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Commandes :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ...List<pw.Widget>.from((r['commandes'] as List).map((v) => pw.Bullet(text: "${v['produit']} - Quantité : ${v['quantite']} (Livraison : ${v['livraison']})"))),
                    pw.SizedBox(height: 8),
                  ],
                ),
              pw.Text('Stocks : ${r['stocks'] ?? 0}'),
              pw.Text('Versement en banque : ${r['versement'] ?? 0} FCFA'),
              pw.Text('Théorique banque : ${theorique.toStringAsFixed(0)} FCFA',
                  style: pw.TextStyle(
                    color: theorique > versement ? PdfColor.fromInt(0xFFB00020) : PdfColor.fromInt(0xFF00A000),
                  )),
            ],
          ),
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter PDF',
            onPressed: () async {
              if (filteredDayForPDF.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Aucun rapport sélectionné pour le PDF")),
                );
                return;
              }
              await exportPDFComplet(filteredDayForPDF);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await storage.deleteAll();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: futureRapports,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final rapports = snapshot.data!;
          for (var r in rapports) {
            r['depenses'] = _decodeList(r['depenses']);
            r['commandes'] = _decodeList(r['commandes']);
            r['autres_ventes'] = _decodeList(r['autres_ventes']);
            r['photos'] = _decodeList(r['photos']);
          }

          final months = rapports.map((r) => monthKey(parseDate(r['date']))).toSet().toList()..sort();
          selectedMonth ??= months.isNotEmpty ? months.last : null;

          final filteredMonth = rapports.where((r) => selectedMonth != null && monthKey(parseDate(r['date'])) == selectedMonth).toList();
          final days = filteredMonth.map((r) => DateFormat('yyyy-MM-dd').format(parseDate(r['date']))).toSet().toList()..sort();

          filteredMonth.sort((a, b) => parseDate(a['date']).compareTo(parseDate(b['date'])));
          selectedDay = (selectedDay != null && days.contains(selectedDay)) ? selectedDay : (days.isNotEmpty ? days.last : null);
          final filteredDay = filteredMonth.where((r) => selectedDay != null && DateFormat('yyyy-MM-dd').format(parseDate(r['date'])) == selectedDay).toList();
          filteredDay.sort((a, b) => parseDate(a['date']).compareTo(parseDate(b['date'])));

          filteredDayForPDF = filteredDay;

          // Calcul indicateurs
          double ventesFcfa = 0;
          for (var r in filteredDay) {
            Map<String, dynamic>? prev;
            final rDateStr = DateFormat('yyyy-MM-dd').format(parseDate(r['date']));
            for (int j = filteredMonth.indexOf(r) - 1; j >= 0; j--) {
              final prevDateStr = DateFormat('yyyy-MM-dd').format(parseDate(filteredMonth[j]['date']));
              if (prevDateStr != rDateStr) {
                prev = filteredMonth[j];
                break;
              }
            }
            final superL = diff(parseDouble(r['super1_index']), parseDouble(prev?['super1_index'])) +
                diff(parseDouble(r['super2_index']), parseDouble(prev?['super2_index'])) +
                diff(parseDouble(r['super3_index']), parseDouble(prev?['super3_index']));
            final gazL = diff(parseDouble(r['gazoil1_index']), parseDouble(prev?['gazoil1_index'])) +
                diff(parseDouble(r['gazoil2_index']), parseDouble(prev?['gazoil2_index'])) +
                diff(parseDouble(r['gazoil3_index']), parseDouble(prev?['gazoil3_index']));
            ventesFcfa += (superL * prixSuper) + (gazL * prixGazoil);
          }

          final depenses = filteredDay.fold<double>(0, (s, r) => s + _sumMontants(r['depenses']));
          final totalAutresVentes = filteredDay.fold<double>(0, (s, r) => s + _sumMontants(r['autres_ventes']));
          final versement = filteredDay.fold<double>(0, (s, r) => s + parseDouble(r['versement']));
          final totalDesVentes = ventesFcfa + totalAutresVentes;
          final theorique = totalDesVentes - depenses;
          final alert = versement < theorique;

          // Graphique
          List<Map<String, dynamic>> chartData = [];
          for (int i = 1; i < filteredMonth.length; i++) {
            final r = filteredMonth[i];
            final prev = i > 0 ? filteredMonth[i - 1] : null;
            final superL = diff(parseDouble(r['super1_index']), parseDouble(prev?['super1_index'])) +
                diff(parseDouble(r['super2_index']), parseDouble(prev?['super2_index'])) +
                diff(parseDouble(r['super3_index']), parseDouble(prev?['super3_index']));
            final gazL = diff(parseDouble(r['gazoil1_index']), parseDouble(prev?['gazoil1_index'])) +
                diff(parseDouble(r['gazoil2_index']), parseDouble(prev?['gazoil2_index'])) +
                diff(parseDouble(r['gazoil3_index']), parseDouble(prev?['gazoil3_index']));
            final vente = round2((superL * prixSuper + gazL * prixGazoil).toDouble());
            final dep = _sumMontants(r['depenses']);
            final vers = parseDouble(r['versement']);
            chartData.add({
              'label': formatDate(parseDate(r['date']), 'dd/MM', locale: 'fr'),
              'venteFcfa': vente,
              'ecartBanque': vente - dep - vers,
            });
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                // Filtres mois/jour
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DropdownButton<String>(
                          value: selectedMonth,
                          isExpanded: true,
                          hint: const Text('Sélectionner le mois'),
                          items: months.map((m) => DropdownMenuItem(value: m, child: Text(monthLabel(m)))).toList(),
                          onChanged: (v) => setState(() {
                            selectedMonth = v;
                            selectedDay = null;
                          }),
                        ),
                      ),
                    ),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedDay,
                        isExpanded: true,
                        hint: const Text('Sélectionner le jour'),
                        items: days.map((d) => DropdownMenuItem(value: d, child: Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(d))))).toList(),
                        onChanged: (v) => setState(() => selectedDay = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Cartes indicateurs
                Card(
                  child: ListTile(
                    title: const Text('Vente totale'),
                    trailing: Text('${totalDesVentes.toStringAsFixed(0)} FCFA'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Dépense totale'),
                    trailing: Text('${depenses.toStringAsFixed(0)} FCFA'),
                  ),
                ),
                Card(
                  color: alert ? Colors.red[100] : Colors.green[100],
                  child: ListTile(
                    title: const Text('Versement banque'),
                    trailing: Text('${versement.toStringAsFixed(0)} FCFA'),
                    subtitle: alert ? const Text('⚠️ Versement insuffisant') : const Text('Versement conforme'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Évolution cumulée des ventes', style: TextStyle(fontWeight: FontWeight.bold)),
                buildDailyChart(chartData),
              ],
            ),
          );
        },
      ),
    );
  }
}
*/