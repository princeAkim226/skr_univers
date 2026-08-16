import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../data/services/story_service.dart';
import 'story_viewer.dart';

class StoriesWidget extends StatefulWidget {
  const StoriesWidget({super.key});

  @override
  State<StoriesWidget> createState() => _StoriesWidgetState();
}

class _StoriesWidgetState extends State<StoriesWidget> {
  final StoryService _storyService = StoryService();
  Map<String, List<Map<String, dynamic>>> _groupedStories = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  // Méthode pour rafraîchir les stories
  Future<void> refreshStories() async {
    await _loadStories();
  }

  Future<void> _loadStories() async {
    try {
      setState(() => _isLoading = true);
      
      // Récupérer les vraies stories depuis la base de données
      final stories = await _storyService.getActiveStories();
      
      // Grouper les stories par e-commerçant
      final Map<String, List<Map<String, dynamic>>> groupedStories = {};
      
      for (final story in stories) {
        final merchantId = story['merchant_id']?.toString() ?? 'unknown';
        groupedStories.putIfAbsent(merchantId, () => <Map<String, dynamic>>[]).add(story);
      }
      
      // Trier les stories de chaque marchand par date de création
      groupedStories.forEach((merchantId, merchantStories) {
        merchantStories.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(1970);
          final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(1970);
          return dateA.compareTo(dateB);
        });
      });
      
      setState(() {
        _groupedStories = groupedStories;
        _isLoading = false;
      });
    } catch (e) {
      ErrorHandler.logError(e, context: 'StoriesWidget._loadStories');
      setState(() => _isLoading = false);
      
      // En cas d'erreur, ne pas afficher de SnackBar pour éviter de spammer
      // L'interface affichera simplement "Aucune story disponible"
      // Les erreurs sont loggées pour le débogage
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Ne pas polluer l'accueil avec un état vide
    if (_groupedStories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _groupedStories.length,
            itemBuilder: (context, index) {
              final merchantId = _groupedStories.keys.elementAt(index);
              final merchantStories = _groupedStories[merchantId] ?? const <Map<String, dynamic>>[];
              return _buildGroupedStoryCircle(merchantStories);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedStoryCircle(List<Map<String, dynamic>> merchantStories) {
    if (merchantStories.isEmpty) return const SizedBox.shrink();
    
    final firstStory = merchantStories.first;
    final merchant = firstStory['merchant'];
    final merchantName = merchant?['business_name'] ?? 'Marchand';
    final images = firstStory['images'] as List<dynamic>? ?? [];
    final hasImage = images.isNotEmpty;
    final imageUrl = hasImage ? images.first.toString() : null;
    final storyCount = merchantStories.length;
    
    return GestureDetector(
      onTap: () => _openGroupedStories(merchantStories),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            // Cercle principal avec indicateur de progression
            Stack(
              children: [
                // Cercle de fond
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasImage
                        ? null
                        : LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryLightColor,
                            ],
                          ),
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: hasImage
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.primaryColor,
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              );
                            },
                          )
                        : const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                  ),
                ),
                
                // Indicateur de progression (comme WhatsApp)
                if (storyCount > 1)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '$storyCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Nom du marchand
            Text(
              merchantName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }


  void _openGroupedStories(List<Map<String, dynamic>> merchantStories) {
    if (merchantStories.isEmpty) return;
    
    try {
      // Incrémenter le compteur de vues pour la première story
      final storyId = merchantStories.first['id']?.toString();
      if (storyId != null) {
        _storyService.incrementViewCount(storyId).catchError((e) {
          ErrorHandler.logError(e, context: 'StoriesWidget._openGroupedStories - incrementViewCount');
        });
      }
      
      // Ouvrir le viewer de stories avec auto-avancement
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => StoryViewer(
            stories: merchantStories,
            initialIndex: 0,
            onComplete: () => Navigator.pop(context),
          ),
          fullscreenDialog: true,
        ),
      );
    } catch (e) {
      ErrorHandler.logError(e, context: 'StoriesWidget._openGroupedStories');
      if (mounted) {
        ErrorHandler.showError(context, e, showAsDialog: false);
      }
    }
  }
}

