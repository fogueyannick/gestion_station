class ApiConfig {
  // Pour émulateur Android: http://10.0.2.2:8000/api
  // Pour émulateur iOS: http://localhost:8000/api
  // Pour appareil physique: http://192.168.x.x:8000/api (votre IP locale)
  // Pour production: https://votre-domaine.com/api
  
  static const String baseUrl = "http://10.0.2.2:8000/api";
  
  // Alternative: détection automatique de la plateforme
  // static String get baseUrl {
  //   if (Platform.isIOS) {
  //     return "http://localhost:8000/api";
  //   }
  //   return "http://10.0.2.2:8000/api";
  // }
}
