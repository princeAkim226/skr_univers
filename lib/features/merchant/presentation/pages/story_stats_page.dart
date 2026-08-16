import 'package:flutter/material.dart';
import '../../../../data/services/story_service.dart';
import '../../../../core/widgets/styled_app_bar.dart';

class StoryStatsPage extends StatefulWidget {
  const StoryStatsPage({super.key});

  @override
  State<StoryStatsPage> createState() => _StoryStatsPageState();
}

class _StoryStatsPageState extends State<StoryStatsPage> {
  final StoryService _storyService = StoryService();
  
  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;
  
  // Statistiques globales
  int _totalViews = 0;
  int _activeStories = 0;
  int _expiredStories = 0;
  int _totalStories = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() => _isLoading = true);
      
      // Récupérer toutes les stories du marchand
      final stories = await _storyService.getMyStories();
      
      // Calculer les statistiques
      int totalViews = 0;
      int activeCount = 0;
      int expiredCount = 0;
      
      for (var story in stories) {
        final viewCount = story['view_count'] ?? 0;
        totalViews += viewCount as int;
        
        final expiresAt = story['expires_at']?.toString();
        if (expiresAt != null) {
          try {
            final expiryDate = DateTime.parse(expiresAt);
            if (DateTime.now().isAfter(expiryDate)) {
              expiredCount++;
            } else if (story['is_active'] == true) {
              activeCount++;
            }
          } catch (e) {
            // Ignorer les erreurs de parsing
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _stories = stories;
          _totalViews = totalViews;
          _activeStories = activeCount;
          _expiredStories = expiredCount;
          _totalStories = stories.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des statistiques: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StyledAppBar(
        title: 'Statistiques des Stories',
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques globales
                    _buildStatsOverview(),
                    const SizedBox(height: 24),
                    
                    // Liste des stories avec leurs statistiques
                    const Text(
                      'Détails par Story',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_stories.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
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
                            ],
                          ),
                        ),
                      )
                    else
                      ..._stories.map((story) => _buildStoryStatCard(story)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue d\'ensemble',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total de vues',
                value: _totalViews.toString(),
                icon: Icons.visibility,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Stories actives',
                value: _activeStories.toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Stories expirées',
                value: _expiredStories.toString(),
                icon: Icons.schedule,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Total stories',
                value: _totalStories.toString(),
                icon: Icons.auto_stories,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryStatCard(Map<String, dynamic> story) {
    final String title = story['title']?.toString() ?? 'Story sans titre';
    final int viewCount = story['view_count'] ?? 0;
    final String? createdAt = story['created_at']?.toString();
    final String? expiresAt = story['expires_at']?.toString();
    final bool isActive = story['is_active'] ?? false;
    final List<dynamic> images = story['images'] ?? [];
    final String? imageUrl = images.isNotEmpty ? images.first.toString() : null;
    
    // Vérifier si la story est expirée
    bool isExpired = false;
    if (expiresAt != null) {
      try {
        final expiryDate = DateTime.parse(expiresAt);
        isExpired = DateTime.now().isAfter(expiryDate);
      } catch (e) {
        isExpired = false;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image miniature
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            const SizedBox(width: 12),
            
            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.orange.withOpacity(0.2)
                              : (isActive
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isExpired
                              ? 'Expiré'
                              : (isActive ? 'Actif' : 'Inactif'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isExpired
                                ? Colors.orange[800]
                                : (isActive
                                    ? Colors.green[800]
                                    : Colors.grey[800]),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Créée: ${_formatDate(createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

