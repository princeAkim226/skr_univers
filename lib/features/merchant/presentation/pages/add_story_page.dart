import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/services/story_service.dart';

class AddStoryPage extends StatefulWidget {
  const AddStoryPage({super.key});

  @override
  State<AddStoryPage> createState() => _AddStoryPageState();
}

class _AddStoryPageState extends State<AddStoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '24');
  
  bool _loading = false;
  List<String> _images = [];
  int _durationHours = 24;

  final _service = StoryService();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagsCtrl.dispose();
    _locationCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();
      
      if (pickedFiles.isEmpty) return;

      setState(() => _loading = true);
      
      for (final file in pickedFiles) {
        final ext = path.extension(file.path);
        final uuid = const Uuid().v4();
        final storagePath = 'stories/$uuid$ext';
        
        // Upload to Supabase Storage
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
            
        setState(() {
          _images.add(url);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout des images: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins une image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final tags = _tagsCtrl.text.trim().isEmpty 
          ? <String>[]
          : _tagsCtrl.text.trim().split(',').map((e) => e.trim()).toList();

      await _service.createStory(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        images: _images,
        tags: tags,
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        durationHours: _durationHours,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story créée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une Story'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Publier'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Images de la Story',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_images.isEmpty)
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 32),
                                  SizedBox(height: 8),
                                  Text('Ajouter des images'),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _images.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _images.length) {
                                return GestureDetector(
                                  onTap: _pickImages,
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        style: BorderStyle.solid,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add, size: 24),
                                          SizedBox(height: 4),
                                          Text('Ajouter', style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Container(
                                width: 120,
                                margin: EdgeInsets.only(right: index < _images.length - 1 ? 8 : 0),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _images[index],
                                        height: 120,
                                        width: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _images.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Titre
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titre de la Story *',
                  hintText: 'Ex: Promotion spéciale, Nouveautés...',
                ),
                validator: (v) => v?.trim().isEmpty == true ? 'Titre requis' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Décrivez votre story...',
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 16),
              
              // Tags
              TextFormField(
                controller: _tagsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tags (séparés par des virgules)',
                  hintText: 'Ex: promotion, nouveauté, offre',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Localisation
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Localisation (optionnel)',
                  hintText: 'Ex: Ouagadougou, Burkina Faso',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Durée
              DropdownButtonFormField<int>(
                value: _durationHours,
                decoration: const InputDecoration(
                  labelText: 'Durée d\'affichage',
                ),
                items: const [
                  DropdownMenuItem(value: 6, child: Text('6 heures')),
                  DropdownMenuItem(value: 12, child: Text('12 heures')),
                  DropdownMenuItem(value: 24, child: Text('24 heures')),
                  DropdownMenuItem(value: 48, child: Text('48 heures')),
                  DropdownMenuItem(value: 72, child: Text('72 heures')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _durationHours = v);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
