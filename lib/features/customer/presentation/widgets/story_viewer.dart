import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/messaging_service.dart';
import '../../../../data/services/subscription_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoryViewer extends StatefulWidget {
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  final VoidCallback? onComplete;

  const StoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    this.onComplete,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  int _currentStoryIndex = 0;
  int _currentImageIndex = 0;
  bool _isPaused = false;
  Timer? _storyTimer;
  
  final MessagingService _messagingService = MessagingService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentStoryIndex);
    
    _progressController = AnimationController(
      duration: const Duration(seconds: 5), // 5 secondes par story
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_progressController);
    
    _startStoryTimer();
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startStoryTimer() {
    if (_currentStoryIndex >= widget.stories.length) {
      widget.onComplete?.call();
      return;
    }

    final story = widget.stories[_currentStoryIndex];
    final images = story['images'] as List<dynamic>? ?? [];
    
    if (images.isEmpty) {
      _nextStory();
      return;
    }

    _progressController.reset();
    _progressController.forward();
    
    _storyTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isPaused) {
        _nextStory();
      }
    });
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
        _currentImageIndex = 0;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startStoryTimer();
    } else {
      widget.onComplete?.call();
    }
  }


  void _pauseStory() {
    setState(() {
      _isPaused = true;
    });
    _storyTimer?.cancel();
    _progressController.stop();
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
    });
    _startStoryTimer();
  }

  void _openMessaging() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final currentStory = widget.stories[_currentStoryIndex];
    final merchantId = currentStory['merchant_id'];

    // Vérifier si le client est déjà abonné
    final isSubscribed = await _subscriptionService.isSubscribed(
      customerId: user.id,
      merchantId: merchantId,
    );

    if (!isSubscribed) {
      // Demander l'abonnement
      final shouldSubscribe = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('S\'abonner'),
          content: Text(
            'Voulez-vous vous abonner à ${currentStory['merchant']['business_name']} pour pouvoir échanger des messages ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('S\'abonner'),
            ),
          ],
        ),
      );

      if (shouldSubscribe == true) {
        final success = await _subscriptionService.subscribeToMerchant(
          customerId: user.id,
          merchantId: merchantId,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Abonnement réussi ! Vous pouvez maintenant échanger des messages.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        return;
      }
    }

    // Créer ou obtenir la conversation
    final conversationId = await _messagingService.getOrCreateConversation(
      customerId: user.id,
      merchantId: merchantId,
    );

    if (conversationId != null && mounted) {
      // Naviguer vers la messagerie
      context.push('/customer/messaging');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Aucune story disponible'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _pauseStory(),
        onTapUp: (_) => _resumeStory(),
        onTapCancel: () => _resumeStory(),
        child: Stack(
          children: [
            // Stories
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStoryIndex = index;
                  _currentImageIndex = 0;
                });
                _startStoryTimer();
              },
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                return _buildStoryContent(widget.stories[index]);
              },
            ),
            
            // Barre de progression
            _buildProgressBar(),
            
            // En-tête avec informations du marchand
            _buildStoryHeader(),
            
            // Boutons d'action
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: List.generate(widget.stories.length, (index) {
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: index == _currentStoryIndex
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
                    : Container(
                        color: index < _currentStoryIndex
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                      ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStoryHeader() {
    final story = widget.stories[_currentStoryIndex];
    final merchant = story['merchant'];
    
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: merchant['business_image'] != null
                ? NetworkImage(merchant['business_image'])
                : null,
            child: merchant['business_image'] == null
                ? Text(
                    merchant['business_name']?.toString().substring(0, 1).toUpperCase() ?? 'M',
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant['business_name'] ?? 'E-commerçant',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatTime(story['created_at']),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: 50,
      right: 16,
      child: Column(
        children: [
          // Bouton messagerie
          FloatingActionButton(
            heroTag: 'story_messaging_${_currentStoryIndex}',
            onPressed: _openMessaging,
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.chat, color: Colors.white),
          ),
          const SizedBox(height: 16),
          // Bouton partage
          FloatingActionButton(
            heroTag: 'story_share_${_currentStoryIndex}',
            onPressed: () {
              // TODO: Implémenter le partage
            },
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.share, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent(Map<String, dynamic> story) {
    final images = story['images'] as List<dynamic>? ?? [];
    
    if (images.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Text(
            'Aucune image',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Image principale
        PageView.builder(
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Image.network(
              images[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                );
              },
            );
          },
        ),
        
        // Overlay avec texte
        Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (story['title'] != null)
                Text(
                  story['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              if (story['description'] != null)
                Text(
                  story['description'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Indicateur d'images multiples
        if (images.length > 1)
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}min';
      } else {
        return 'Maintenant';
      }
    } catch (e) {
      return '';
    }
  }
}
