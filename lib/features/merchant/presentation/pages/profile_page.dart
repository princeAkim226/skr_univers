import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/image_service.dart';
import '../../../../data/services/profile_service.dart';
import '../../../../data/services/auth_service.dart';

class MerchantProfilePage extends StatefulWidget {
  const MerchantProfilePage({super.key});

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _isEditing = false;
  String? _businessImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessDescriptionController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
      final profile = await _profileService.getMerchantProfile();
      if (!mounted) return;
      setState(() {
        _businessNameController.text =
            (profile?['business_name'] ?? '').toString();
        _businessDescriptionController.text =
            (profile?['business_description'] ?? '').toString();
        _businessPhoneController.text =
            (profile?['business_phone'] ?? '').toString();
        _businessAddressController.text =
            (profile?['business_address'] ?? '').toString();
        _businessImage = profile?['business_image']?.toString();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showError(context, e);
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Logo / photo boutique',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: const Text('Galerie'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUpload(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: const Text('Appareil photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUpload(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);
      final url = await _profileService.uploadBusinessImageFromXFile(picked);
      if (!mounted) return;
      setState(() {
        _businessImage = url;
        _isUploadingPhoto = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image boutique mise à jour'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ErrorHandler.showError(context, e);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _isSaving = true);
      await _profileService.updateMerchantProfile(
        businessName: _businessNameController.text.trim(),
        businessDescription:
            _businessDescriptionController.text.trim().isEmpty
                ? null
                : _businessDescriptionController.text.trim(),
        businessPhone: _businessPhoneController.text.trim().isEmpty
            ? null
            : _businessPhoneController.text.trim(),
        businessAddress: _businessAddressController.text.trim().isEmpty
            ? null
            : _businessAddressController.text.trim(),
        businessImage: _businessImage,
      );
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadProfile();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ErrorHandler.showError(context, e);
    }
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment quitter votre session ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (result == true) {
      await _authService.signOut();
      if (mounted) context.go('/user-type-selection');
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
          Icon(icon, color: AppTheme.primaryColor.withValues(alpha: 0.85)),
      filled: true,
      fillColor: const Color(0xFFF3F7F3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final name = _businessNameController.text.trim().isEmpty
        ? 'Ma boutique'
        : _businessNameController.text.trim();

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F4),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, top + 12, 20, 64),
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
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'B-Place',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _isEditing = !_isEditing),
                        icon: Icon(
                          _isEditing
                              ? Icons.close_rounded
                              : Icons.edit_rounded,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _showLogoutDialog,
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Profil e-commerçant',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -52),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                width: 118,
                                height: 118,
                                child: CircularProgressIndicator(strokeWidth: 3),
                              )
                            : ImageService.buildCircularImage(
                                imageUrl: _businessImage ?? '',
                                radius: 59,
                                placeholder: CircleAvatar(
                                  radius: 59,
                                  backgroundColor: const Color(0xFFE8F2E8),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    size: 54,
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                errorWidget: CircleAvatar(
                                  radius: 59,
                                  backgroundColor: const Color(0xFFE8F2E8),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    size: 54,
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap:
                              _isUploadingPhoto ? null : _showImageSourceSheet,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed:
                        _isUploadingPhoto ? null : _showImageSourceSheet,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: Text(
                      (_businessImage == null || _businessImage!.isEmpty)
                          ? 'Ajouter un logo'
                          : 'Changer le logo',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations boutique',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _businessNameController,
                            enabled: _isEditing,
                            decoration: _fieldDecoration(
                              'Nom de l\'entreprise *',
                              Icons.store_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le nom de l\'entreprise est requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _businessDescriptionController,
                            enabled: _isEditing,
                            maxLines: 3,
                            decoration: _fieldDecoration(
                              'Description',
                              Icons.notes_outlined,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _businessPhoneController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.phone,
                            decoration: _fieldDecoration(
                              'Téléphone',
                              Icons.phone_outlined,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _businessAddressController,
                            enabled: _isEditing,
                            maxLines: 2,
                            decoration: _fieldDecoration(
                              'Adresse',
                              Icons.location_on_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Enregistrer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
