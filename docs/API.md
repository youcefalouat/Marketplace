# API Documentation - Marketplace Contrôlée

Base URL: `https://your-api-domain.com/api`

## Authentification

L'API utilise JWT (JSON Web Tokens) pour l'authentification.

### Headers requis pour les endpoints protégés
```
Authorization: Bearer <votre_token_jwt>
Content-Type: application/json
```

---

## Endpoints Publics (sans authentification)

### POST /auth/register
Inscription d'un nouvel utilisateur.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "motdepasse123",
  "name": "Jean Dupont",
  "phone": "0612345678",
  "city": "Paris"
}
```

**Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "Jean Dupont",
    "phone": "0612345678",
    "city": "Paris",
    "role": "User"
  }
}
```

---

### POST /auth/login
Connexion d'un utilisateur existant.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "motdepasse123"
}
```

**Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "Jean Dupont",
    "phone": "0612345678",
    "city": "Paris",
    "role": "User"
  }
}
```

---

### GET /annonces
Liste des annonces approuvées (publiques).

**Query Parameters:**
| Paramètre | Type | Description |
|-----------|------|-------------|
| category | int | 0=Électroménager, 1=Meubles, 2=Literie, 3=Décoration |
| minPrice | decimal | Prix minimum |
| maxPrice | decimal | Prix maximum |
| city | string | Filtrer par ville |
| page | int | Numéro de page (défaut: 1) |
| pageSize | int | Éléments par page (défaut: 20) |

**Response (200):**
```json
{
  "items": [
    {
      "id": 1,
      "title": "Réfrigérateur Samsung",
      "price": 450.00,
      "city": "Paris",
      "category": "Electromenager",
      "mainImageUrl": "https://storage.blob.core.windows.net/annonces/image1.jpg",
      "createdAt": "2026-01-27T10:30:00Z"
    }
  ],
  "totalCount": 42,
  "page": 1,
  "pageSize": 20,
  "totalPages": 3
}
```

---

### GET /annonces/{id}
Détail d'une annonce approuvée.

**Response (200):**
```json
{
  "id": 1,
  "title": "Réfrigérateur Samsung",
  "description": "Réfrigérateur en excellent état, peu utilisé...",
  "price": 450.00,
  "category": "Electromenager",
  "state": "Used",
  "phone": "0612345678",
  "city": "Paris",
  "status": "Approved",
  "createdAt": "2026-01-27T10:30:00Z",
  "imageUrls": [
    "https://storage.blob.core.windows.net/annonces/image1.jpg",
    "https://storage.blob.core.windows.net/annonces/image2.jpg"
  ],
  "seller": {
    "name": "Jean Dupont",
    "phone": "0612345678",
    "city": "Paris"
  }
}
```

---

## Endpoints Utilisateur (authentification requise)

### GET /users/profile
Récupère le profil de l'utilisateur connecté.

**Response (200):**
```json
{
  "id": 1,
  "email": "user@example.com",
  "name": "Jean Dupont",
  "phone": "0612345678",
  "city": "Paris",
  "role": "User"
}
```

---

### PUT /users/profile
Met à jour le profil de l'utilisateur.

**Request Body:**
```json
{
  "name": "Jean-Pierre Dupont",
  "phone": "0698765432",
  "city": "Lyon"
}
```

---

### POST /annonces
Créer une nouvelle annonce (multipart/form-data).

**Form Data:**
| Champ | Type | Requis | Description |
|-------|------|--------|-------------|
| category | int | Oui | 0-3 |
| title | string | Oui | Titre de l'annonce |
| description | string | Oui | Description détaillée |
| price | decimal | Oui | Prix demandé |
| state | int | Oui | 0=Neuf, 1=Occasion |
| phone | string | Non | Téléphone (sinon celui du profil) |
| city | string | Non | Ville (sinon celle du profil) |
| images | file[] | Oui | 1 à 5 images |

**Response (201):**
```json
{
  "id": 5,
  "title": "Canapé cuir noir",
  "status": "Pending",
  ...
}
```

---

### GET /annonces/my
Liste des annonces de l'utilisateur connecté.

**Response (200):**
```json
[
  {
    "id": 5,
    "title": "Canapé cuir noir",
    "price": 800.00,
    "category": "Meubles",
    "status": "Pending",
    "mainImageUrl": "...",
    "createdAt": "2026-01-27T14:00:00Z"
  }
]
```

---

### DELETE /annonces/{id}
Supprime une annonce de l'utilisateur.

**Response (204):** No Content

---

## Endpoints Admin (rôle Admin requis)

### GET /admin/annonces/pending
Liste des annonces en attente de validation.

---

### GET /admin/annonces
Liste de toutes les annonces avec filtres.

**Query Parameters:**
| Paramètre | Type | Description |
|-----------|------|-------------|
| status | enum | Pending, Approved, Rejected |

---

### GET /admin/annonces/{id}
Détail complet d'une annonce pour admin (inclut notes internes).

---

### POST /admin/annonces/{id}/approve
Approuve une annonce.

**Response (200):**
```json
{
  "message": "Annonce approuvée"
}
```

---

### POST /admin/annonces/{id}/reject
Refuse une annonce.

**Response (200):**
```json
{
  "message": "Annonce refusée"
}
```

---

### POST /admin/annonces/{id}/note
Ajoute une note interne à une annonce.

**Request Body:**
```json
{
  "note": "Vendeur sérieux, produit vérifié"
}
```

---

### PUT /admin/annonces/{id}/estimate
Met à jour l'estimation magasin et le statut bonne affaire.

**Request Body:**
```json
{
  "storePriceEstimate": 600.00,
  "isGoodDeal": true
}
```

---

## Codes d'Erreur

| Code | Description |
|------|-------------|
| 200 | Succès |
| 201 | Créé avec succès |
| 204 | Supprimé avec succès |
| 400 | Requête invalide |
| 401 | Non authentifié |
| 403 | Accès refusé |
| 404 | Ressource non trouvée |
| 500 | Erreur serveur |

## Énumérations

### Category
| Valeur | Libellé |
|--------|---------|
| 0 | Électroménager |
| 1 | Meubles |
| 2 | Literie |
| 3 | Décoration |

### ProductState
| Valeur | Libellé |
|--------|---------|
| 0 | Neuf |
| 1 | Occasion |

### AnnonceStatus
| Valeur | Libellé |
|--------|---------|
| 0 | Pending (En attente) |
| 1 | Approved (Approuvée) |
| 2 | Rejected (Refusée) |
