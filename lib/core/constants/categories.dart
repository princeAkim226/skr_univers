
class Category {
  final String name;
  final String emoji;
  final String route;

  const Category({
    required this.name,
    required this.emoji,
    required this.route,
  });

  String get slug => route.replaceAll('/', '');
}

const List<Category> categories = [
  Category(name: 'Habitations', emoji: '🏠', route: '/habitations'),
  Category(name: 'Moteurs', emoji: '🚗', route: '/moteurs'),
  Category(name: 'Électroniques', emoji: '📱', route: '/electroniques'),
  Category(name: 'Vêtements', emoji: '👕', route: '/vetements'),
  Category(name: 'Livres', emoji: '📚', route: '/livres'),
  Category(name: 'Équipement sport', emoji: '⚽', route: '/sport'),
  Category(name: 'Divertissement', emoji: '🎬', route: '/divertissement'),
  Category(name: 'Jobs', emoji: '💼', route: '/jobs'),
  Category(name: 'Beauté', emoji: '💄', route: '/beaute'),
  Category(name: 'Art', emoji: '🎨', route: '/art'),
  Category(name: 'Fournitures', emoji: '🏪', route: '/fournitures'),
  Category(name: 'Animaux', emoji: '🐕', route: '/animaux'),
  Category(name: 'Autre', emoji: '📦', route: '/autre'),
];

