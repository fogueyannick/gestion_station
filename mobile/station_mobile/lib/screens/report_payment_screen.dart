import 'package:flutter/material.dart';
import '../services/log_service.dart';

class ReportPaymentScreen extends StatefulWidget {
  const ReportPaymentScreen({super.key});

  @override
  State<ReportPaymentScreen> createState() => _ReportPaymentScreenState();
}

class _ReportPaymentScreenState extends State<ReportPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final depotCtrl = TextEditingController();
  late Map<String, dynamic> previousData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      previousData = args;
      if (previousData["depot_banque"] != null) {
        depotCtrl.text = previousData["depot_banque"].toString();
      }
    } else {
      previousData = {};
    }
  }

  void goToNext() {
    if (_formKey.currentState!.validate()) {
      // 🔹 Copie superficielle de toutes les données existantes
      final Map<String, dynamic> fullData = {
        ...previousData,
        "depot_banque": double.tryParse(depotCtrl.text) ?? 0.0,
      };

      // 🔹 Debug : voir exactement ce qui sera transmis
      LogService.debug("PAYMENT DATA => $fullData");
      LogService.debug("PAYMENT DATA PREVIOUS => $previousData");
      
      // 🔹 Navigation vers le résumé
      Navigator.pushNamed(
        context,
        "/report_summary",
        arguments: fullData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paiement")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: depotCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Dépôt banque"),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Champ obligatoire";
                  if (double.tryParse(v) == null) return "Montant invalide";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: goToNext,
                child: const Text("Terminer"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
