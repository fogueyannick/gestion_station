# 🚀 Guide d'Installation Flutter - Windows

## 📋 Prérequis

- Windows 10/11 (64-bit)
- 10 GB d'espace disque
- Connexion Internet

## 📥 Étape 1: Télécharger Flutter

1. Aller sur: https://docs.flutter.dev/get-started/install/windows
2. Télécharger le fichier ZIP Flutter SDK (environ 1.5 GB)
3. Extraire dans `C:\src\flutter` (créer le dossier si nécessaire)

**Alternative via PowerShell:**
```powershell
# Créer le dossier
New-Item -ItemType Directory -Path C:\src -Force

# Télécharger (remplacer X.X.X par la version actuelle)
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.10.3-stable.zip" -OutFile "C:\src\flutter.zip"

# Extraire
Expand-Archive -Path C:\src\flutter.zip -DestinationPath C:\src -Force
```

## 🔧 Étape 2: Ajouter Flutter au PATH

### Option A: Via l'interface Windows

1. Rechercher "Variables d'environnement" dans le menu Démarrer
2. Cliquer sur "Modifier les variables d'environnement système"
3. Cliquer sur "Variables d'environnement..."
4. Dans "Variables utilisateur", sélectionner "Path" puis "Modifier"
5. Cliquer sur "Nouveau"
6. Ajouter: `C:\src\flutter\bin`
7. Cliquer sur "OK" trois fois

### Option B: Via PowerShell (permanent)

```powershell
# Ajouter au PATH utilisateur (permanent)
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newPath = "$currentPath;C:\src\flutter\bin"
[Environment]::SetEnvironmentVariable("Path", $newPath, "User")

# Redémarrer PowerShell après cette commande
```

### Option C: Via PowerShell (session en cours uniquement)

```powershell
# Ajouter au PATH (temporaire, pour la session actuelle)
$env:Path += ";C:\src\flutter\bin"
```

## ✅ Étape 3: Vérifier l'installation

```powershell
# Ouvrir un NOUVEAU terminal PowerShell et exécuter:
flutter --version

# Devrait afficher quelque chose comme:
# Flutter 3.10.3 • channel stable
```

## 🔍 Étape 4: Vérifier les dépendances

```powershell
flutter doctor
```

Vous verrez un rapport comme celui-ci:

```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.10.3, on Windows 11)
[✗] Android toolchain - develop for Android devices
    ✗ Android SDK not found
[✗] Chrome - develop for the web
[✗] Visual Studio - develop Windows apps
[!] Android Studio (not installed)
[✓] VS Code (version 1.85.0)
```

## 📱 Étape 5: Installer Android Studio (pour Android)

### 5.1 Télécharger Android Studio

1. Aller sur: https://developer.android.com/studio
2. Télécharger Android Studio
3. Installer avec les options par défaut

### 5.2 Configurer Android Studio

```powershell
# Lancer Android Studio
# Suivre l'assistant de configuration
# Installer Android SDK, Android SDK Platform, Android Virtual Device
```

### 5.3 Accepter les licences Android

```powershell
flutter doctor --android-licenses

# Taper 'y' pour accepter toutes les licences
```

## 🔌 Étape 6: Installer les extensions VS Code

```powershell
# Si vous utilisez VS Code:
code --install-extension Dart-Code.dart-code
code --install-extension Dart-Code.flutter
```

Ou manuellement dans VS Code:
1. Ouvrir VS Code
2. Aller dans Extensions (Ctrl+Shift+X)
3. Rechercher et installer:
   - **Flutter**
   - **Dart**

## 📱 Étape 7: Créer un émulateur Android

### Via Android Studio:

1. Ouvrir Android Studio
2. Aller dans "Tools" > "Device Manager"
3. Cliquer sur "Create Device"
4. Choisir un appareil (ex: Pixel 5)
5. Télécharger une image système (ex: API 33)
6. Cliquer sur "Finish"

### Via ligne de commande:

```powershell
# Lister les images système disponibles
flutter emulators

# Créer un émulateur (si disponible)
flutter emulators --create

# Lancer un émulateur
flutter emulators --launch <emulator_id>
```

## 🧪 Étape 8: Tester Flutter

```powershell
# Créer une app de test
flutter create test_app
cd test_app

# Lister les appareils disponibles
flutter devices

# Lancer l'app (l'émulateur doit être démarré)
flutter run
```

## 🚀 Étape 9: Lancer votre projet

```powershell
# Aller dans le dossier du projet
cd f:\workspace\MaitreYann\gestion_station\mobile\station_mobile

# Installer les dépendances
flutter pub get

# Vérifier les appareils
flutter devices

# Lancer l'app
flutter run
```

## 🔧 Dépannage

### Problème: "flutter: command not found"

**Solution**:
```powershell
# Vérifier le PATH
$env:Path

# Si C:\src\flutter\bin n'apparaît pas, l'ajouter:
$env:Path += ";C:\src\flutter\bin"

# Ou redémarrer le terminal
```

### Problème: "Android licenses not accepted"

**Solution**:
```powershell
flutter doctor --android-licenses
# Taper 'y' pour tout accepter
```

### Problème: "No devices found"

**Solution**:
```powershell
# Vérifier que l'émulateur est lancé
flutter emulators
flutter emulators --launch <emulator_id>

# Ou connecter un appareil physique via USB (activer le debug USB)
```

### Problème: Build échoue

**Solution**:
```powershell
# Nettoyer le cache
flutter clean
flutter pub get

# Réessayer
flutter run
```

## 📝 Commandes Utiles

```powershell
# Vérifier la version
flutter --version

# Mettre à jour Flutter
flutter upgrade

# Analyser le code
flutter analyze

# Formater le code
dart format lib/

# Lister les appareils
flutter devices

# Lancer l'app
flutter run

# Lancer en mode release
flutter run --release

# Build APK
flutter build apk --release

# Nettoyer
flutter clean

# Installer les dépendances
flutter pub get

# Mettre à jour les dépendances
flutter pub upgrade
```

## 🌐 Configurer l'API pour appareil physique

Si vous testez sur un appareil physique:

1. **Trouver votre IP locale**:
```powershell
ipconfig
# Chercher "Adresse IPv4" (ex: 192.168.1.10)
```

2. **Modifier la configuration**:
```dart
// Dans lib/config/api_config.dart
static const String baseUrl = "http://192.168.1.10:8000/api";
```

3. **Connecter téléphone et PC au même Wi-Fi**

4. **Autoriser le firewall** (si nécessaire):
```powershell
# Autoriser Laravel
netsh advfirewall firewall add rule name="Laravel Dev Server" dir=in action=allow protocol=TCP localport=8000
```

## ✅ Checklist finale

- [ ] Flutter installé (`flutter --version` fonctionne)
- [ ] `flutter doctor` ne montre pas d'erreurs critiques
- [ ] Android Studio installé et configuré
- [ ] Licences Android acceptées
- [ ] Émulateur créé et fonctionne
- [ ] VS Code avec extensions Flutter/Dart (optionnel)
- [ ] Projet compile (`flutter pub get` réussit)
- [ ] App se lance (`flutter run` fonctionne)

## 📚 Ressources

- Documentation officielle: https://flutter.dev/docs
- Codelabs: https://docs.flutter.dev/codelabs
- Samples: https://flutter.github.io/samples/
- Pub.dev (packages): https://pub.dev/
- Stack Overflow: https://stackoverflow.com/questions/tagged/flutter

## 🆘 Support

Si vous rencontrez des problèmes:

1. Exécuter `flutter doctor -v` pour plus de détails
2. Chercher l'erreur sur Google/Stack Overflow
3. Consulter la documentation Flutter
4. Vérifier les logs détaillés avec `flutter run -v`

---

**Temps estimé d'installation**: 30-60 minutes (selon la connexion Internet)

**Prêt à développer?** 🚀
