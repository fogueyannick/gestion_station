import 'package:flutter/material.dart';
import '../services/log_service.dart';

class ReportOtherSalesScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const ReportOtherSalesScreen({super.key, this.data});

  @override
  State<ReportOtherSalesScreen> createState() =>
      _ReportOtherSalesScreenState();
}

class _ReportOtherSalesScreenState extends State<ReportOtherSalesScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> previousData;

  List<Map<String, dynamic>> autresVentes = [];

  @override
  void initState() {
    super.initState();
    previousData = widget.data ?? {};
  }

  void addVente() {
    setState(() {
      autresVentes.add({
        "nom": TextEditingController(),
        "montant": TextEditingController(),
      });
    });
  }

  void removeVente(int index) {
    setState(() {
      autresVentes.removeAt(index);
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
                    const InputDecoration(labelText: "Nom de la vente"),
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
              onPressed: () => removeVente(index),
            ),
          ],
        ),
      ),
    );
  }

  void goToNext() {
    if (_formKey.currentState!.validate()) {
      final ventesFormatted = autresVentes.map((v) {
        return {
          "nom": v["nom"].text,
          "montant": double.tryParse(v["montant"].text) ?? 0.0,
        };
      }).toList();

      final fullData = {
        ...previousData,

        // ✅ ÉCRASE PROPREMENT (array garanti)
        "autres_ventes": ventesFormatted,
      };

      // ✅ Sécurité backend
      if (fullData["autres_ventes"] is! List) {
        fullData["autres_ventes"] = [];
      }
      if (fullData["depenses"] is! List) {
        fullData["depenses"] = [];
      }
      if (fullData["commandes"] is! List) {
        fullData["commandes"] = [];
      }

      LogService.debug("OTHER SALES DATA => $fullData");

      Navigator.pushNamed(
        context,
        "/report_depense",
        arguments: fullData,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Autres ventes")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (autresVentes.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Liste des autres ventes",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: autresVentes.length,
                itemBuilder: (_, i) => buildItem(autresVentes[i], i),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: addVente,
                icon: const Icon(Icons.add),
                label: const Text("Ajouter une vente"),
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
