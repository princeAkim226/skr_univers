import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error_handling/error_boundary.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/phone_auth_service.dart';
import '../widgets/login_error_overlay.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with ErrorHandlingMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final _authService = AuthService();
  final _phoneAuthService = PhoneAuthService();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await executeWithErrorHandling(
      () async {
        // Rechercher l'utilisateur par numéro de téléphone dans la table users centralisée
        final phoneNumber = _phoneAuthService.formatPhoneNumber(_phoneController.text.trim());
        final phoneNumberWithoutPrefix = _phoneController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
        
        // Chercher dans la table users avec le numéro exact d'abord
        var userResponse = await _phoneAuthService.supabase
            .from('users')
            .select('*')
            .eq('phone_number', phoneNumberWithoutPrefix)
            .maybeSingle();
        
        // Si pas trouvé, essayer avec le format complet
        if (userResponse == null) {
          userResponse = await _phoneAuthService.supabase
              .from('users')
              .select('*')
              .eq('phone_number', phoneNumber)
              .maybeSingle();
        }
        
        if (userResponse == null) {
          throw Exception('Aucun compte trouvé avec ce numéro de téléphone');
        }
        
        // Vérifier si l'utilisateur a un email
        final userEmail = userResponse['email'];
        
        if (userEmail == null || userEmail.isEmpty) {
          // Connexion directe avec le numéro de téléphone (sans email)
          final response = await _phoneAuthService.supabase.auth.signInWithPassword(
            phone: userResponse['phone_number'],
            password: _passwordController.text,
          );
          
          if (response.user != null) {
            if (mounted) {
              showSuccess('Connexion réussie !');
              
              // Rediriger selon le type d'utilisateur
              final userType = userResponse['user_type'];
              if (userType == 'merchant') {
                context.go('/merchant');
              } else {
                context.go('/customer');
              }
            }
          } else {
            throw Exception('Mot de passe incorrect');
          }
        } else {
          // Connexion classique avec email
          final response = await _authService.signIn(
            email: userEmail,
            password: _passwordController.text,
          );
          
          if (response.user != null) {
            if (mounted) {
              showSuccess('Connexion réussie !');
              
              // Rediriger selon le type d'utilisateur
              final userType = userResponse['user_type'];
              if (userType == 'merchant') {
                context.go('/merchant');
              } else {
                context.go('/customer');
              }
            }
          } else {
            throw Exception('Mot de passe incorrect');
          }
        }
      },
      onSuccess: () {
        // Connexion réussie
      },
      showErrorSnackBar: false, // Désactiver le SnackBar d'erreur
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: LoginErrorOverlayWidget(
        errorMessage: errorMessage,
        onRetry: () => clearError(),
        onCreateAccount: () {
          clearError();
          context.go('/user-type-selection');
        },
        onDismiss: () => clearError(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                const SizedBox(height: 40),
                
                // Logo et titre
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.shopping_bag,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Connexion',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connectez-vous à votre compte',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Formulaire
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+226 XX XX XX XX',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    if (!_phoneAuthService.isValidPhoneNumber(value)) {
                      return 'Format de numéro invalide';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (value.length < AppConstants.minPasswordLength) {
                      return 'Le mot de passe doit contenir au moins ${AppConstants.minPasswordLength} caractères';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implémenter la récupération de mot de passe
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité à venir'),
                        ),
                      );
                    },
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Bouton de connexion
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Connexion...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Séparateur
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Bouton d'inscription
                OutlinedButton(
                  onPressed: () => context.go('/user-type-selection'),
                  child: const Text('Créer un compte'),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 