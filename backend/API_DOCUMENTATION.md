# 📚 API Documentation - Gestion Station

API Backend Laravel pour la gestion des stations-service.

---

## 🚀 Démarrage Rapide

### Installation
```bash
cd backend
composer install
copy .env.example .env
php artisan key:generate
php artisan migrate:fresh --seed
php artisan storage:link
php artisan serve
```

**URL de base**: `http://127.0.0.1:8000/api`

---

## 🔐 Authentification

### 1. Connexion (Login)

**Endpoint**: `POST /auth/login`

**Body**:
```json
{
  "name": "gerant",
  "password": "gerant"
}
```

**Réponse**:
```json
{
  "access_token": "1|xxxxxxxxxxxxx",
  "token_type": "Bearer",
  "role": "gerant"
}
```

**Utilisateurs par défaut**:
- **Gérant**: `gerant` / `gerant`
- **Pompiste**: `pompiste` / `pompiste`

### 2. Déconnexion

**Endpoint**: `POST /auth/logout`  
**Headers**: `Authorization: Bearer {token}`

### 3. Informations utilisateur

**Endpoint**: `GET /auth/me`  
**Headers**: `Authorization: Bearer {token}`

---

## 📊 Gestion des Rapports

> ⚠️ **Toutes les routes nécessitent l'authentification** (header `Authorization: Bearer {token}`)

### 1. Créer un rapport

**Endpoint**: `POST /reports`

**Headers**:
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Body**:
```json
{
  "station_id": 1,
  "date": "2025-12-22",
  "super1_index": 1000.50,
  "super2_index": 2000.75,
  "super3_index": 3000.25,
  "gazoil1_index": 1500.00,
  "gazoil2_index": 2500.50,
  "gazoil3_index": 3500.75,
  "stock_sup_9000": 100,
  "stock_sup_10000": 200,
  "stock_sup_14000": 300,
  "stock_gaz_10000": 150,
  "stock_gaz_6000": 250,
  "versement": 5000.00,
  "depenses": [100, 200, 300],
  "autres_ventes": [50, 75, 25],
  "commandes": [1000, 2000]
}
```

**Réponse** (201 Created):
```json
{
  "message": "Rapport enregistré",
  "report": {
    "id": 1,
    "station_id": 1,
    "user_id": 1,
    "date": "2025-12-22",
    "super1_index": 1000.50,
    "super2_index": 2000.75,
    "super3_index": 3000.25,
    "gazoil1_index": 1500.00,
    "gazoil2_index": 2500.50,
    "gazoil3_index": 3500.75,
    "super_sales": 6001.50,
    "gazoil_sales": 7500.25,
    "total_sales": 13501.75,
    "stock_sup_9000": 100,
    "stock_sup_10000": 200,
    "stock_sup_14000": 300,
    "stock_gaz_10000": 150,
    "stock_gaz_6000": 250,
    "versement": 5000.00,
    "depenses": [100, 200, 300],
    "autres_ventes": [50, 75, 25],
    "commandes": [1000, 2000],
    "photos": [],
    "user": {...},
    "station": {...}
  }
}
```

**Notes importantes**:
- ✅ Les ventes (`super_sales`, `gazoil_sales`, `total_sales`) sont **calculées automatiquement**
- ✅ Si un rapport existe déjà pour cette station/date, il sera **mis à jour** (upsert)
- ✅ Pour le premier rapport: ventes = somme des index
- ✅ Pour les suivants: ventes = index actuel - index du jour précédent

### 2. Upload de photos (multipart)

**Endpoint**: `POST /reports` (même endpoint)

**Headers**:
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Body** (form-data):
```
station_id: 1
date: 2025-12-22
super1_index: 1000
... (autres champs)
photos[]: [fichier image 1]
photos[]: [fichier image 2]
```

**Types acceptés**: jpg, jpeg, png, gif, svg, webp

### 3. Lister les rapports (paginé)

**Endpoint**: `GET /reports`

**Réponse**:
```json
{
  "current_page": 1,
  "data": [
    {
      "id": 1,
      "station_id": 1,
      "user_id": 1,
      "date": "2025-12-22",
      "super_sales": 6001.50,
      "gazoil_sales": 7500.25,
      "total_sales": 13501.75,
      "versement": 5000.00,
      "user": {...},
      "station": {...}
    }
  ],
  "first_page_url": "http://127.0.0.1:8000/api/reports?page=1",
  "from": 1,
  "last_page": 3,
  "last_page_url": "http://127.0.0.1:8000/api/reports?page=3",
  "next_page_url": "http://127.0.0.1:8000/api/reports?page=2",
  "path": "http://127.0.0.1:8000/api/reports",
  "per_page": 20,
  "prev_page_url": null,
  "to": 20,
  "total": 45
}
```

**Pagination**:
- Par défaut: 20 rapports par page
- Naviguer: `GET /reports?page=2`

### 4. Mettre à jour un rapport

**Endpoint**: `PUT /reports/{id}`

**Body**: Mêmes champs que la création (tous optionnels sauf les index)

**Note**: Les photos sont **fusionnées** avec les anciennes (pas remplacées)

### 5. Supprimer un rapport

**Endpoint**: `DELETE /reports/{id}`

**Réponse** (200):
```json
{
  "message": "Deleted successfully"
}
```

---

## 📈 Statistiques Dashboard

### Obtenir les statistiques

**Endpoint**: `GET /dashboard/stats`

**Réponse**:
```json
{
  "total_reports": 45,
  "total_versements": 225000.00,
  "total_depenses": 15000.00,
  "total_autres_ventes": 3500.00
}
```

**Calculs**:
- `total_reports`: Nombre total de rapports
- `total_versements`: Somme de tous les versements
- `total_depenses`: Somme de toutes les valeurs dans les tableaux `depenses`
- `total_autres_ventes`: Somme de toutes les valeurs dans les tableaux `autres_ventes`

---

## 🔧 Codes de Statut HTTP

| Code | Signification | Contexte |
|------|---------------|----------|
| 200 | OK | Requête réussie |
| 201 | Created | Rapport créé |
| 401 | Unauthorized | Token manquant ou invalide |
| 404 | Not Found | Ressource introuvable |
| 422 | Unprocessable Entity | Erreur de validation |
| 500 | Internal Server Error | Erreur serveur |

---

## 🧪 Exemples avec cURL

### Connexion
```bash
curl -X POST http://127.0.0.1:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"name":"gerant","password":"gerant"}'
```

### Créer un rapport
```bash
curl -X POST http://127.0.0.1:8000/api/reports \
  -H "Authorization: Bearer 1|xxxxx" \
  -H "Content-Type: application/json" \
  -d '{
    "station_id": 1,
    "date": "2025-12-22",
    "super1_index": 1000,
    "super2_index": 2000,
    "super3_index": 3000,
    "gazoil1_index": 1500,
    "gazoil2_index": 2500,
    "gazoil3_index": 3500,
    "stock_sup_9000": 100,
    "stock_sup_10000": 200,
    "stock_sup_14000": 300,
    "stock_gaz_10000": 150,
    "stock_gaz_6000": 250,
    "versement": 5000
  }'
```

### Lister les rapports
```bash
curl -X GET http://127.0.0.1:8000/api/reports \
  -H "Authorization: Bearer 1|xxxxx"
```

### Obtenir les statistiques
```bash
curl -X GET http://127.0.0.1:8000/api/dashboard/stats \
  -H "Authorization: Bearer 1|xxxxx"
```

---

## 🧪 Tests

### Exécuter tous les tests
```bash
php artisan test
```

### Exécuter les tests des rapports uniquement
```bash
php artisan test --filter=ReportApiTest
```

### Tests disponibles
- ✅ Création de rapport avec calcul automatique des ventes
- ✅ Calcul correct avec rapport précédent
- ✅ Pagination (20 par page)
- ✅ Statistiques avec champs JSON
- ✅ Contrainte unique par station/date
- ✅ Authentification requise

---

## 🔍 Validation des Champs

### Champs requis
- `station_id` (integer, doit exister dans la table stations)
- `date` (format: YYYY-MM-DD)
- `super1_index`, `super2_index`, `super3_index` (numeric)
- `gazoil1_index`, `gazoil2_index`, `gazoil3_index` (numeric)
- `stock_sup_9000`, `stock_sup_10000`, `stock_sup_14000` (integer)
- `stock_gaz_10000`, `stock_gaz_6000` (integer)

### Champs optionnels
- `versement` (numeric, défaut: 0)
- `depenses` (array de nombres)
- `autres_ventes` (array de nombres)
- `commandes` (array)
- `photos` (array d'images)

---

## 🛡️ Sécurité

### Authentification
- Utilise **Laravel Sanctum** pour les tokens API
- Token envoyé via header: `Authorization: Bearer {token}`
- Token créé à la connexion, détruit à la déconnexion

### Validation
- Tous les champs sont validés côté serveur
- Protection contre les injections SQL (Eloquent ORM)
- Protection CSRF désactivée pour l'API (normal)

### CORS
- **Développement**: Toutes les origines acceptées (`*`)
- **Production**: À restreindre aux domaines autorisés

---

## 📦 Structure de la Base de Données

### Table `reports`
| Colonne | Type | Description |
|---------|------|-------------|
| id | bigint | Clé primaire |
| station_id | bigint | FK vers stations |
| user_id | bigint | FK vers users |
| date | date | Date du rapport |
| super1_index | decimal | Index pompe super 1 |
| super2_index | decimal | Index pompe super 2 |
| super3_index | decimal | Index pompe super 3 |
| gazoil1_index | decimal | Index pompe gazoil 1 |
| gazoil2_index | decimal | Index pompe gazoil 2 |
| gazoil3_index | decimal | Index pompe gazoil 3 |
| **super_sales** | decimal | **Ventes super (calculé)** |
| **gazoil_sales** | decimal | **Ventes gazoil (calculé)** |
| **total_sales** | decimal | **Total ventes (calculé)** |
| stock_sup_9000 | integer | Stock super 9000L |
| stock_sup_10000 | integer | Stock super 10000L |
| stock_sup_14000 | integer | Stock super 14000L |
| stock_gaz_10000 | integer | Stock gazoil 10000L |
| stock_gaz_6000 | integer | Stock gazoil 6000L |
| versement | decimal | Montant versé |
| depenses | json | Tableau des dépenses |
| autres_ventes | json | Tableau autres ventes |
| commandes | json | Tableau commandes |
| photos | json | Chemins des photos |

**Contrainte unique**: (`station_id`, `date`) - Un seul rapport par station par jour

---

## 🆘 Dépannage

### Token invalide (401)
- Vérifier que le token est bien envoyé dans le header
- Format: `Authorization: Bearer {token}`
- Le token expire-t-il? (configuré dans `config/sanctum.php`)

### Erreur de validation (422)
- Vérifier que tous les champs requis sont présents
- Vérifier le format des données (nombres, dates, etc.)
- Lire le message d'erreur retourné

### Station introuvable
- Vérifier que la station existe: `GET /api/stations`
- Exécuter le seeder: `php artisan db:seed`

---

## 📞 Support

- **Documentation Laravel**: https://laravel.com/docs/12.x
- **Documentation Sanctum**: https://laravel.com/docs/12.x/sanctum
- **Tests**: Consulter `tests/Feature/ReportApiTest.php`

---

**Version**: 1.0  
**Dernière mise à jour**: 22 Décembre 2025
