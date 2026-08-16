import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error_handling/error_boundary.dart';
import '../../../../data/services/simple_auth_service.dart';
import '../widgets/auth_page_shell.dart';

class SimpleLoginPage extends StatefulWidget {
  const SimpleLoginPage({super.key});

  @override
  State<SimpleLoginPage> createState() => _SimpleLoginPageState();
}

class _SimpleLoginPageState extends State<SimpleLoginPage> with ErrorHandlingMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  final _authService = SimpleAuthService();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await executeWithErrorHandling(
      () async {
        final response = await _authService.signIn(
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user != null) {
          if (mounted) {
            showSuccess('Connexion réussie !');
            final userType = _authService.userType;
            if (userType == 'merchant') {
              context.go('/merchant');
            } else {
              context.go('/customer');
            }
          }
        }
      },
      onSuccess: () {},
      showErrorSnackBar: true,
    );
  }

  Future<void> _handleForgotPassword() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !_authService.isValidPhoneNumber(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrez votre numéro de téléphone pour réinitialiser'),
        ),
      );
      return;
    }

    await executeWithErrorHandling(
      () async {
        await _authService.resetPasswordByPhone(phone);
        if (mounted) {
          showSuccess(
            'Lien de réinitialisation envoyé (si un compte email est associé).',
          );
        }
      },
      showErrorSnackBar: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      onBack: () => context.go('/user-type-selection'),
      title: 'Bon retour',
      subtitle: 'Connectez-vous avec votre numéro de téléphone',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthSectionTitle('Identifiants'),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: authInputDecoration(
                label: 'Numéro de téléphone',
                icon: Icons.phone_outlined,
                hint: '+226 XX XX XX XX',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre numéro';
                }
                if (!_authService.isValidPhoneNumber(value)) {
                  return 'Format invalide (ex: +226 XX XX XX XX)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: authInputDecoration(
                label: 'Mot de passe',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre mot de passe';
                }
                if (value.length < AppConstants.minPasswordLength) {
                  return 'Min. ${AppConstants.minPasswordLength} caractères';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                child: Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            AuthPrimaryButton(
              label: 'Se connecter',
              loading: isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey.shade300)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: () => context.go('/user-type-selection'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Créer un compte',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
