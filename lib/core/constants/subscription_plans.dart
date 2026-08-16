/// Constantes pour les plans d'abonnement des e-commerçants
class SubscriptionPlans {
  // Types de plans
  static const String simple = 'simple';
  static const String pro = 'pro';
  static const String premium = 'premium';

  // Durées en jours par plan
  static int getDurationInDays(String planType) {
    switch (planType) {
      case simple:
        return 7; // 1 semaine
      case pro:
        return 30; // 1 mois
      case premium:
        return 90; // 3 mois
      default:
        return 7;
    }
  }

  // Avantages par plan
  static const Map<String, List<String>> planBenefits = {
    simple: [
      'Gestion de base des produits',
      'Création de stories',
      'Messagerie avec les clients',
    ],
    pro: [
      'Tous les avantages Simple',
      'Apparition dans la liste des e-commerçants',
      'Statistiques avancées',
      'Validité de 1 mois',
    ],
    premium: [
      'Tous les avantages Pro',
      'Priorité dans la liste des e-commerçants',
      'Support prioritaire',
      'Analytics avancés',
      'Validité de 3 mois',
    ],
  };

  // Vérifier si un plan peut apparaître dans la liste des e-commerçants
  static bool canAppearInMerchantList(String planType) {
    return planType == pro || planType == premium;
  }

  // Obtenir le nom d'affichage du plan
  static String getDisplayName(String planType) {
    switch (planType) {
      case simple:
        return 'Simple';
      case pro:
        return 'Pro';
      case premium:
        return 'Premium';
      default:
        return 'Simple';
    }
  }

  // Obtenir la description du plan
  static String getDescription(String planType) {
    switch (planType) {
      case simple:
        return 'Plan simple pour démarrer votre activité en ligne';
      case pro:
        return 'Plan professionnel avec visibilité accrue (1 mois)';
      case premium:
        return 'Plan premium avec priorité maximale (3 mois)';
      default:
        return 'Plan simple';
    }
  }

  // Obtenir le prix du plan en FCFA
  static double getPriceInFCFA(String planType) {
    switch (planType) {
      case simple:
        return 600.0; // 600 FCFA - 1 semaine
      case pro:
        return 2000.0; // 2000 FCFA - 1 mois
      case premium:
        return 6000.0; // 6000 FCFA - 3 mois
      default:
        return 600.0;
    }
  }

  // Obtenir le prix du plan en dollars (non utilisé, tous les prix sont en FCFA)
  static double getPriceInUSD(String planType) {
    return 0.0; // Tous les prix sont en FCFA
  }

  // Obtenir le prix suggéré du plan (pour compatibilité)
  static double getSuggestedPrice(String planType) {
    return getPriceInFCFA(planType);
  }

  // Obtenir la devise du plan
  static String getCurrency(String planType) {
    return 'FCFA'; // Tous les plans sont en FCFA
  }

  // Obtenir la durée d'affichage
  static String getDurationDisplay(String planType) {
    switch (planType) {
      case simple:
        return '1 semaine';
      case pro:
        return '1 mois';
      case premium:
        return '3 mois';
      default:
        return '1 semaine';
    }
  }
}

/// Constantes pour les abonnements publicitaires
class AdSubscriptionPlans {
  // Prix de l'abonnement publicitaire en FCFA par mois
  static const double monthlyPriceFCFA = 25000.0; // 25 000 FCFA par mois

  // Durée par défaut (1 mois)
  static const int defaultDurationInDays = 30;

  // Obtenir le prix mensuel
  static double getMonthlyPrice() {
    return monthlyPriceFCFA;
  }

  // Obtenir la durée en jours
  static int getDurationInDays() {
    return defaultDurationInDays;
  }
}

