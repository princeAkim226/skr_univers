/// Configuration Supabase - permet de gérer plusieurs projets.
///
/// Projet actif actuellement :
/// https://dmmtdmpcguybkshmdhzd.supabase.co
class SupabaseConfig {
  /// true = projet actif (dmmtdmpcguybkshmdhzd)
  /// false = projet précédent (kadmbndujdygbdzleojn)
  static const bool useNewProject = true;

  // --- Projet précédent raaga ---
  static const String _oldUrl = 'https://kadmbndujdygbdzleojn.supabase.co';
  static const String _oldAnonKey = 'sb_publishable_mCt5OGnlK-_OQ30jiRhI2Q_BfO2wG40';

  // --- Projet actif ---
  static const String _newUrl = 'https://dmmtdmpcguybkshmdhzd.supabase.co';
  /// Clé publique (Dashboard > Project Settings > API).
  /// Si l'auth échoue avec "Invalid API key", utilise la clé JWT "anon" (commence par eyJ...).
  static const String _newAnonKey = 'sb_publishable_WbG65xW9lmsbrw8QExnfyw_PmAm-fKr';

  static String get supabaseUrl => useNewProject ? _newUrl : _oldUrl;
  static String get supabaseAnonKey => useNewProject ? _newAnonKey : _oldAnonKey;
}
