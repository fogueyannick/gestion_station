/// Exceptions personnalisées pour l'application

class AppException implements Exception {
  final String message;
  final String? details;

  AppException(this.message, [this.details]);

  @override
  String toString() => details != null ? '$message: $details' : message;
}

class NetworkException extends AppException {
  NetworkException([String? details]) 
      : super('Erreur de connexion réseau', details);
}

class AuthenticationException extends AppException {
  AuthenticationException([String? details]) 
      : super('Erreur d\'authentification', details);
}

class ValidationException extends AppException {
  ValidationException([String? details]) 
      : super('Erreur de validation', details);
}

class ServerException extends AppException {
  final int? statusCode;
  
  ServerException(String message, [this.statusCode, String? details]) 
      : super(message, details);
  
  @override
  String toString() => statusCode != null 
      ? 'Erreur serveur ($statusCode): $message' 
      : 'Erreur serveur: $message';
}

class DataException extends AppException {
  DataException([String? details]) 
      : super('Erreur de données', details);
}
