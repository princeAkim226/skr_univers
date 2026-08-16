import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error_handling/error_boundary.dart';
import '../../../../data/services/simple_auth_service.dart';
import '../widgets/auth_page_shell.dart';

class SimpleRegisterPage extends StatefulWidget {
  final String userType;

  const SimpleRegisterPage({
    super.key,
    required this.userType,
  });

  @override
  State<SimpleRegisterPage> createState() => _SimpleRegisterPageState();
}

class _SimpleRegisterPageState extends State<SimpleRegisterPage> with ErrorHandlingMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final _authService = SimpleAuthService();

  bool get isMerchant => widget.userType == AppConstants.userTypeMerchant;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    await executeWithErrorHandling(
      () async {
        if (isMerchant) {
          final response = await _authService.signUpMerchant(
            phoneNumber: _phoneController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            businessName: _businessNameController.text.trim(),
            businessDescription: _businessDescriptionController.text.trim(),
            businessAddress: _businessAddressController.text.trim(),
            businessPhone: _businessPhoneController.text.trim(),
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          );

          if (response.user != null) {
            if (mounted) {
              showSuccess('Compte e-commerçant créé avec succès !');
              context.go('/merchant');
            }
          } else {
            throw Exception('Erreur lors de la création du compte');
          }
        } else {
          final response = await _authService.signUpCustomer(
            phoneNumber: _phoneController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          );

          if (response.user != null) {
            if (mounted) {
              showSuccess('Compte client créé avec succès !');
              context.go('/customer');
            }
          } else {
            throw Exception('Erreur lors de la création du compte');
          }
        }
      },
      onSuccess: () {},
      showErrorSnackBar: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      onBack: () => context.go('/user-type-selection'),
      headerIcon: isMerchant ? Icons.storefront_outlined : Icons.shopping_bag_outlined,
      title: isMerchant ? 'Créer votre boutique' : 'Créer votre compte',
      subtitle: isMerchant
          ? 'Commencez à vendre vos produits en ligne'
          : 'Rejoignez la communauté d\'acheteurs B-Place',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthSectionTitle('Informations personnelles'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: authInputDecoration(
                      label: 'Prénom *',
                      icon: Icons.person_outline_rounded,
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Prénom requis' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: authInputDecoration(
                      label: 'Nom *',
                      icon: Icons.badge_outlined,
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Nom requis' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: authInputDecoration(
                label: 'Téléphone *',
                icon: Icons.phone_outlined,
                hint: '+226 XX XX XX XX',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Téléphone requis';
                if (!_authService.isValidPhoneNumber(value)) {
                  return 'Format invalide (ex: +226 XX XX XX XX)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: authInputDecoration(
                label: 'Email (optionnel)',
                icon: Icons.email_outlined,
                hint: 'vous@exemple.com',
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (!RegExp(r'^[\w+.=-]+@[\w.-]+\.[a-zA-Z]{2,}$')
                      .hasMatch(value.trim())) {
                    return 'Format d\'email invalide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: authInputDecoration(
                label: 'Mot de passe *',
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
                if (value == null || value.isEmpty) return 'Mot de passe requis';
                if (value.length < AppConstants.minPasswordLength) {
                  return 'Min. ${AppConstants.minPasswordLength} caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: authInputDecoration(
                label: 'Confirmer le mot de passe *',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => setState(
                    () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Confirmation requise';
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
            if (isMerchant) ...[
              const SizedBox(height: 22),
              const AuthSectionTitle('Informations entreprise'),
              const SizedBox(height: 14),
              TextFormField(
                controller: _businessNameController,
                decoration: authInputDecoration(
                  label: 'Nom de l\'entreprise *',
                  icon: Icons.storefront_outlined,
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _businessDescriptionController,
                maxLines: 3,
                decoration: authInputDecoration(
                  label: 'Description *',
                  icon: Icons.description_outlined,
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Description requise' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _businessAddressController,
                maxLines: 2,
                decoration: authInputDecoration(
                  label: 'Adresse *',
                  icon: Icons.location_on_outlined,
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Adresse requise' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _businessPhoneController,
                keyboardType: TextInputType.phone,
                decoration: authInputDecoration(
                  label: 'Téléphone entreprise *',
                  icon: Icons.phone_outlined,
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Téléphone requis' : null,
              ),
            ],
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: isMerchant ? 'Créer ma boutique' : 'Créer mon compte',
              loading: isLoading,
              onPressed: _handleRegister,
              color: isMerchant ? AppTheme.secondaryColor : AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Vous avez déjà un compte ? ',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 13.5,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
