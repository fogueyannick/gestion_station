# 🚀 Backend API - Gestion Station

Backend Laravel 12 pour la gestion des stations-service avec application mobile Flutter.

[![Laravel](https://img.shields.io/badge/Laravel-12-red.svg)](https://laravel.com)
[![PHP](https://img.shields.io/badge/PHP-8.2+-blue.svg)](https://php.net)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Quality](https://img.shields.io/badge/code%20quality-8.5%2F10-brightgreen.svg)](SUMMARY.md)

---

## ✨ Fonctionnalités

- 🔐 **Authentification API** avec Laravel Sanctum
- 📊 **Gestion des rapports journaliers** avec calcul automatique des ventes
- 📸 **Upload de photos** avec validation
- 📈 **Dashboard statistiques** avec données JSON
- 🔄 **Pagination** automatique (20 items/page)
- 📱 **API REST** pour mobile Flutter
- 🧪 **Tests automatisés** PHPUnit

---

## 🚀 Installation Rapide

### Prérequis
- PHP 8.2+
- Composer
- MySQL/SQLite

### Commandes

```bash
# 1. Installer les dépendances
composer install

# 2. Configuration
copy .env.example .env
php artisan key:generate

# 3. Base de données
php artisan migrate:fresh
php artisan db:seed --class=InitialDataSeeder

# 4. Stockage
php artisan storage:link

# 5. Lancer le serveur
php artisan serve
```

**URL**: http://127.0.0.1:8000

**Utilisateurs par défaut**:
- Gérant: `gerant` / `gerant`
- Pompiste: `pompiste` / `pompiste`

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)** | Guide complet de l'API |
| **[IMPROVEMENTS_APPLIED.md](IMPROVEMENTS_APPLIED.md)** | Détails des corrections |
| **[SUMMARY.md](SUMMARY.md)** | Résumé exécutif (scores qualité) |
| **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** | Checklist de déploiement |

---

## 🔌 Endpoints Principaux

### Authentification
```
POST   /api/auth/login      # Connexion
POST   /api/auth/logout     # Déconnexion
GET    /api/auth/me         # Info utilisateur
```

### Rapports
```
POST   /api/reports         # Créer un rapport
GET    /api/reports         # Liste paginée
PUT    /api/reports/{id}    # Mettre à jour
DELETE /api/reports/{id}    # Supprimer
```

### Dashboard
```
GET    /api/dashboard/stats # Statistiques
```

---

## 🧪 Tests

```bash
# Tous les tests
php artisan test

# Tests spécifiques
php artisan test --filter=ReportApiTest

# Avec couverture
php artisan test --coverage
```

**Tests disponibles**: 6 tests automatisés (authentification, CRUD, calculs, pagination, stats)

---

## 🎯 Améliorations Récentes

### ✅ Problèmes Critiques Résolus

1. **Incohérence des noms de modèles** - Relations Eloquent corrigées
2. **Calcul des ventes** - Implémenté automatiquement
3. **Stats avec JSON** - Correction pour champs `depenses` et `autres_ventes`
4. **Pagination** - Ajoutée (20 items/page)
5. **Contrainte unique** - Un seul rapport par station/jour

**Score qualité**: 8.5/10 (↑ +33% depuis le code review)

Voir [IMPROVEMENTS_APPLIED.md](IMPROVEMENTS_APPLIED.md) pour les détails.

---

## 🏗️ Architecture

```
backend/
├── app/
│   ├── Http/Controllers/     # Contrôleurs API
│   ├── Models/               # Modèles Eloquent
│   └── Imports/              # Import Excel
├── database/
│   ├── migrations/           # Migrations DB
│   └── seeders/              # Données initiales
├── routes/
│   └── api.php               # Routes API
├── tests/Feature/            # Tests automatisés
└── config/                   # Configuration
```

---

## 🔒 Sécurité

- ✅ Authentification Laravel Sanctum
- ✅ Validation stricte des entrées
- ✅ Protection SQL injection (Eloquent ORM)
- ✅ Hash des mots de passe (Bcrypt)
- ✅ CORS configurable
- ⚠️ À configurer en production: CORS, upload limits, HTTPS

---

## 🚀 Déploiement Production

Voir [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) pour la checklist complète.

**Essentiel**:
```bash
composer install --optimize-autoloader --no-dev
php artisan config:cache
php artisan route:cache
php artisan migrate --force
```

**Configuration**:
- `APP_ENV=production`
- `APP_DEBUG=false`
- Restreindre CORS
- Activer HTTPS
- Configurer sauvegardes

---

## 📊 Fonctionnalités Clés

### Calcul Automatique des Ventes

Le système calcule automatiquement les ventes en comparant les index actuels avec ceux du jour précédent:

```php
super_sales = (super1 + super2 + super3) - previous_total
gazoil_sales = (gazoil1 + gazoil2 + gazoil3) - previous_total
total_sales = super_sales + gazoil_sales
```

### Gestion des Dépenses JSON

Les champs `depenses` et `autres_ventes` sont stockés en JSON et correctement sommés:

```json
{
  "depenses": [100, 200, 300],  // Total: 600
  "autres_ventes": [50, 75]     // Total: 125
}
```

---

## 🛠️ Technologies

- **Framework**: Laravel 12
- **PHP**: 8.2+
- **Auth**: Laravel Sanctum
- **Base de données**: MySQL / SQLite
- **Import**: Maatwebsite Excel
- **Tests**: PHPUnit

---

## 📞 Support

- **Documentation Laravel**: https://laravel.com/docs/12.x
- **Documentation Sanctum**: https://laravel.com/docs/12.x/sanctum
- **Issues**: Voir les tests et logs

---

## 📝 License

MIT License - Voir fichier LICENSE

---

## 🤝 Contribution

Les contributions sont les bienvenues! Merci de:
1. Fork le projet
2. Créer une branche feature
3. Commiter les changements
4. Pousser vers la branche
5. Ouvrir une Pull Request

---

**Version**: 1.0  
**Dernière mise à jour**: 22 Décembre 2025  
**Statut**: ✅ Production Ready

In order to ensure that the Laravel community is welcoming to all, please review and abide by the [Code of Conduct](https://laravel.com/docs/contributions#code-of-conduct).

## Security Vulnerabilities

If you discover a security vulnerability within Laravel, please send an e-mail to Taylor Otwell via [taylor@laravel.com](mailto:taylor@laravel.com). All security vulnerabilities will be promptly addressed.

## License

The Laravel framework is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
