import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final Map<String, int> categoryStats;

  const CategorySelector({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
    required this.categoryStats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1, // +1 pour "Tous"
        itemBuilder: (context, index) {
          if (index == 0) {
            // Bouton "Tous"
            final isSelected = selectedCategory == null;
            return _buildCategoryChip(
              'Tous',
              isSelected,
              () => onCategorySelected(null),
              null,
            );
          }
          
          final category = categories[index - 1];
          final isSelected = selectedCategory == category;
          final productCount = categoryStats[category] ?? 0;
          
          return _buildCategoryChip(
            category,
            isSelected,
            () => _handleTap(context, category),
            productCount,
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(
    String category,
    bool isSelected,
    VoidCallback onTap,
    int? productCount,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? AppTheme.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(25),
        elevation: isSelected ? 4 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (productCount != null && productCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      productCount.toString(),
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, String category) {
    // Normaliser la catégorie (minuscules, sans accents approximatif) pour
    // gérer les petites variations de libellés venant de la base.
    String normalized = category.toLowerCase();
    normalized = normalized
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('û', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('î', 'i');

    // Navigation directe pour certaines catégories connues
    switch (normalized) {
      case 'habitations':
      case 'maison':
      case 'maisons':
        context.push('/customer/habitations');
        break;
      case 'vetements':
      case 'vetement':
      case 'mode':
        context.push('/customer/vetements');
        break;
      case 'livres':
      case 'livre':
        context.push('/customer/livres');
        break;
      case 'moteurs':
      case 'moteur':
        context.push('/customer/motor');
        break;
      case 'beaute':
        context.push('/customer/beaute');
        break;
      case 'electroniques':
      case 'electronique':
        context.push('/customer/electroniques');
        break;
      case 'equipement sport':
      case 'equipements sport':
      case 'sport':
        context.push('/customer/equipements');
        break;
      case 'divertissement':
      case 'loisirs':
        context.push('/customer/divertissement');
        break;
      case 'jobs':
      case 'emploi':
      case 'travail':
        context.push('/customer/jobs');
        break;
      case 'art':
        context.push('/customer/art');
        break;
      case 'fournitures':
      case 'fourniture':
        context.push('/customer/fournitures');
        break;
      case 'animaux':
      case 'animal':
        context.push('/customer/animaux');
        break;
      default:
        onCategorySelected(category);
    }
  }
}
