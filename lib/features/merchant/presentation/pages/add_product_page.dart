import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/location_service.dart';
import '../widgets/image_editor_widget.dart';
import '../widgets/custom_category_dialog.dart';
import '../../../../core/error_handling/error_handler.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  String _habType = 'Maison';
  String _habGoal = 'Vente';
  final _habRoomsCtrl = TextEditingController();
  final _habSurfaceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _origPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '1');
  String _selectedCategory = categories.first.name;
  final List<String> _availableCategories =
      categories.map((c) => c.name).toList();
  bool _loading = false;
  final List<String> _images = [];
  double? _latitude;
  double? _longitude;
  String? _address;

  final _service = ProductService();
  final _locationService = LocationService();

  Future<void> _openImageEditor() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord ajouter des images'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditorWidget(
          initialImagePath: _images.first,
          onImageEdited: (editedPath) {
            setState(() => _images[0] = editedPath);
          },
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _loading = true);

      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _address = _locationService.currentAddress ?? 'Position actuelle';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Position géolocalisée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'obtenir votre position'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Vous devez être connecté pour ajouter des images');
      }

      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isEmpty) return;

      setState(() => _loading = true);

      for (final file in pickedFiles) {
        final ext = path.extension(file.path);
        final safeExt = ext.isEmpty ? '.jpg' : ext;
        final uuid = const Uuid().v4();
        final storagePath = '$uuid$safeExt';

        final bytes = await file.readAsBytes();
        final response = await Supabase.instance.client.storage
            .from(AppConstants.productImagesBucket)
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
              ),
            );

        if (response.isEmpty) {
          throw Exception('Erreur lors de l\'upload de l\'image');
        }

        final url = Supabase.instance.client.storage
            .from(AppConstants.productImagesBucket)
            .getPublicUrl(storagePath);

        setState(() => _images.add(url));
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _habRoomsCtrl.dispose();
    _habSurfaceCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _origPriceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _service.createProduct(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        originalPrice: _origPriceCtrl.text.trim().isEmpty
            ? null
            : double.parse(_origPriceCtrl.text.trim()),
        stockQuantity: int.parse(_stockCtrl.text.trim()),
        category: _selectedCategory,
        images: _images,
        latitude: _latitude,
        longitude: _longitude,
        address: _address,
        propertyGoal: _selectedCategory == 'Habitations' ? _habGoal : null,
        propertyType: _selectedCategory == 'Habitations' ? _habType : null,
        propertyRooms:
            _selectedCategory == 'Habitations' && _habRoomsCtrl.text.isNotEmpty
                ? int.tryParse(_habRoomsCtrl.text.trim())
                : null,
        propertySurface: _selectedCategory == 'Habitations' &&
                _habSurfaceCtrl.text.isNotEmpty
            ? double.tryParse(_habSurfaceCtrl.text.trim())
            : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: AppTheme.primaryColor.withValues(alpha: 0.85),
      ),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.errorColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: Column(
        children: [
          _buildHeader(top),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImagesSection(),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Catégorie',
                      subtitle: 'Choisis le type d’annonce',
                      child: DropdownButtonFormField<String>(
                        value: _availableCategories.contains(_selectedCategory)
                            ? _selectedCategory
                            : null,
                        items: [
                          for (final category in _availableCategories)
                            DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                        ],
                        onChanged: (v) async {
                          if (v == 'Autre') {
                            final customCategory = await showDialog<String>(
                              context: context,
                              builder: (context) =>
                                  const CustomCategoryDialog(),
                            );
                            if (customCategory != null) {
                              setState(() {
                                _selectedCategory = customCategory;
                                if (!_availableCategories
                                    .contains(customCategory)) {
                                  _availableCategories.add(customCategory);
                                }
                              });
                            }
                          } else if (v != null) {
                            setState(() => _selectedCategory = v);
                          }
                        },
                        decoration: _fieldDecoration(
                          label: 'Catégorie',
                          icon: Icons.category_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez sélectionner une catégorie';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_selectedCategory == 'Habitations') ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: 'Bien immobilier',
                        subtitle: 'Détails de l’habitation',
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _habGoal,
                              items: ['Vente', 'Location']
                                  .map(
                                    (g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _habGoal = v ?? 'Vente'),
                              decoration: _fieldDecoration(
                                label: 'Objectif',
                                icon: Icons.sell_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _habType,
                              items: [
                                'Maison',
                                'Terrain',
                                'Magasin',
                                'Résidence',
                                'Appartement',
                              ]
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _habType = v ?? 'Maison'),
                              decoration: _fieldDecoration(
                                label: 'Type de bien',
                                icon: Icons.home_work_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _habRoomsCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDecoration(
                                label: 'Nombre de chambres',
                                icon: Icons.bed_outlined,
                              ),
                              validator: (v) =>
                                  (v == null || int.tryParse(v) == null)
                                      ? 'Nombre invalide'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _habSurfaceCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: _fieldDecoration(
                                label: 'Surface (m²)',
                                icon: Icons.square_foot_outlined,
                                hint: 'Optionnel',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Informations',
                      subtitle: 'Titre et description',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleCtrl,
                            decoration: _fieldDecoration(
                              label: 'Titre',
                              icon: Icons.title_rounded,
                              hint: 'Ex: Maison 4 pièces Ouaga',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Titre requis'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 4,
                            decoration: _fieldDecoration(
                              label: 'Description',
                              icon: Icons.notes_outlined,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Description requise'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Tarif',
                      subtitle: 'Prix affiché aux clients',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceCtrl,
                                  decoration: _fieldDecoration(
                                    label: 'Prix',
                                    icon: Icons.payments_outlined,
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) => (v == null ||
                                          double.tryParse(v) == null)
                                      ? 'Prix invalide'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _origPriceCtrl,
                                  decoration: _fieldDecoration(
                                    label: 'Prix barré',
                                    icon: Icons.local_offer_outlined,
                                    hint: 'Optionnel',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedCategory != 'Habitations') ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _stockCtrl,
                              decoration: _fieldDecoration(
                                label: 'Stock',
                                icon: Icons.inventory_2_outlined,
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  (v == null || int.tryParse(v) == null)
                                      ? 'Stock invalide'
                                      : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!_availableCategories.contains(_selectedCategory) &&
                        _selectedCategory != categories.first.name) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Catégorie: $_selectedCategory',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _buildLocationSection(),
                    const SizedBox(height: 20),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double top) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, top + 4, 16, 20),
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
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'B-Place',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ajouter un produit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_images.length} photo${_images.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return _SectionCard(
      title: 'Photos',
      subtitle: 'Ajoute de belles images de ton produit',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_images.isEmpty)
            GestureDetector(
              onTap: _loading ? null : _pickImages,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ajouter des images',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Galerie · plusieurs photos possibles',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == _images.length) {
                    return GestureDetector(
                      onTap: _loading ? null : _pickImages,
                      child: Container(
                        width: 108,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7F3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE6EEE6)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: AppTheme.primaryColor,
                              size: 28,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ajouter',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final url = _images[index];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          url,
                          width: 108,
                          height: 118,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 108,
                            height: 118,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.remove(url)),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Principale',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _pickImages,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galerie'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _openImageEditor,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Éditer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.45),
                    ),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final hasLocation = _address != null;

    return _SectionCard(
      title: 'Localisation',
      subtitle: 'Aide les clients près de toi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasLocation)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Position enregistrée',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _address!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: _loading ? null : _getCurrentLocation,
            icon: Icon(
              hasLocation ? Icons.refresh_rounded : Icons.my_location_rounded,
            ),
            label: Text(
              hasLocation ? 'Mettre à jour la position' : 'Géolocaliser',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: BorderSide(
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded),
                  SizedBox(width: 10),
                  Text(
                    'Publier le produit',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EEE6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
