# ⚡ Guide Rapide - Build Application Mobile

## 🎯 Pour les pressés

### Option 1: Tester en mode développement

```powershell
# 1. Aller dans le dossier
cd f:\workspace\MaitreYann\gestion_station\mobile\station_mobile

# 2. Installer dépendances
flutter pub get

# 3. Lancer (émulateur doit être démarré)
flutter run
```

### Option 2: Builder l'APK

```powershell
# Build APK release
flutter build apk --release

# Fichier généré:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 📝 Checklist avant le build

- [ ] Flutter est installé (`flutter --version`)
- [ ] Backend Laravel est lancé (`php artisan serve`)
- [ ] URL API configurée dans `lib/config/api_config.dart`
- [ ] Aucune erreur avec `flutter analyze`
- [ ] Testé en mode debug (`flutter run`)

---

## 🔧 Configuration selon l'environnement

### Pour émulateur Android
```dart
// lib/config/api_config.dart
static const String baseUrl = "http://10.0.2.2:8000/api";
```

### Pour émulateur iOS
```dart
// lib/config/api_config.dart
static const String baseUrl = "http://localhost:8000/api";
```

### Pour appareil physique
```dart
// lib/config/api_config.dart
// Remplacer par votre IP locale (obtenue avec ipconfig)
static const String baseUrl = "http://192.168.1.XXX:8000/api";
```

### Pour production
```dart
// lib/config/api_config.dart
static const String baseUrl = "https://votre-domaine.com/api";
```

---

## 🚀 Commandes principales

```powershell
# Installer dépendances
flutter pub get

# Analyser le code
flutter analyze

# Lancer en debug
flutter run

# Lancer en release
flutter run --release

# Build APK
flutter build apk --release

# Build AAB (Google Play Store)
flutter build appbundle --release

# Nettoyer le cache
flutter clean

# Réinstaller tout
flutter clean; flutter pub get

# Vérifier les appareils
flutter devices

# Voir les logs
flutter logs
```

---

## 📱 Installer l'APK sur téléphone

### Via câble USB

```powershell
# 1. Activer "Debug USB" sur le téléphone
# 2. Connecter le téléphone
# 3. Installer
flutter install

# Ou manuellement
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Via partage de fichier

1. Copier `app-release.apk` sur le téléphone
2. Ouvrir le fichier sur le téléphone
3. Autoriser l'installation depuis sources inconnues
4. Installer

---

## ⚙️ Configuration production recommandée

### 1. Changer le nom de l'app

**Android**: `android/app/src/main/AndroidManifest.xml`
```xml
<application
    android:label="Station Service"
    ...>
```

**iOS**: `ios/Runner/Info.plist`
```xml
<key>CFBundleName</key>
<string>Station Service</string>
```

### 2. Changer l'icône de l'app

1. Préparer une icône 1024x1024 px
2. Utiliser un générateur: https://appicon.co/
3. Remplacer les fichiers dans:
   - `android/app/src/main/res/mipmap-*`
   - `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### 3. Configurer le splash screen

Modifier: `android/app/src/main/res/drawable/launch_background.xml`

### 4. Changer l'identifiant de l'app

**Android**: `android/app/build.gradle`
```gradle
defaultConfig {
    applicationId "com.votreentreprise.station"
    ...
}
```

**iOS**: Ouvrir `ios/Runner.xcworkspace` dans Xcode et changer le Bundle Identifier

---

## 🔒 Signer l'APK (production)

### Créer la clé

```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Sauvegarder dans: android/app/
```

### Configurer Gradle

**Créer**: `android/key.properties`
```properties
storePassword=votre_mot_de_passe
keyPassword=votre_mot_de_passe
keyAlias=upload
storeFile=upload-keystore.jks
```

**Modifier**: `android/app/build.gradle`
```gradle
// Avant android {
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Build signé

```powershell
flutter build apk --release
# ou
flutter build appbundle --release
```

---

## 📊 Vérifier la taille de l'app

```powershell
# Analyser la taille
flutter build apk --analyze-size

# Voir les détails
flutter build apk --release --verbose
```

**Taille attendue**: 20-30 MB

---

## 🐛 Problèmes courants

### "Gradle build failed"

```powershell
# Solution
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### "No devices found"

```powershell
# Lister les appareils
flutter devices

# Lancer l'émulateur
flutter emulators
flutter emulators --launch <id>
```

### "Version conflict"

```powershell
# Mettre à jour les dépendances
flutter pub upgrade --major-versions
```

### "Build prend trop de temps"

```powershell
# Désactiver R8 (temporaire, pour debug)
# android/gradle.properties
android.enableR8=false
```

---

## ✅ Checklist finale avant release

Production:
- [ ] URL API de production configurée
- [ ] Tests sur émulateur OK
- [ ] Tests sur appareil physique OK
- [ ] APK signé avec clé de production
- [ ] Icône de l'app personnalisée
- [ ] Nom de l'app correct
- [ ] Splash screen configuré
- [ ] Permissions vérifiées (camera, storage)
- [ ] Version et build number incrémentés
- [ ] Changelog documenté
- [ ] APK testé sur plusieurs appareils
- [ ] Performance vérifiée (pas de lag)

---

## 📦 Distribuer l'APK

### Google Play Store

1. Créer un compte développeur (25$ unique)
2. Créer une app dans la console
3. Upload l'AAB:
```powershell
flutter build appbundle --release
```
4. Remplir les informations (description, screenshots)
5. Soumettre pour review

### Distribution directe

1. Upload l'APK sur votre serveur
2. Partager le lien
3. Les utilisateurs doivent autoriser les sources inconnues

---

## 🎉 Build réussi!

Votre APK est ici:
```
build/app/outputs/flutter-apk/app-release.apk
```

**Taille**: ~20-30 MB  
**Compatible**: Android 5.0+ (API 21+)

---

## 📞 Besoin d'aide?

1. Voir les logs: `flutter run -v`
2. Consulter: `CODE_REVIEW.md`
3. Documentation Flutter: https://flutter.dev/docs
4. Stack Overflow: https://stackoverflow.com/questions/tagged/flutter

---

**Bon build! 🚀**
