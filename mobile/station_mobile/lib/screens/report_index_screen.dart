import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//import 'login_screen.dart'; // ton écran de login
import 'package:station_mobile/screens/login_screen.dart';



class ReportIndexScreen extends StatefulWidget {
  const ReportIndexScreen({super.key});

  @override
  State<ReportIndexScreen> createState() => _ReportIndexScreenState();
}

class _ReportIndexScreenState extends State<ReportIndexScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final storage = const FlutterSecureStorage();

  // Date
  final dateCtrl = TextEditingController();

  // Index
  final super1Ctrl = TextEditingController();
  final super2Ctrl = TextEditingController();
  final super3Ctrl = TextEditingController();
  final gaz1Ctrl = TextEditingController();
  final gaz2Ctrl = TextEditingController();
  final gaz3Ctrl = TextEditingController();

  // Photos
  File? photoSuper1;
  File? photoSuper2;
  File? photoSuper3;
  File? photoGaz1;
  File? photoGaz2;
  File? photoGaz3;

  Future<void> takePhoto(String key) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        switch (key) {
          case "super1":
            photoSuper1 = File(pickedFile.path);
            break;
          case "super2":
            photoSuper2 = File(pickedFile.path);
            break;
          case "super3":
            photoSuper3 = File(pickedFile.path);
            break;
          case "gaz1":
            photoGaz1 = File(pickedFile.path);
            break;
          case "gaz2":
            photoGaz2 = File(pickedFile.path);
            break;
          case "gaz3":
            photoGaz3 = File(pickedFile.path);
            break;
        }
      });
    }
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      dateCtrl.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  void goToNext() {
    if (_formKey.currentState!.validate()) {
      final missingPhotos = <String>[];
      if (photoSuper1 == null) missingPhotos.add("Super 1");
      if (photoSuper2 == null) missingPhotos.add("Super 2");
      if (photoSuper3 == null) missingPhotos.add("Super 3");
      if (photoGaz1 == null) missingPhotos.add("Gazoil 1");
      if (photoGaz2 == null) missingPhotos.add("Gazoil 2");
      if (photoGaz3 == null) missingPhotos.add("Gazoil 3");

      if (missingPhotos.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Veuillez prendre une photo pour : ${missingPhotos.join(', ')}"),
          ),
        );
        return;
      }

      final data = {
        "date": dateCtrl.text,
        "super1": double.parse(super1Ctrl.text),
        "super2": double.parse(super2Ctrl.text),
        "super3": double.parse(super3Ctrl.text),
        "gaz1": double.parse(gaz1Ctrl.text),
        "gaz2": double.parse(gaz2Ctrl.text),
        "gaz3": double.parse(gaz3Ctrl.text),

        // ✅ INITIALISATION CRITIQUE POUR LES ÉCRANS SUIVANTS
        "autres_ventes": <Map<String, dynamic>>[],
        "depenses": <Map<String, dynamic>>[],
        "commandes": <Map<String, dynamic>>[],

        "photos": {
          "super1": photoSuper1,
          "super2": photoSuper2,
          "super3": photoSuper3,
          "gaz1": photoGaz1,
          "gaz2": photoGaz2,
          "gaz3": photoGaz3,
        }
      };

      print("INDEX DATA => $data");

      Navigator.pushNamed(
        context,
        "/report_other_sales",
        arguments: data,
      );
    }
  }

  Widget buildField(
      String label, TextEditingController ctrl, String photoKey, File? photo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Champ obligatoire';
            if (double.tryParse(v) == null) return 'Doit être un nombre';
            if (double.parse(v) < 0) return 'Valeur invalide';
            return null;
          },
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => takePhoto(photoKey),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Photo"),
            ),
            const SizedBox(width: 10),
            photo != null
                ? Image.file(photo, width: 50, height: 50, fit: BoxFit.cover)
                : const Text("Aucune photo"),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: 
      //AppBar(title: const Text("Saisie des index")),
      //    return Scaffold(
      appBar: AppBar(
        title: const Text("Saisie des index"),
        actions: [
          // ✅ Bouton de déconnexion
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
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: dateCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Relevé du",
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: pickDate,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Date obligatoire' : null,
              ),
              const SizedBox(height: 20),

              const Text("SUPER",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              buildField("Super 1", super1Ctrl, "super1", photoSuper1),
              buildField("Super 2", super2Ctrl, "super2", photoSuper2),
              buildField("Super 3", super3Ctrl, "super3", photoSuper3),

              const SizedBox(height: 20),

              const Text("GAZOIL",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              buildField("Gazoil 1", gaz1Ctrl, "gaz1", photoGaz1),
              buildField("Gazoil 2", gaz2Ctrl, "gaz2", photoGaz2),
              buildField("Gazoil 3", gaz3Ctrl, "gaz3", photoGaz3),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: goToNext,
                child: const Text("Suivant"),
              )
            ],
          ),
        ),
      ),
      
    );
  }
}
