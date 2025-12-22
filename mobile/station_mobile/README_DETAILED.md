# 📱 Application Mobile - Station Service

Application Flutter pour la gestion quotidienne des rapports de station-service.

## 🎯 Fonctionnalités

### Pour les Pompistes
- ✅ Saisie des index de compteurs (Super, Gazoil)
- 📸 Prise de photos des compteurs
- 💰 Enregistrement des autres ventes
- 💸 Suivi des dépenses
- 📦 Gestion des stocks
- 🏦 Dépôts bancaires
- 📋 Résumé et envoi des rapports

### Pour les Gérants
- 📊 Dashboard avec graphiques
- 📈 Analyse des ventes (journalières, mensuelles)
- 📉 Suivi des performances
- 📄 Export PDF et Excel
- 🗑️ Gestion des rapports (édition, suppression)

## 🛠️ Technologies Utilisées

- **Flutter** 3.10.3+
- **Dart** 3.10.3+
- **Packages principaux:**
  - `http` - Requêtes API
  - `flutter_secure_storage` - Stockage sécurisé des tokens
  - `fl_chart` - Graphiques
  - `pdf` & `printing` - Export PDF
  - `excel` - Export Excel
  - `image_picker` - Photos
  - `intl` - Internationalisation

## 📋 Prérequis

### 1. Installation de Flutter

#### Windows
```bash
# Télécharger Flutter SDK depuis https://flutter.dev/docs/get-started/install/windows
# Extraire dans C:\src\flutter
# Ajouter au PATH: C:\src\flutter\bin

# Vérifier l'installation
flutter doctor
```

#### macOS
```bash
# Installer avec Homebrew
brew install --cask flutter

# Ou télécharger depuis https://flutter.dev/docs/get-started/install/macos
flutter doctor
```

#### Linux
```bash
# Télécharger depuis https://flutter.dev/docs/get-started/install/linux
# Extraire et ajouter au PATH
export PATH="$PATH:`pwd`/flutter/bin"

flutter doctor
```

### 2. Configurer les dépendances

#### Android
- Android Studio 2022.3+ ou supérieur
- Android SDK 30+
- Émulateur Android ou appareil physique

#### iOS (macOS uniquement)
- Xcode 14+
- CocoaPods
- Simulateur iOS ou iPhone physique

## 🚀 Installation et Configuration

### 1. Cloner le projet
```bash
cd mobile/station_mobile
```

### 2. Installer les dépendances
```bash
flutter pub get
```

### 3. Configurer l'URL de l'API

Modifier le fichier `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Pour émulateur Android
  static const String baseUrl = "http://10.0.2.2:8000/api";
  
  // Pour émulateur iOS
  // static const String baseUrl = "http://localhost:8000/api";
  
  // Pour appareil physique (remplacer par votre IP locale)
  // static const String baseUrl = "http://192.168.1.XXX:8000/api";
  
  // Pour production
  // static const String baseUrl = "https://votre-domaine.com/api";
}
```

### 4. Trouver votre IP locale (pour appareil physique)

#### Windows
```bash
ipconfig
# Chercher "Adresse IPv4"
```

#### macOS/Linux
```bash
ifconfig
# Chercher "inet" (pas inet6)
```

## 🏃 Lancement de l'application

### Mode Debug

```bash
# Lister les appareils disponibles
flutter devices

# Lancer sur un appareil spécifique
flutter run -d <device-id>

# Lancer sur tous les appareils
flutter run
```

### Mode Release (Production)

#### Android APK
```bash
# Build APK
flutter build apk --release

# L'APK sera dans: build/app/outputs/flutter-apk/app-release.apk

# Build AAB (pour Google Play Store)
flutter build appbundle --release
```

#### iOS
```bash
# Build iOS (macOS uniquement)
flutter build ios --release

# Puis ouvrir dans Xcode pour signer et distribuer
open ios/Runner.xcworkspace
```

## 🧪 Tests

```bash
# Lancer les tests
flutter test

# Lancer avec coverage
flutter test --coverage
```

## 🔍 Analyse du Code

```bash
# Analyser le code
flutter analyze

# Formater le code
dart format lib/

# Vérifier les dépendances obsolètes
flutter pub outdated
```

## 📱 Structure du Projet

```
lib/
├── config/                 # Configuration (API, etc.)
│   └── api_config.dart
├── dashboard/             # Écrans du dashboard
│   ├── dashboard_screen.dart
│   ├── dashboard_chart.dart
│   └── ...
├── models/                # Modèles de données
│   └── daily_report.dart
├── screens/               # Écrans de l'application
│   ├── login_screen.dart
│   ├── report_*.dart
│   └── ...
├── services/              # Services (API, logs)
│   ├── api.dart
│   ├── log_service.dart
│   └── pdf_service.dart
├── theme/                 # Thème de l'application
│   └── app_theme.dart
├── utils/                 # Utilitaires
│   ├── constants.dart
│   ├── exceptions.dart
│   └── date_utils.dart
├── widgets/               # Widgets réutilisables
│   ├── buttons.dart
│   ├── inputs.dart
│   └── ...
└── main.dart             # Point d'entrée
```

## 🔧 Configuration Backend

Assurez-vous que le backend Laravel est lancé:

```bash
# Depuis le dossier backend/
php artisan serve

# L'API sera disponible sur http://localhost:8000
```

## 🐛 Dépannage

### Erreur: "flutter: command not found"
```bash
# Ajouter Flutter au PATH
export PATH="$PATH:/path/to/flutter/bin"
```

### Erreur de connexion API
- Vérifier que le backend Laravel est lancé
- Vérifier l'URL dans `api_config.dart`
- Pour appareil physique: vérifier que le téléphone et l'ordinateur sont sur le même réseau Wi-Fi
- Désactiver le pare-feu temporairement pour tester

### Problème de build Android
```bash
# Nettoyer le cache
flutter clean
flutter pub get
flutter build apk
```

### Problème de build iOS
```bash
# Nettoyer les pods
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter build ios
```

## 📝 TODO / Améliorations futures

- [ ] Ajout de tests unitaires
- [ ] Ajout de tests d'intégration
- [ ] Mode hors ligne avec synchronisation
- [ ] Notifications push
- [ ] Support multilingue (FR/EN)
- [ ] Mode sombre
- [ ] Biométrie (empreinte, Face ID)
- [ ] Signature électronique des rapports
- [ ] Géolocalisation des rapports

## 👥 Équipe

- **Développeur**: [Votre Nom]
- **Client**: Station Service

## 📄 Licence

Propriétaire - Tous droits réservés

## 🆘 Support

Pour toute question ou problème:
- Email: support@example.com
- Documentation API: [backend/API_DOCUMENTATION.md](../backend/API_DOCUMENTATION.md)

---

**Version**: 1.0.0  
**Dernière mise à jour**: 22 décembre 2025
