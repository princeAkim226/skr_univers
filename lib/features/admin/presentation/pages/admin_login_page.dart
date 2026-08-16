import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/simple_auth_service.dart';
import '../../../auth/presentation/widgets/auth_page_shell.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = SimpleAuthService();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final identifier = _identifierController.text.trim();
      final password = _passwordController.text;
      final loginId = identifier.toLowerCase() == 'admin'
          ? 'admin@bplace.local'
          : identifier;

      if (loginId.contains('@')) {
        await Supabase.instance.client.auth.signInWithPassword(
          email: loginId,
          password: password,
        );
      } else {
        await _authService.signIn(
          phoneNumber: loginId,
          password: password,
        );
      }

      final isAdmin = await AuthService().isCurrentUserAdmin();
      if (!isAdmin) {
        await AuthService().signOut();
        if (!mounted) return;
        ErrorHandler.showError(
          context,
          null,
          customMessage:
              'Ce compte n’a pas accès à la plateforme d’administration.',
        );
        return;
      }

      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 400 ? width - 32 : 360.0;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF43A047),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SizedBox(
              width: cardWidth,
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 24),
                children: [
                  const Text(
                    'Admin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Administration',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Plateforme distincte de l’app Business Place',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    elevation: 10,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const AuthSectionTitle('Connexion admin'),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: authInputDecoration(
                                label: 'Téléphone ou email',
                                icon: Icons.person_outline,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Identifiant obligatoire';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              decoration: authInputDecoration(
                                label: 'Mot de passe',
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Mot de passe obligatoire';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                child: Text(
                                  _loading
                                      ? 'Connexion…'
                                      : 'Entrer dans l’admin',
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Cette plateforme n’est pas l’application mobile, ni sa version web.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
