import 'package:flutter/material.dart';

class StoryViewerPage extends StatefulWidget {
  final Map<String, dynamic> story;
  final List<Map<String, dynamic>> allStories;
  final int initialIndex;

  const StoryViewerPage({
    super.key,
    required this.story,
    required this.allStories,
    required this.initialIndex,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  int _currentIndex = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Debug: Afficher les données de la story
    print('Story data: ${widget.story}');
    print('Created at type: ${widget.story['created_at'].runtimeType}');
    print('Created at value: ${widget.story['created_at']}');
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));

    _startProgress();
  }

  void _startProgress() {
    if (!_isPaused) {
      _progressController.forward();
    }
  }

  void _pauseProgress() {
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
  }

  void _resumeProgress() {
    setState(() {
      _isPaused = false;
    });
    _progressController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.allStories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image de fond
          Positioned.fill(
            child: _buildStoryImage(),
          ),
          
          // Overlay sombre
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Barre de progression
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: List.generate(widget.allStories.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentIndex
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: index == _currentIndex
                            ? AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return LinearProgressIndicator(
                                    value: _progressAnimation.value,
                                    backgroundColor: Colors.transparent,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  );
                                },
                              )
                            : null,
                      ),
                    );
                  }),
                ),
                
                // Indicateur de story actuelle (comme WhatsApp)
                if (widget.allStories.length > 1) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1}/${widget.allStories.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // En-tête avec bouton retour
          Positioned(
            top: widget.allStories.length > 1 ? 90 : 60,
            left: 16,
            right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.story['merchant']['business_name'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.story['merchant']?['business_name'] ?? 'Marchand',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.allStories.length > 1) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${widget.allStories.length} stories',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _formatTimeAgo(widget.story['created_at']),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Implémenter le menu des options
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Options')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Zone de tap pour navigation
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _previousStory,
                    onTapDown: (_) => _pauseProgress(),
                    onTapUp: (_) => _resumeProgress(),
                    onTapCancel: () => _resumeProgress(),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _nextStory,
                    onTapDown: (_) => _pauseProgress(),
                    onTapUp: (_) => _resumeProgress(),
                    onTapCancel: () => _resumeProgress(),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu de la story
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.story['title']?.toString() ?? 'Story',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.story['description']?.toString() ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Boutons d'action
          Positioned(
            bottom: 40,
            right: 16,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    // TODO: Implémenter le like
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Liked!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    // TODO: Implémenter le partage
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Partagé!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryImage() {
    final images = widget.story['images'];
    String? imageUrl;
    
    if (images is List && images.isNotEmpty) {
      imageUrl = images.first.toString();
    }
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: Icon(
            Icons.image,
            color: Colors.white,
            size: 100,
          ),
        ),
      );
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[800],
          child: const Center(
            child: Icon(
              Icons.image,
              color: Colors.white,
              size: 100,
            ),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(dynamic dateTime) {
    DateTime parsedDate;
    
    if (dateTime is String) {
      try {
        parsedDate = DateTime.parse(dateTime);
      } catch (e) {
        return 'il y a un moment';
      }
    } else if (dateTime is DateTime) {
      parsedDate = dateTime;
    } else {
      return 'il y a un moment';
    }
    
    final now = DateTime.now();
    final difference = now.difference(parsedDate);
    
    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes}min';
    } else {
      return 'à l\'instant';
    }
  }
}
