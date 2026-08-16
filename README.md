# RAAGA - Application Mobile E-commerce

## Description
RAAGA est une application mobile e-commerce développée avec Flutter pour le marché burkinabé. Elle permet aux e-commerçants de créer et gérer leurs produits, et aux clients de découvrir et commander des produits.

## Fonctionnalités

### Pour les E-commerçants
- ✅ Création de produits avec images
- ✅ Gestion des catégories
- ✅ Tableau de bord des ventes
- ✅ Gestion des commandes
- ✅ Analytics des ventes

### Pour les Clients
- ✅ Découverte des produits récents (affichage en cercles comme WhatsApp)
- ✅ Navigation par catégories
- ✅ Recherche de produits
- ✅ Détails des produits
- ✅ Ajout au panier
- ✅ Passation de commandes

## Technologies Utilisées
- **Flutter** - Framework de développement mobile
- **Supabase** - Backend as a Service (Base de données, Authentification, Storage)
- **Go Router** - Navigation
- **Image Picker** - Sélection d'images
- **Path Provider** - Gestion des fichiers

## Installation

### Prérequis
- Flutter SDK (version 3.0 ou supérieure)
- Android Studio / VS Code
- Compte Supabase

### Étapes d'installation

1. **Cloner le repository**
```bash
git clone <url-du-repo>
cd skr_univers
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Configurer Supabase**
   - Créer un projet sur [Supabase](https://supabase.com)
   - Récupérer l'URL et la clé anonyme
   - Mettre à jour `lib/core/constants/app_constants.dart` avec vos credentials

4. **Configurer la base de données**
   - Créer les tables nécessaires dans Supabase :
     - `products` (id, merchant_id, title, description, price, original_price, stock_quantity, images, category, tags, is_active, is_featured, created_at, updated_at)
     - `merchants` (id, business_name, business_image, business_phone, business_address)
     - `customers` (id, name, email, phone, address)

5. **Lancer l'application**
```bash
flutter run
```

## Structure du Projet

```
lib/
├── core/
│   ├── constants/          # Constantes de l'application
│   ├── routes/            # Configuration des routes
│   └── theme/             # Thème et styles
├── data/
│   ├── models/            # Modèles de données
│   ├── repositories/      # Repositories
│   └── services/          # Services (API, Auth, etc.)
├── features/
│   ├── auth/              # Authentification
│   ├── customer/          # Fonctionnalités client
│   ├── merchant/          # Fonctionnalités e-commerçant
│   └── shared/            # Composants partagés
└── main.dart              # Point d'entrée
```

## Fonctionnalités Principales

### Page d'Accueil Client
- **Produits récents** : Affichage en cercles comme les statuts WhatsApp
- **Catégories populaires** : Navigation rapide par catégorie
- **Produits en vedette** : Grille de produits recommandés
- **Design élégant** : Interface moderne et intuitive

### Gestion des Produits
- **Création** : Formulaire complet avec images multiples
- **Catégories** : Système de catégorisation flexible
- **Prix** : Support des prix originaux et réduits
- **Stock** : Gestion des quantités disponibles

### Navigation
- **Routes dynamiques** : Navigation fluide entre les pages
- **Paramètres** : Passage de données entre les écrans
- **Authentification** : Gestion des sessions utilisateur

## Personnalisation

### Thème
Le thème peut être personnalisé dans `lib/core/theme/app_theme.dart` :
- Couleurs primaires et secondaires
- Typographie
- Espacements
- Bordures et ombres

### Catégories
Les catégories sont définies dans `lib/core/constants/categories.dart` et peuvent être facilement modifiées.

## Déploiement

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit les changements (`git commit -m 'Ajouter nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Ouvrir une Pull Request

## Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## Support

Pour toute question ou problème, veuillez ouvrir une issue sur GitHub ou contacter l'équipe de développement.

## Roadmap

- [ ] Système de paiement mobile money
- [ ] Notifications push
- [ ] Chat en temps réel
- [ ] Système de livraison
- [ ] Analytics avancées
- [ ] Mode hors ligne
- [ ] Multi-langues (Français, Anglais, Langues locales)