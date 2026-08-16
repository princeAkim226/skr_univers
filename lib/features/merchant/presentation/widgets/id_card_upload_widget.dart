import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skr_univers/core/theme/app_theme.dart';

class IdCardUploadWidget extends StatefulWidget {
  final String? frontImage;
  final String? backImage;
  final String? idCardType;
  final Function(String? frontImage, String? backImage, String? idCardType) onChanged;
  final bool isRequired;

  const IdCardUploadWidget({
    super.key,
    this.frontImage,
    this.backImage,
    this.idCardType,
    required this.onChanged,
    this.isRequired = true,
  });

  @override
  State<IdCardUploadWidget> createState() => _IdCardUploadWidgetState();
}

class _IdCardUploadWidgetState extends State<IdCardUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  
  String? _frontImage;
  String? _backImage;
  String? _selectedIdCardType;
  bool _isUploading = false;

  final List<String> _idCardTypes = [
    'CNI (Carte Nationale d\'Identité)',
    'Passeport',
    'Permis de conduire',
    'Carte de résident',
  ];

  @override
  void initState() {
    super.initState();
    _frontImage = widget.frontImage;
    _backImage = widget.backImage;
    _selectedIdCardType = widget.idCardType;
  }

  Future<void> _pickImage(String side) async {
    try {
      // Pour le web, utiliser la galerie par défaut
      final ImageSource source = ImageSource.gallery;
      
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() {
          _isUploading = true;
        });

        // Simuler un upload (en réalité, on stocke juste le chemin local)
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Stocker le chemin local de l'image (pas d'upload immédiat)
        final String localImagePath = image.path;
        
        setState(() {
          if (side == 'front') {
            _frontImage = localImagePath; // Stocker le chemin local
          } else {
            _backImage = localImagePath; // Stocker le chemin local
          }
        });

        widget.onChanged(_frontImage, _backImage, _selectedIdCardType);
        _showSuccessSnackBar('Image sélectionnée avec succès');
      }
    } catch (e) {
      _showErrorSnackBar('Impossible de sélectionner l’image. Réessayez.');
    } finally {
      setState(() {
        _isUploading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type de pièce d'identité
        Text(
          'Type de pièce d\'identité *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedIdCardType,
          decoration: InputDecoration(
            hintText: 'Sélectionnez le type de pièce',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: _idCardTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedIdCardType = newValue;
            });
            widget.onChanged(_frontImage, _backImage, _selectedIdCardType);
          },
        ),
        const SizedBox(height: 24),

        // Upload recto
        _buildUploadSection(
          title: 'Recto de la pièce d\'identité *',
          image: _frontImage,
          side: 'front',
          icon: Icons.credit_card,
        ),
        const SizedBox(height: 16),

        // Upload verso
        _buildUploadSection(
          title: 'Verso de la pièce d\'identité *',
          image: _backImage,
          side: 'back',
          icon: Icons.credit_card,
        ),

        // Message d'information
        if (widget.isRequired)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.infoColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.infoColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les pièces d\'identité sont nécessaires pour la vérification de votre compte e-commerçant.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.infoColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildUploadSection({
    required String title,
    required String? image,
    required String side,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: image != null ? AppTheme.successColor : AppTheme.textSecondaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: image != null 
                ? AppTheme.successColor.withOpacity(0.05)
                : AppTheme.surfaceColor,
          ),
          child: image != null
              ? _buildImagePreview(image, side)
              : _buildUploadButton(side),
        ),
      ],
    );
  }

  Widget _buildImagePreview(String imagePath, String side) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: kIsWeb 
            ? Image.network(
                imagePath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.surfaceColor,
                    child: Icon(
                      Icons.image,
                      color: AppTheme.successColor,
                      size: 40,
                    ),
                  );
                },
              )
            : Image.file(
                File(imagePath),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.surfaceColor,
                    child: Icon(
                      Icons.image,
                      color: AppTheme.successColor,
                      size: 40,
                    ),
                  );
                },
              ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: const Text(
                  '✓',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _pickImage(side),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton(String side) {
    return InkWell(
      onTap: _isUploading ? null : () => _pickImage(side),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primaryColor,
            style: BorderStyle.solid,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isUploading)
              const CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              )
            else
              Icon(
                Icons.add_a_photo,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            const SizedBox(height: 8),
            Text(
              _isUploading ? 'Upload en cours...' : 'Appuyez pour sélectionner une image',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
