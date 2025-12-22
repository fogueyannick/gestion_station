// lib/services/pdf_service.dart
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateDailyReportPdf(Map<String, dynamic> report) async {
  final pdf = pw.Document();

  List depenses = report['depenses'] ?? [];
  List ventes = report['autres_ventes'] ?? [];
  List commandes = report['commandes'] ?? [];

  double totalDepenses = depenses.fold<double>(0, (sum, e) => sum + (e['montant'] ?? 0));
  double totalVentes = ventes.fold<double>(0, (sum, e) => sum + (e['montant'] ?? 0));
  double totalCommandes = commandes.fold<double>(0, (sum, e) => sum + (e['montant'] ?? 0));

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Rapport du ${report['date']}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),

          // Carburants
          pw.Text('Super1 : ${report['super1_index']} L'),
          pw.Text('Super2 : ${report['super2_index']} L'),
          pw.Text('Super3 : ${report['super3_index']} L'),
          pw.Text('Gazoil1 : ${report['gazoil1_index']} L'),
          pw.Text('Gazoil2 : ${report['gazoil2_index']} L'),
          pw.Text('Gazoil3 : ${report['gazoil3_index']} L'),
          pw.SizedBox(height: 8),

          // Autres ventes
          pw.Text('Autres ventes : ${totalVentes.toStringAsFixed(0)} FCFA'),
          if (ventes.isNotEmpty)
            ...ventes.map((v) => pw.Text('${v['libelle'] ?? v['type'] ?? '-'} : ${v['montant'] ?? 0} FCFA')),

          pw.SizedBox(height: 8),

          // Dépenses
          pw.Text('Dépenses : ${totalDepenses.toStringAsFixed(0)} FCFA'),
          if (depenses.isNotEmpty)
            ...depenses.map((d) => pw.Text('${d['libelle'] ?? d['type'] ?? '-'} : ${d['montant'] ?? 0} FCFA')),

          pw.SizedBox(height: 8),

          // Commandes
          pw.Text('Commandes : ${totalCommandes.toStringAsFixed(0)} FCFA'),
          if (commandes.isNotEmpty)
            ...commandes.map((c) => pw.Text('${c['libelle'] ?? c['type'] ?? '-'} : ${c['montant'] ?? 0} FCFA')),

          pw.SizedBox(height: 8),

          // Versement
          pw.Text('Versement en banque : ${report['versement'] ?? 0} FCFA'),

          // Stocks
          pw.SizedBox(height: 8),
          pw.Text(
            'Stocks : Sup9000:${report['stock_sup_9000']} | Sup10000:${report['stock_sup_10000']} | Sup14000:${report['stock_sup_14000']} | Gaz10000:${report['stock_gaz_10000']} | Gaz6000:${report['stock_gaz_6000']}',
            style: pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    ),
  );

  await Printing.layoutPdf(onLayout: (_) => pdf.save());
}

}
