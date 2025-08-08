# SKR Univers - Application E-commerce

Une application e-commerce moderne développée avec Flutter, offrant deux volets distincts : un espace pour les e-commerçants et un espace pour les clients.

## 🚀 Fonctionnalités

### Pour les E-commerçants
- ✅ Inscription et authentification
- ✅ Tableau de bord avec statistiques
- ✅ Gestion des produits (ajout, modification, suppression)
- ✅ Suivi des commandes
- ✅ Analytics et rapports
- ✅ Profil et paramètres

### Pour les Clients
- ✅ Inscription et authentification
- ✅ Parcours des produits
- ✅ Panier d'achat
- ✅ Historique des commandes
- ✅ Profil utilisateur

## 🛠️ Technologies utilisées

- **Frontend**: Flutter 3.7.2+
- **Backend**: Supabase
- **Base de données**: PostgreSQL (via Supabase)
- **Authentification**: Supabase Auth
- **Stockage**: Supabase Storage
- **Navigation**: Go Router
- **Gestion d'état**: Provider
- **UI**: Material Design 3

## 📱 Captures d'écran

*Captures d'écran à ajouter*

## 🏗️ Architecture du projet

```
lib/
├── core/
│   ├── constants/          # Constantes de l'application
│   ├── theme/             # Thème et styles
│   ├── routes/            # Configuration de navigation
│   └── utils/             # Utilitaires
├── features/
│   ├── auth/              # Authentification
│   │   ├── presentation/
│   │   └── domain/
│   ├── merchant/          # Fonctionnalités e-commerçants
│   │   ├── presentation/
│   │   └── domain/
│   ├── customer/          # Fonctionnalités clients
│   │   ├── presentation/
│   │   └── domain/
│   └── shared/            # Composants partagés
│       └── presentation/
└── data/
    ├── models/            # Modèles de données
    ├── services/          # Services API
    └── repositories/      # Couche d'accès aux données
```

## 🚀 Installation

### Prérequis

- Flutter SDK 3.7.2+
- Dart SDK
- Android Studio / VS Code
- Compte Supabase

### Étapes d'installation

1. **Cloner le repository**
   ```bash
   git clone <repository-url>
   cd skr_univers
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Configurer Supabase**
   - Créer un projet sur [Supabase](https://supabase.com)
   - Récupérer l'URL et la clé anonyme
   - Mettre à jour `lib/core/constants/app_constants.dart`

4. **Lancer l'application**
   ```bash
   flutter run
   ```

## 🔧 Configuration Supabase

### Tables nécessaires

#### Table `users`
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  phone_number TEXT,
  user_type TEXT NOT NULL CHECK (user_type IN ('customer', 'merchant')),
  profile_image TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  
  -- Champs spécifiques aux e-commerçants
  business_name TEXT,
  business_description TEXT,
  business_address TEXT,
  business_phone TEXT,
  business_email TEXT,
  is_verified BOOLEAN DEFAULT FALSE
);
```

#### Table `products`
```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  original_price DECIMAL(10,2),
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  images TEXT[] DEFAULT '{}',
  category TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT TRUE,
  is_featured BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Politiques RLS (Row Level Security)

```sql
-- Activer RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Politiques pour users
CREATE POLICY "Users can view their own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Politiques pour products
CREATE POLICY "Anyone can view active products" ON products
  FOR SELECT USING (is_active = true);

CREATE POLICY "Merchants can manage their own products" ON products
  FOR ALL USING (
    auth.uid() = merchant_id AND 
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() AND users.user_type = 'merchant'
    )
  );
```

## 🎨 Thème et Design

L'application utilise un thème moderne avec :
- **Couleurs principales**: Indigo (#6366F1)
- **Couleurs secondaires**: Vert (#10B981)
- **Police**: Poppins
- **Design**: Material Design 3

## 📋 Fonctionnalités à venir

- [ ] Système de paiement (Stripe/PayPal)
- [ ] Notifications push
- [ ] Système de notation et avis
- [ ] Chat en temps réel
- [ ] Mode hors ligne
- [ ] Tests unitaires et d'intégration
- [ ] CI/CD
- [ ] Déploiement sur stores

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📞 Support

Pour toute question ou support :
- Email: [votre-email@example.com]
- Issues GitHub: [lien vers les issues]

---

**Développé avec ❤️ par [Votre Nom]**
