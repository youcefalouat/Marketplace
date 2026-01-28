# Guide d'Installation - Marketplace Contrôlée

## Prérequis

### Backend (.NET)
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- SQL Server (cloud ou local)
- Visual Studio 2022 ou VS Code

### Mobile (Flutter)
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.x+)
- Android Studio ou VS Code avec extensions Flutter
- Xcode (pour iOS, macOS uniquement)

---

## Configuration du Backend

### 1. Cloner le projet

```bash
git clone <repository-url>
cd marketplace-controlee
```

### 2. Configurer la base de données

Modifier le fichier `backend/MarketplaceApi/appsettings.json` :

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=VOTRE_SERVEUR;Database=MarketplaceDb;User Id=VOTRE_USER;Password=VOTRE_PASSWORD;TrustServerCertificate=True;"
  }
}
```

#### Options de base de données :

**SQL Server Cloud (Azure SQL) :**
```
Server=tcp:votre-serveur.database.windows.net,1433;Database=MarketplaceDb;User Id=admin;Password=VotreMotDePasse;Encrypt=True;TrustServerCertificate=False;
```

**SQL Server LocalDB (développement) :**
```
Server=(localdb)\mssqllocaldb;Database=MarketplaceDb_Dev;Trusted_Connection=True;TrustServerCertificate=True;
```

### 3. Configurer le stockage Azure Blob (optionnel)

Pour le stockage cloud des images, ajouter dans `appsettings.json` :

```json
{
  "AzureStorage": {
    "ConnectionString": "DefaultEndpointsProtocol=https;AccountName=VOTRE_COMPTE;AccountKey=VOTRE_CLE;EndpointSuffix=core.windows.net",
    "BaseUrl": "https://VOTRE_COMPTE.blob.core.windows.net"
  }
}
```

> **Note** : Sans configuration Azure, les images sont stockées localement dans `wwwroot/uploads/`

### 4. Configurer JWT

Modifier la clé secrète dans `appsettings.json` :

```json
{
  "JwtSettings": {
    "SecretKey": "VotreCleSecreteTresLongueAvecAuMoins32Caracteres!",
    "Issuer": "MarketplaceApi",
    "Audience": "MarketplaceApp",
    "ExpirationDays": "7"
  }
}
```

> ⚠️ **Important** : Utilisez une clé secrète unique et complexe en production !

### 5. Lancer le backend

```bash
cd backend/MarketplaceApi
dotnet restore
dotnet run
```

L'API sera disponible sur :
- **API REST** : https://localhost:5001/swagger
- **Admin Back-Office** : https://localhost:5001/admin

### 6. Compte administrateur par défaut

Au premier lancement, un compte admin est créé automatiquement :
- **Email** : `admin@marketplace.com`
- **Mot de passe** : `Admin123!`

> ⚠️ **Changez ce mot de passe en production !**

---

## Configuration de l'Application Mobile

### 1. Installer Flutter

```bash
# Vérifier l'installation
flutter doctor
```

### 2. Configurer l'URL de l'API

Modifier le fichier `mobile/marketplace_app/lib/services/api_service.dart` :

```dart
// Pour Android emulator (localhost de la machine hôte)
static const String baseUrl = 'http://10.0.2.2:5000/api';

// Pour iOS simulator
// static const String baseUrl = 'http://localhost:5000/api';

// Pour un appareil physique ou production
// static const String baseUrl = 'https://votre-api.azurewebsites.net/api';
```

### 3. Installer les dépendances

```bash
cd mobile/marketplace_app
flutter pub get
```

### 4. Lancer l'application

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (debug uniquement)
flutter run -d chrome
```

---

## Déploiement en Production

### Backend sur Azure App Service

1. Créer une Azure SQL Database
2. Créer un Azure App Service (.NET 8)
3. Configurer les variables d'environnement :
   - `ConnectionStrings__DefaultConnection`
   - `JwtSettings__SecretKey`
   - `AzureStorage__ConnectionString`

4. Déployer via GitHub Actions ou Azure DevOps

### Application Mobile

**Android :**
```bash
flutter build apk --release
# ou pour app bundle
flutter build appbundle --release
```

**iOS :**
```bash
flutter build ipa --release
```

---

## Structure du Projet

```
marketplace-controlee/
├── backend/
│   └── MarketplaceApi/
│       ├── Controllers/      # API REST endpoints
│       ├── Models/           # Entités Entity Framework
│       ├── DTOs/             # Data Transfer Objects
│       ├── Data/             # DbContext
│       ├── Services/         # Logique métier
│       ├── Components/       # Blazor components
│       └── Pages/Admin/      # Pages admin Blazor
├── mobile/
│   └── marketplace_app/
│       └── lib/
│           ├── models/       # Modèles Dart
│           ├── services/     # Service API
│           ├── providers/    # State management
│           ├── screens/      # Écrans UI
│           └── widgets/      # Widgets réutilisables
└── docs/
    ├── INSTALLATION.md       # Ce fichier
    └── API.md                # Documentation API
```

---

## Dépannage

### Erreur de connexion à la base de données
- Vérifiez que SQL Server est accessible
- Vérifiez la chaîne de connexion
- Assurez-vous que le firewall autorise les connexions

### Erreur CORS sur l'API
- L'API est configurée pour accepter toutes les origines en développement
- En production, configurez les origines autorisées

### Images non affichées
- Vérifiez les permissions du dossier `wwwroot/uploads`
- Vérifiez la configuration Azure Blob Storage

### Erreur Flutter "Connection refused"
- Vérifiez que l'API est en cours d'exécution
- Vérifiez l'URL de l'API dans `api_service.dart`
- Pour Android, utilisez `10.0.2.2` au lieu de `localhost`

---

## Support

Pour toute question ou problème, contactez l'équipe de développement.
