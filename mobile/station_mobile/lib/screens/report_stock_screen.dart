import 'package:flutter/material.dart';

class ReportStockScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const ReportStockScreen({super.key, this.data});

  @override
  State<ReportStockScreen> createState() => _ReportStockScreenState();
}

class _ReportStockScreenState extends State<ReportStockScreen> {
  final _formKey = GlobalKey<FormState>();

  // Stocks
  final sup9000Ctrl = TextEditingController();
  final sup10000Ctrl = TextEditingController();
  final sup14000Ctrl = TextEditingController();
  final gaz10000Ctrl = TextEditingController();
  final gaz6000Ctrl = TextEditingController();

  // Commandes
  List<Map<String, dynamic>> commandes = [];

  late Map<String, dynamic> previousData;

  @override
  void initState() {
    super.initState();
    previousData = widget.data ?? {};
  }

  // ================= COMMANDES =================
  void addCommande() {
    setState(() {
      commandes.add({
        "produit": "Super",
        "quantite": TextEditingController(),
        "date": TextEditingController(),
      });
    });
  }

  Widget buildCommande(int i) {
    return Column(
      children: [
        Row(
          children: [
            DropdownButton<String>(
              value: commandes[i]["produit"],
              items: const [
                DropdownMenuItem(value: "Super", child: Text("Super")),
                DropdownMenuItem(value: "Gazoil", child: Text("Gazoil")),
              ],
              onChanged: (v) {
                setState(() => commandes[i]["produit"] = v);
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: commandes[i]["quantite"],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantité"),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Obligatoire";
                  if (int.tryParse(v) == null) return "Nombre invalide";
                  return null;
                },
              ),
            ),
          ],
        ),
        TextFormField(
          controller: commandes[i]["date"],
          readOnly: true,
          decoration: const InputDecoration(
            labelText: "Date de livraison",
            suffixIcon: Icon(Icons.calendar_today),
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              commandes[i]["date"].text =
                  "${picked.day}/${picked.month}/${picked.year}";
            }
          },
          validator: (v) =>
              v == null || v.isEmpty ? "Date obligatoire" : null,
        ),
        const Divider(),
      ],
    );
  }

  // ================= VALIDATION =================
  void goToNext() {
    if (_formKey.currentState!.validate()) {
      final stockData = {
        "stock_sup_9000": int.parse(sup9000Ctrl.text),
        "stock_sup_10000": int.parse(sup10000Ctrl.text),
        "stock_sup_14000": int.parse(sup14000Ctrl.text),
        "stock_gaz_10000": int.parse(gaz10000Ctrl.text),
        "stock_gaz_6000": int.parse(gaz6000Ctrl.text),
      };

      final commandesFormatted = commandes.map((c) {
        return {
          "produit": c["produit"],
          "quantite": int.tryParse(c["quantite"].text) ?? 0,
          "livraison": c["date"].text,
        };
      }).toList();

      final fullData = {
        ...previousData,
        ...stockData,

        // ✅ écrase proprement
        "commandes": commandesFormatted,
      };

      // ✅ Sécurité backend
      if (fullData["commandes"] is! List) {
        fullData["commandes"] = [];
      }
      if (fullData["depenses"] is! List) {
        fullData["depenses"] = [];
      }
      if (fullData["autres_ventes"] is! List) {
        fullData["autres_ventes"] = [];
      }

      print("STOCK DATA => $fullData");

      Navigator.pushNamed(
        context,
        "/report_payment",
        arguments: fullData,
      );
    }
  }

  Widget buildField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (v == null || v.isEmpty) return "Champ obligatoire";
        if (int.tryParse(v) == null) return "Nombre invalide";
        if (int.parse(v) < 0) return "Valeur invalide";
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saisie des stocks")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("STOCK SUPER",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              buildField("Sup 9000 L", sup9000Ctrl),
              buildField("Sup 10000 L", sup10000Ctrl),
              buildField("Sup 14000 L", sup14000Ctrl),

              const SizedBox(height: 20),

              const Text("STOCK GAZOIL",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              buildField("Gaz 10000 L", gaz10000Ctrl),
              buildField("Gaz 6000 L", gaz6000Ctrl),

              const SizedBox(height: 30),

              const Text("COMMANDES",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: commandes.length,
                itemBuilder: (_, i) => buildCommande(i),
              ),

              ElevatedButton.icon(
                onPressed: addCommande,
                icon: const Icon(Icons.add),
                label: const Text("Ajouter une commande"),
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
