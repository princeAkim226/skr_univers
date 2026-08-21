
class Category {
  final String name;
  final String emoji;
  final String route;
  final String imageAsset;

  const Category({
    required this.name,
    required this.emoji,
    required this.route,
    required this.imageAsset,
  });

  String get slug => route.replaceAll('/', '');
}

const List<Category> categories = [
  Category(
    name: 'Habitations',
    emoji: '🏠',
    route: '/habitations',
    imageAsset: 'assets/images/categories/habitations.png',
  ),
  Category(
    name: 'Moteurs',
    emoji: '🚗',
    route: '/moteurs',
    imageAsset: 'assets/images/categories/moteurs.png',
  ),
  Category(
    name: 'Électroniques',
    emoji: '📱',
    route: '/electroniques',
    imageAsset: 'assets/images/categories/electroniques.png',
  ),
  Category(
    name: 'Vêtements',
    emoji: '👕',
    route: '/vetements',
    imageAsset: 'assets/images/categories/vetements.png',
  ),
  Category(
    name: 'Livres',
    emoji: '📚',
    route: '/livres',
    imageAsset: 'assets/images/categories/livres.png',
  ),
  Category(
    name: 'Équipement sport',
    emoji: '⚽',
    route: '/sport',
    imageAsset: 'assets/images/categories/sport.png',
  ),
  Category(
    name: 'Divertissement',
    emoji: '🎬',
    route: '/divertissement',
    imageAsset: 'assets/images/categories/divertissement.png',
  ),
  Category(
    name: 'Jobs',
    emoji: '💼',
    route: '/jobs',
    imageAsset: 'assets/images/categories/jobs.png',
  ),
  Category(
    name: 'Beauté',
    emoji: '💄',
    route: '/beaute',
    imageAsset: 'assets/images/categories/beaute.png',
  ),
  Category(
    name: 'Art',
    emoji: '🎨',
    route: '/art',
    imageAsset: 'assets/images/categories/art.png',
  ),
  Category(
    name: 'Fournitures',
    emoji: '🏪',
    route: '/fournitures',
    imageAsset: 'assets/images/categories/fournitures.png',
  ),
  Category(
    name: 'Animaux',
    emoji: '🐕',
    route: '/animaux',
    imageAsset: 'assets/images/categories/animaux.png',
  ),
  Category(
    name: 'Autre',
    emoji: '📦',
    route: '/autre',
    imageAsset: 'assets/images/categories/autre.png',
  ),
];

String? categoryImageAsset(String name) {
  for (final category in categories) {
    if (category.name == name) return category.imageAsset;
  }
  switch (name) {
    case 'Maison':
      return 'assets/images/categories/habitations.png';
    case 'Mode':
      return 'assets/images/categories/vetements.png';
    case 'Électronique':
      return 'assets/images/categories/electroniques.png';
    case 'Sport':
      return 'assets/images/categories/sport.png';
    default:
      return 'assets/images/categories/autre.png';
  }
}
