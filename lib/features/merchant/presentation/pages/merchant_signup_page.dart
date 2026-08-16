import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skr_univers/core/theme/app_theme.dart';
import 'package:skr_univers/features/merchant/presentation/widgets/id_card_upload_widget.dart';
import 'package:skr_univers/data/services/location_service.dart';
import 'package:skr_univers/data/services/image_service.dart';
import 'package:skr_univers/data/services/simple_auth_service.dart';

class MerchantSignupPage extends StatefulWidget {
  const MerchantSignupPage({super.key});

  @override
  State<MerchantSignupPage> createState() => _MerchantSignupPageState();
}

class _MerchantSignupPageState extends State<MerchantSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _businessCityController = TextEditingController();
  final _phoneController = TextEditingController();

  final LocationService _locationService = LocationService();
  final SimpleAuthService _authService = SimpleAuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Pièces d'identité
  String? _idCardFront;
  String? _idCardBack;
  String? _idCardType;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _businessCityController.dispose();
    _businessDescriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idCardFront == null || _idCardBack == null || _idCardType == null) {
      _showErrorSnackBar('Veuillez sélectionner vos pièces d\'identité');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Inscription avec SimpleAuthService
      final response = await _authService.signUpMerchant(
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
        firstName: _businessNameController.text.split(' ').first,
        lastName: _businessNameController.text.split(' ').length > 1 
            ? _businessNameController.text.split(' ').sublist(1).join(' ')
            : '',
        businessName: _businessNameController.text.trim(),
        businessDescription: _businessDescriptionController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        businessPhone: _businessPhoneController.text.trim(),
      );

      if (response.user != null) {
        // Obtenir la position actuelle (ne pas bloquer si refusée)
        final position = await _locationService.getCurrentPosition();
        
        // Upload des images (ne pas bloquer l'inscription si le bucket n'existe pas)
        String? uploadedFrontImage;
        String? uploadedBackImage;
        bool uploadFailed = false;
        
        try {
          if (_idCardFront != null) {
            final XFile frontFile = XFile(_idCardFront!);
            uploadedFrontImage = await ImageService.uploadImageFromXFile(frontFile, 'product-images');
          }
          if (_idCardBack != null) {
            final XFile backFile = XFile(_idCardBack!);
            uploadedBackImage = await ImageService.uploadImageFromXFile(backFile, 'product-images');
          }
        } catch (e) {
          uploadFailed = true;
          if (mounted) {
            _showErrorSnackBar(
              'Compte créé. Les pièces d\'identité n\'ont pas pu être envoyées (stockage non configuré). Vous pourrez les ajouter plus tard.',
            );
          }
        }
        
        // Mettre à jour le profil e-commerçant avec les informations supplémentaires
        final merchantData = {
          'business_city': _businessCityController.text.trim(),
          'business_email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          'business_country': 'Burkina Faso',
          'id_card_front': uploadedFrontImage,
          'id_card_back': uploadedBackImage,
          'id_card_type': _idCardType,
          'id_card_upload_date': DateTime.now().toIso8601String(),
          'id_card_status': 'pending',
          'latitude': position?.latitude,
          'longitude': position?.longitude,
          'is_verified': false,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await Supabase.instance.client
            .from('merchants')
            .update(merchantData)
            .eq('user_id', response.user!.id);

        if (mounted) {
          if (!uploadFailed) {
            _showSuccessSnackBar('Inscription réussie ! Votre compte sera vérifié sous 24h.');
          }
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Erreur d\'inscription';
        
        if (e.toString().contains('user_already_exists')) {
          errorMessage = 'Ce numéro de téléphone est déjà utilisé. Veuillez vous connecter ou utiliser un autre numéro.';
        } else if (e.toString().contains('Invalid phone')) {
          errorMessage = 'Numéro de téléphone invalide.';
        } else if (e.toString().contains('Password should be at least')) {
          errorMessage = 'Le mot de passe doit contenir au moins 6 caractères.';
        } else if (e.toString().contains('422')) {
          errorMessage = 'Numéro de téléphone déjà utilisé. Veuillez vous connecter ou utiliser un autre numéro.';
        } else {
          errorMessage = 'Impossible de créer le compte. Vérifiez vos informations et réessayez.';
        }
        
        _showErrorSnackBar(errorMessage);
        
        // Si le numéro existe déjà, proposer de se connecter
        if (e.toString().contains('user_already_exists') || e.toString().contains('422')) {
          _showLoginOption();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showLoginOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email déjà utilisé'),
        content: const Text(
          'Cet email est déjà associé à un compte. Voulez-vous vous connecter avec ce compte ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription E-commerçant'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.store,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Créer votre compte e-commerçant',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rejoignez notre plateforme et vendez vos produits',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Informations de connexion
              _buildSectionTitle('Informations de connexion'),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (optionnel)',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.contains('@')) {
                      return 'Veuillez saisir un email valide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe *',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre mot de passe';
                  }
                  if (value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe *',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez confirmer votre mot de passe';
                  }
                  if (value != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Votre numéro de téléphone *',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+226 XX XX XX XX',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre numéro de téléphone';
                  }
                  if (value.length < 8) {
                    return 'Le numéro de téléphone doit contenir au moins 8 chiffres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Informations de l'entreprise
              _buildSectionTitle('Informations de l\'entreprise'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'entreprise *',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir le nom de votre entreprise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone de l\'entreprise',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessAddressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse de l\'entreprise',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessCityController,
                decoration: const InputDecoration(
                  labelText: 'Ville *',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir votre ville';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _businessDescriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description de l\'entreprise',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Upload de pièce d'identité
              _buildSectionTitle('Pièce d\'identité'),
              const SizedBox(height: 16),
              
              IdCardUploadWidget(
                frontImage: _idCardFront,
                backImage: _idCardBack,
                idCardType: _idCardType,
                onChanged: (front, back, type) {
                  setState(() {
                    _idCardFront = front;
                    _idCardBack = back;
                    _idCardType = type;
                  });
                },
                isRequired: true,
              ),
              const SizedBox(height: 32),

              // Bouton d'inscription
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          'Créer mon compte e-commerçant',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Lien vers la connexion
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: RichText(
                    text: TextSpan(
                      text: 'Déjà un compte ? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: 'Se connecter',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
