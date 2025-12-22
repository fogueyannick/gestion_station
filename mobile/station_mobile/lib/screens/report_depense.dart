import 'package:flutter/material.dart';
import '../services/log_service.dart';

class ReportDepenseScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const ReportDepenseScreen({super.key, this.data});

  @override
  State<ReportDepenseScreen> createState() => _ReportDepenseScreenState();
}

class _ReportDepenseScreenState extends State<ReportDepenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> previousData;

  List<Map<String, dynamic>> depenses = [];

  @override
  void initState() {
    super.initState();
    previousData = widget.data ?? {};
  }

  void addDepense() {
    setState(() {
      depenses.add({
        "nom": TextEditingController(),
        "montant": TextEditingController(),
      });
    });
  }

  void removeDepense(int index) {
    setState(() {
      depenses.removeAt(index);
    });
  }

  Widget buildItem(Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: item["nom"],
                decoration:
                    const InputDecoration(labelText: "Nom de la dépense"),
                validator: (v) =>
                    v == null || v.isEmpty ? "Nom obligatoire" : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: item["montant"],
                decoration:
                    const InputDecoration(labelText: "Montant (FCFA)"),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Montant obligatoire";
                  if (double.tryParse(v) == null) return "Montant invalide";
                  return null;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => removeDepense(index),
            ),
          ],
        ),
      ),
    );
  }

  void goToNext() {
    if (_formKey.currentState!.validate()) {
      final depensesFormatted = depenses.map((d) {
        return {
          "nom": d["nom"].text,
          "montant": double.tryParse(d["montant"].text) ?? 0.0,
        };
      }).toList();

      final fullData = {
        ...previousData,

        // ✅ écrase proprement
        "depenses": depensesFormatted,
      };

      // ✅ Sécurité backend
      if (fullData["depenses"] is! List) {
        fullData["depenses"] = [];
      }
      if (fullData["autres_ventes"] is! List) {
        fullData["autres_ventes"] = [];
      }
      if (fullData["commandes"] is! List) {
        fullData["commandes"] = [];
      }

      LogService.debug("DEPENSE DATA => $fullData");

      Navigator.pushNamed(
        context,
        "/report_stock",
        arguments: fullData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dépenses du mois")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (depenses.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Liste des dépenses",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: depenses.length,
                itemBuilder: (_, i) => buildItem(depenses[i], i),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: addDepense,
                icon: const Icon(Icons.add),
                label: const Text("Ajouter une dépense"),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: goToNext,
                child: const Text("Suivant"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
