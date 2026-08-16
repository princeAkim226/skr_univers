import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageService {
  static const int maxImageSize = 1024; // Taille maximale en pixels
  static const int quality = 85; // Qualité de compression (0-100)
  static const int maxFileSize = 2 * 1024 * 1024; // 2MB max

  // Compresser et redimensionner une image
  static Future<File> compressAndResizeImage(File imageFile) async {
    try {
      // Lire l'image
      final bytes = await imageFile.readAsBytes();
      
      // Vérifier la taille du fichier
      if (bytes.length > maxFileSize) {
        throw Exception('L\'image est trop volumineuse. Taille maximale: 2MB');
      }

      // Créer un répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      final fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = File(path.join(tempDir.path, fileName));

      // Simuler la compression (dans une vraie app, utiliser image package)
      // Ici on copie simplement le fichier pour la démo
      await compressedFile.writeAsBytes(bytes);

      return compressedFile;
    } catch (e) {
      throw Exception('Erreur lors de la compression.');
    }
  }

  // Obtenir une image depuis la galerie
  static Future<File?> pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxImageSize.toDouble(),
        maxHeight: maxImageSize.toDouble(),
        imageQuality: quality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Impossible de sélectionner l’image. Réessayez.');
    }
  }

  // Obtenir une image depuis l'appareil photo
  static Future<File?> pickImageFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxImageSize.toDouble(),
        maxHeight: maxImageSize.toDouble(),
        imageQuality: quality,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la prise de photo.');
    }
  }

  // Afficher un dialogue de sélection d'image
  static Future<File?> showImagePickerDialog(BuildContext context) async {
    return await showModalBottomSheet<File>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galerie'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await pickImageFromGallery();
                  if (file != null) {
                    Navigator.of(context).pop(file);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Appareil photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await pickImageFromCamera();
                  if (file != null) {
                    Navigator.of(context).pop(file);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Créer un widget d'image optimisé
  static Widget buildOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? 
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
      },
      errorBuilder: (context, error, stackTrace) {
        // Permet de diagnostiquer rapidement CORS/403/404 côté navigateur.
        // (On log uniquement pour dev/debug.)
        // ignore: avoid_print
        print('ImageService.buildOptimizedImage failed: $imageUrl => $error');
        return errorWidget ?? 
          Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
            ),
          );
      },
    );
  }

  // Créer un widget d'image circulaire optimisé
  static Widget buildCircularImage({
    required String imageUrl,
    required double radius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Use Image.network with errorBuilder inside a ClipOval instead of
    // CircleAvatar.backgroundImage (NetworkImage) which can throw uncaught
    // framework errors on image load failures (e.g. 404). This prevents the
    // global ErrorBoundary from showing a full-screen error for simple
    // network image problems.
    final double size = radius * 2;

    if (imageUrl.isEmpty) {
      return ClipOval(
        child: Container(
          width: size,
          height: size,
          color: Colors.grey[200],
          child: placeholder ?? Icon(Icons.person, size: radius, color: Colors.grey[400]),
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return placeholder ??
                Container(
                  width: size,
                  height: size,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
          },
          errorBuilder: (context, error, stackTrace) {
            // Log minimal info but avoid throwing so the ErrorBoundary isn't triggered
            // for expected network failures like 404.
            // Developers can still see the error in console while users see a placeholder.
            // ignore: avoid_print
            print('ImageService.buildCircularImage - failed to load image: $error');
            return errorWidget ??
                Container(
                  width: size,
                  height: size,
                  color: Colors.grey[200],
                  child: Icon(Icons.person, size: radius, color: Colors.grey[400]),
                );
          },
        ),
      ),
    );
  }

  // Valider une image
  static Future<bool> validateImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      // Vérifier la taille du fichier
      if (bytes.length > maxFileSize) {
        return false;
      }

      // Vérifier le format (simplifié)
      final extension = path.extension(imageFile.path).toLowerCase();
      final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      
      return validExtensions.contains(extension);
    } catch (e) {
      return false;
    }
  }

  // Obtenir la taille d'un fichier en format lisible
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Uploader une image vers Supabase Storage (compatible web et mobile)
  static Future<String?> uploadImage(String imagePath, String bucketName) async {
    try {
      if (kIsWeb) {
        // Pour le web, on ne peut pas utiliser File, donc on retourne null
        // et on utilise uploadImageFromXFile à la place
        print('Erreur: uploadImage ne fonctionne pas sur le web. Utilisez uploadImageFromXFile.');
        return null;
      } else {
        // Pour mobile/desktop, utiliser File
        final file = File(imagePath);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '$bucketName/$fileName';
        
        // Lire le fichier
        final bytes = await file.readAsBytes();
        
      // Uploader vers Supabase Storage (utiliser le bucket product-images)
      await Supabase.instance.client.storage
          .from('product-images')
          .uploadBinary(filePath, bytes);
      
      // Obtenir l'URL publique
      final publicUrl = Supabase.instance.client.storage
          .from('product-images')
          .getPublicUrl(filePath);
        
        return publicUrl;
      }
    } catch (e) {
      print('Erreur lors de l\'upload: $e');
      return null;
    }
  }

  // Uploader une image depuis XFile (compatible web et mobile)
  static Future<String?> uploadImageFromXFile(XFile imageFile, String bucketName) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$bucketName/$fileName';
      
      // Lire les bytes depuis XFile
      final bytes = await imageFile.readAsBytes();
      
      // Vérifier la taille du fichier
      if (bytes.length > maxFileSize) {
        throw Exception('L\'image est trop volumineuse. Taille maximale: ${getFileSizeString(maxFileSize)}');
      }
      
      // Uploader vers Supabase Storage (utiliser le bucket product-images)
      await Supabase.instance.client.storage
          .from('product-images')
          .uploadBinary(filePath, bytes);
      
      // Obtenir l'URL publique
      final publicUrl = Supabase.instance.client.storage
          .from('product-images')
          .getPublicUrl(filePath);
      
      print('Image uploadée avec succès: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Erreur lors de l\'upload: $e');
      if (e.toString().contains('Bucket not found')) {
        throw Exception('Le bucket de stockage n\'existe pas. Veuillez contacter l\'administrateur.');
      } else if (e.toString().contains('File too large')) {
        throw Exception('L\'image est trop volumineuse. Taille maximale: ${getFileSizeString(maxFileSize)}');
      } else if (e.toString().contains('row-level security policy') || e.toString().contains('403')) {
        throw Exception('Impossible d’envoyer l’image. Réessayez.');
      } else {
        throw Exception('Impossible d’envoyer l’image. Réessayez.');
      }
    }
  }

  // Créer un placeholder de chargement
  static Widget buildLoadingPlaceholder({
    double? width,
    double? height,
    double borderRadius = 8.0,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Créer un placeholder d'erreur
  static Widget buildErrorPlaceholder({
    double? width,
    double? height,
    double borderRadius = 8.0,
    String? message,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Colors.grey[400],
            size: 32,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
