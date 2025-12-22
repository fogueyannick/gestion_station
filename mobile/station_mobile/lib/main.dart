import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/report_index_screen.dart';
import 'screens/report_stock_screen.dart';
import 'screens/report_payment_screen.dart';
import 'screens/report_other_sales_screen.dart';
import 'screens/report_depense.dart';
import 'screens/report_summary_screen.dart';

// Dashboard
import 'dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Liste des locales que ton app va utiliser
  const locales = ['fr', 'en']; // Ajouter d'autres si nécessaire

  // Initialise toutes les locales
  for (final locale in locales) {
    await initializeDateFormatting(locale, null);
  }

  runApp(const StationApp());
}

class StationApp extends StatelessWidget {
  const StationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Station Service",
      home: const SplashScreen(),
      routes: {
        "/login": (context) => const LoginScreen(),
        "/report_index": (context) => const ReportIndexScreen(),
        "/report_payment": (context) => const ReportPaymentScreen(),
        "/report_summary": (context) => const ReportSummaryScreen(),
        "/dashboard": (context) => const DashboardScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case "/report_other_sales":
            final data = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => ReportOtherSalesScreen(data: data),
            );
          case "/report_depense":
            final data = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (_) => ReportDepenseScreen(data: data),
            );
          case "/report_stock":
            final data = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ReportStockScreen(data: data),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text("Route inconnue"),
                ),
              ),
            );
        }
      },
    );
  }
}

/// ------------------------------------------------------------
/// SplashScreen : vérifie session (token / rôle)
/// ------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    // ⚠️ À supprimer en production (utilisé ici pour test)
    await storage.delete(key: "token");
    await storage.delete(key: "role");

    // Redirection vers login
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
