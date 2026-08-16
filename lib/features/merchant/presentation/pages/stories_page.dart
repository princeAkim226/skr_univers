import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/vintage_icons.dart';
import '../../../../core/widgets/styled_app_bar.dart';
import '../../../../data/services/story_service.dart';

class MerchantStoriesPage extends StatefulWidget {
  const MerchantStoriesPage({super.key});

  @override
  State<MerchantStoriesPage> createState() => _MerchantStoriesPageState();
}

class _MerchantStoriesPageState extends State<MerchantStoriesPage> {
  final StoryService _storyService = StoryService();
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      setState(() => _isLoading = true);
      
      // Récupérer les stories du marchand connecté
      final stories = await _storyService.getMyStories();
      
      if (mounted) {
        setState(() {
          _stories = stories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des stories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteStory(String storyId) async {
    try {
      await _storyService.deleteStory(storyId);
      await _loadStories(); // Recharger la liste
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _republishStory(String storyId) async {
    try {
      await _storyService.republishStory(storyId: storyId);
      await _loadStories(); // Recharger la liste
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story republiée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la republication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(String storyId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la story'),
        content: Text('Êtes-vous sûr de vouloir supprimer la story "$title" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteStory(storyId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: StyledAppBar(
        title: 'Mes stories',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Créer une story',
            icon: Icon(VintageIcons.merchantAction('Créer une story')),
            onPressed: () => context.push('/merchant/add-story'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStories,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _stories.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_stories,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucune story créée',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Commencez par créer votre première story',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Adapter la disposition selon la largeur de l'écran
                      if (constraints.maxWidth > 600) {
                        // Écrans larges : grille de 2 colonnes
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: _stories.length,
                          itemBuilder: (context, index) {
                            final story = _stories[index];
                            return _buildStoryCard(story);
                          },
                        );
                      } else {
                        // Écrans étroits : liste verticale
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _stories.length,
                          itemBuilder: (context, index) {
                            final story = _stories[index];
                            return _buildStoryCard(story);
                          },
                        );
                      }
                    },
                  ),
      ),
    );
  }

  Widget _buildStoryCard(Map<String, dynamic> story) {
    final String title = story['title']?.toString() ?? 'Story sans titre';
    final String description = story['description']?.toString() ?? '';
    final List<dynamic> images = story['images'] ?? [];
    final String? imageUrl = images.isNotEmpty ? images.first.toString() : null;
    final bool isActive = story['is_active'] ?? false;
    final String createdAt = story['created_at']?.toString() ?? '';
    final int viewCount = story['view_count'] ?? 0;
    final String? expiresAt = story['expires_at']?.toString();
    
    // Vérifier si la story est expirée
    bool isExpired = false;
    if (expiresAt != null) {
      try {
        final expiryDate = DateTime.parse(expiresAt);
        isExpired = DateTime.now().isAfter(expiryDate);
      } catch (e) {
        // Si la date ne peut pas être parsée, on considère qu'elle n'est pas expirée
        isExpired = false;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image de la story
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isExpired 
                            ? Colors.orange 
                            : (isActive ? Colors.green : Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isExpired 
                            ? 'Expiré' 
                            : (isActive ? 'Actif' : 'Inactif'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Informations de la story
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$viewCount vues',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                if (expiresAt != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expire: ${_formatDate(expiresAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Bouton Republier pour les stories expirées
                    if (isExpired) ...[
                      ElevatedButton.icon(
                        onPressed: () => _republishStory(story['id']),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Republier'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Bouton Modifier (seulement si pas expiré)
                    if (!isExpired)
                      TextButton.icon(
                        onPressed: () {
                          // TODO: Implémenter l'édition de story
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité d\'édition à venir'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Modifier'),
                      ),
                    if (!isExpired) const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _showDeleteDialog(story['id'], title),
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}
