import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/error_handling/error_handler.dart';

class ImageEditorWidget extends StatefulWidget {
  final String? initialImagePath;
  final Function(String editedImagePath) onImageEdited;

  const ImageEditorWidget({
    super.key,
    this.initialImagePath,
    required this.onImageEdited,
  });

  @override
  State<ImageEditorWidget> createState() => _ImageEditorWidgetState();
}

class _ImageEditorWidgetState extends State<ImageEditorWidget> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  String? _currentImagePath;
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _rotation = 0.0;
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.initialImagePath;
  }

  Future<void> _pickNewImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _currentImagePath = pickedFile.path;
        _resetFilters();
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _rotation = 0.0;
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  Future<void> _saveEditedImage() async {
    if (_currentImagePath == null) return;

    try {
      if (kIsWeb) {
        // Sur le web, on ne peut pas sauvegarder l'image modifiée
        // On retourne simplement le chemin original
        widget.onImageEdited(_currentImagePath!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note: L\'édition d\'images n\'est pas disponible sur le web'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Capturer l'image modifiée (mobile seulement)
      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        // Sauvegarder l'image modifiée
        final editedImagePath = _currentImagePath!.replaceAll('.jpg', '_edited.png');
        final file = File(editedImagePath);
        await file.writeAsBytes(byteData.buffer.asUint8List());
        
        widget.onImageEdited(editedImagePath);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image modifiée sauvegardée avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditeur d\'image'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetFilters,
            tooltip: 'Réinitialiser',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEditedImage,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone d'édition d'image
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: _currentImagePath != null
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..translate(_offset.dx, _offset.dy)
                            ..rotateZ(_rotation)
                            ..scale(_scale),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.matrix([
                              _contrast, 0, 0, 0, _brightness * 255,
                              0, _contrast, 0, 0, _brightness * 255,
                              0, 0, _contrast, 0, _brightness * 255,
                              0, 0, 0, 1, 0,
                            ]),
                            child: Image.file(
                              File(_currentImagePath!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune image sélectionnée',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _pickNewImage,
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('Sélectionner une image'),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Contrôles d'édition
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Luminosité
                  _buildSliderControl(
                    'Luminosité',
                    _brightness,
                    -1.0,
                    1.0,
                    (value) => setState(() => _brightness = value),
                    Icons.brightness_6,
                  ),
                  
                  // Contraste
                  _buildSliderControl(
                    'Contraste',
                    _contrast,
                    0.0,
                    2.0,
                    (value) => setState(() => _contrast = value),
                    Icons.contrast,
                  ),
                  
                  // Rotation
                  _buildSliderControl(
                    'Rotation',
                    _rotation,
                    -3.14,
                    3.14,
                    (value) => setState(() => _rotation = value),
                    Icons.rotate_right,
                  ),
                  
                  // Zoom
                  _buildSliderControl(
                    'Zoom',
                    _scale,
                    0.5,
                    3.0,
                    (value) => setState(() => _scale = value),
                    Icons.zoom_in,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickNewImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Nouvelle image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _saveEditedImage,
                        icon: const Icon(Icons.save),
                        label: const Text('Sauvegarder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: Colors.grey[300],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
