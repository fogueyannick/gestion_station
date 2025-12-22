import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool loading = false;

  final FlutterSecureStorage storage = FlutterSecureStorage();

  void doLogin() async {
    
    setState(() => loading = true);

    final result = await ApiService.login(usernameCtrl.text, passwordCtrl.text);


    print("LOGIN RESULT = $result");

    setState(() => loading = false);

    if (result != null) {
      final token = result["access_token"];
      final role = result["role"];

      // Sauvegarde du token et du rôle
      await storage.write(key: "token", value: token);
      await storage.write(key: "role", value: role);

      // Redirection selon rôle
      if (role == "gerant") {
        Navigator.pushReplacementNamed(context, "/dashboard");
      } else if (role == "pompiste") {
          Navigator.pushReplacementNamed(
              context,
              "/report_index",
              arguments: {"token": token},);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nom d’utilisateur ou mot de passe incorrect")),
      );
    }
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(labelText: "Nom d’utilisateur"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordCtrl,
              decoration: const InputDecoration(labelText: "Mot de passe"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : doLogin,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Se connecter"),
            )
          ],
        ),
      ),
    );
  }
}


