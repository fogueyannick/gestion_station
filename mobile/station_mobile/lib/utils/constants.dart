/// Constantes utilisées dans l'application
class AppConstants {
  // Informations de l'application
  static const String appName = "Station Service";
  static const String appVersion = "1.0.0";

  // Prix des produits (FCFA)
  static const double prixSuper = 840.0;
  static const double prixGazoil = 828.0;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration splashDuration = Duration(seconds: 2);

  // IDs des stations (à configurer selon besoin)
  static const int defaultStationId = 1;

  // Clés de stockage sécurisé
  static const String storageKeyToken = "token";
  static const String storageKeyRole = "role";
  static const String storageKeyUserId = "user_id";
  static const String storageKeyUserName = "user_name";

  // Rôles
  static const String roleGerant = "gerant";
  static const String rolePompiste = "pompiste";

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPhotoQuality = 70;

  // Messages
  static const String msgLoginSuccess = "Connexion réussie";
  static const String msgLoginError = "Nom d'utilisateur ou mot de passe incorrect";
  static const String msgNetworkError = "Erreur de connexion au serveur";
  static const String msgReportSent = "Rapport envoyé avec succès";
  static const String msgReportError = "Erreur lors de l'envoi du rapport";
}
