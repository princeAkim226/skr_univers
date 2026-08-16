import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/image_service.dart';
import '../../../../data/services/platform_ad_service.dart';
import '../widgets/admin_shell.dart';

class AdminPlatformAdsPage extends StatefulWidget {
  const AdminPlatformAdsPage({super.key});

  @override
  State<AdminPlatformAdsPage> createState() => _AdminPlatformAdsPageState();
}

class _AdminPlatformAdsPageState extends State<AdminPlatformAdsPage> {
  final PlatformAdService _service = PlatformAdService();
  List<Map<String, dynamic>> _ads = [];
  bool _loading = true;
  bool _tableMissing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _tableMissing = false;
    });
    try {
      final ads = await _service.getAllAdsForAdmin();
      if (!mounted) return;
      setState(() => _ads = ads);
    } catch (e) {
      if (!mounted) return;
      final missing = _isMissingTable(e);
      setState(() => _tableMissing = missing);
      if (!missing) ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isMissingTable(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('pgrst205') ||
        text.contains('42p01') ||
        text.contains('platform_ads') && text.contains('schema cache') ||
        text.contains('could not find the table');
  }

  Future<void> _openEditor({Map<String, dynamic>? ad}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PlatformAdEditor(ad: ad),
    );
    if (saved == true) _load();
  }

  Future<void> _toggle(Map<String, dynamic> ad) async {
    try {
      await _service.updateAd(
        id: ad['id'].toString(),
        isActive: ad['is_active'] != true,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    }
  }

  Future<void> _delete(Map<String, dynamic> ad) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette publicité ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.deleteAd(ad['id'].toString());
      _load();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Pubs B-Place',
      actions: [
        IconButton(
          tooltip: 'Nouvelle publicité',
          onPressed: () => _openEditor(),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tableMissing
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storage_outlined, size: 48, color: Colors.black38),
                        const SizedBox(height: 12),
                        const Text(
                          'Table des pubs B-Place absente',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Dans Supabase → SQL Editor, exécutez le fichier create_platform_ads.sql, puis rechargez cette page.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _ads.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.campaign_outlined, size: 48, color: Colors.black38),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucune publicité propriétaire',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ces pubs s’affichent sur l’accueil, séparément des pubs des boutiques.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _openEditor(),
                          child: const Text('Créer une publicité'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: _ads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ad = _ads[index];
                      final active = ad['is_active'] == true;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                          leading: _adThumb(ad['image_url']?.toString()),
                          title: Text(
                            ad['title']?.toString() ?? 'Sans titre',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            active ? 'Visible sur l’accueil' : 'Masquée',
                            style: TextStyle(
                              color: active
                                  ? AppTheme.primaryDarkColor
                                  : Colors.black54,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: active,
                                onChanged: (_) => _toggle(ad),
                              ),
                              IconButton(
                                onPressed: () => _openEditor(ad: ad),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                onPressed: () => _delete(ad),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _adThumb(String? url) {
    if (url == null || url.isEmpty) {
      return const CircleAvatar(
        backgroundColor: Color(0xFFE8EAE9),
        child: Icon(Icons.campaign_outlined, color: Colors.black45),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const CircleAvatar(
          backgroundColor: Color(0xFFE8EAE9),
          child: Icon(Icons.broken_image_outlined, color: Colors.black45),
        ),
      ),
    );
  }
}

class _PlatformAdEditor extends StatefulWidget {
  final Map<String, dynamic>? ad;

  const _PlatformAdEditor({this.ad});

  @override
  State<_PlatformAdEditor> createState() => _PlatformAdEditorState();
}

class _PlatformAdEditorState extends State<_PlatformAdEditor> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String? _imageUrl;
  XFile? _pickedImage;
  Uint8List? _pickedBytes;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ad = widget.ad;
    if (ad != null) {
      _titleCtrl.text = ad['title']?.toString() ?? '';
      _descCtrl.text = ad['description']?.toString() ?? '';
      _urlCtrl.text = ad['target_url']?.toString() ?? '';
      final existing = ad['image_url']?.toString();
      _imageUrl = (existing == null || existing.isEmpty) ? null : existing;
      _active = ad['is_active'] == true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedImage = image;
      _pickedBytes = bytes;
    });
  }

  void _clearImage() {
    setState(() {
      _pickedImage = null;
      _pickedBytes = null;
      _imageUrl = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String? imageUrl = _imageUrl;
      if (_pickedImage != null) {
        imageUrl = await ImageService.uploadImageFromXFile(
          _pickedImage!,
          AppConstants.productImagesBucket,
        );
        if (imageUrl == null || imageUrl.isEmpty) {
          throw Exception('Impossible d’envoyer la photo. Réessayez.');
        }
      }

      final service = PlatformAdService();
      if (widget.ad == null) {
        await service.createAd(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          imageUrl: imageUrl,
          targetUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
          isActive: _active,
        );
      } else {
        await service.updateAd(
          id: widget.ad!['id'].toString(),
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          imageUrl: imageUrl ?? '',
          targetUrl: _urlCtrl.text.trim(),
          isActive: _active,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.ad == null ? 'Nouvelle publicité B-Place' : 'Modifier la publicité',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Titre obligatoire' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Photo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _imagePicker(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lien (optionnel)',
                  hintText: 'https://…',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Visible sur l’accueil'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePicker() {
    final hasImage = _pickedBytes != null || (_imageUrl != null && _imageUrl!.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _saving ? null : _pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_pickedBytes != null)
                        Image.memory(_pickedBytes!, fit: BoxFit.cover)
                      else
                        Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined, size: 40),
                          ),
                        ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Changer',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.black38),
                        SizedBox(height: 8),
                        Text(
                          'Choisir une photo',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Depuis l’ordinateur ou le téléphone',
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (hasImage)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _saving ? null : _clearImage,
              child: const Text('Retirer la photo'),
            ),
          ),
      ],
    );
  }
}
