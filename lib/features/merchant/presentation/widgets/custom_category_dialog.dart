import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CustomCategoryDialog extends StatefulWidget {
  const CustomCategoryDialog({super.key});

  @override
  State<CustomCategoryDialog> createState() => _CustomCategoryDialogState();
}

class _CustomCategoryDialogState extends State<CustomCategoryDialog> {
  final TextEditingController _categoryController = TextEditingController();
  final List<String> _suggestions = [
    'Jardinage',
    'Bricolage',
    'Cuisine',
    'Décoration',
    'Musique',
    'Photographie',
    'Voyage',
    'Santé',
    'Éducation',
    'Services',
  ];
  String? _selectedSuggestion;

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Préciser la catégorie'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Veuillez préciser la catégorie de votre produit :',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          
          // Champ de saisie
          TextField(
            controller: _categoryController,
            decoration: InputDecoration(
              hintText: 'Ex: Jardinage, Bricolage, Cuisine...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _selectedSuggestion = null;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Suggestions
          const Text(
            'Suggestions :',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((suggestion) {
              final isSelected = _selectedSuggestion == suggestion;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSuggestion = suggestion;
                    _categoryController.text = suggestion;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _categoryController.text.trim().isNotEmpty
              ? () => Navigator.of(context).pop(_categoryController.text.trim())
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}
