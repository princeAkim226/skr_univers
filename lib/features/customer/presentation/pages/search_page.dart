import 'package:flutter/material.dart';
import '../../../../data/services/product_service.dart';
import '../widgets/product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _currentQuery = '';
  String _selectedCategory = 'Tous';
  String _sortBy = 'created_at';
  bool _sortAscending = false;
  RangeValues _priceRange = const RangeValues(0, 1000000);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length >= 2) {
      _getSuggestions(query);
    } else {
      setState(() {
        _suggestions = [];
        _searchResults = [];
        _currentQuery = '';
      });
    }
  }

  Future<void> _getSuggestions(String query) async {
    try {
      final suggestions = await _productService.getSearchSuggestions(query);
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      print('Erreur lors de la récupération des suggestions: $e');
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _currentQuery = query;
    });

    try {
      final results = await _productService.searchProducts(
        query: query,
        category: _selectedCategory == 'Tous' ? null : _selectedCategory,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        sortBy: _sortBy,
        ascending: _sortAscending,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de recherche: $e')),
        );
      }
    }
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _performSearch();
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtres',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _selectedCategory = 'Tous';
                        _priceRange = const RangeValues(0, 1000000);
                        _sortBy = 'created_at';
                        _sortAscending = false;
                      });
                    },
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Catégorie
              Text(
                'Catégorie',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: [
                  'Tous',
                  'Électronique',
                  'Mode',
                  'Maison',
                  'Sport',
                  'Livres',
                  'Beauté',
                  'Art',
                ].map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )).toList(),
                onChanged: (value) {
                  setModalState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Prix
              Text(
                'Prix (FCFA)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 1000000,
                divisions: 20,
                labels: RangeLabels(
                  '${_priceRange.start.round()} FCFA',
                  '${_priceRange.end.round()} FCFA',
                ),
                onChanged: (values) {
                  setModalState(() {
                    _priceRange = values;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Tri
              Text(
                'Trier par',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sortBy,
                items: [
                  DropdownMenuItem(value: 'created_at', child: Text('Plus récent')),
                  DropdownMenuItem(value: 'price', child: Text('Prix')),
                  DropdownMenuItem(value: 'title', child: Text('Nom')),
                ],
                onChanged: (value) {
                  setModalState(() {
                    _sortBy = value!;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _performSearch();
                      },
                      child: const Text('Appliquer'),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Rechercher des produits...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          autofocus: true,
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _performSearch,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggestions
          if (_suggestions.isNotEmpty && !_isSearching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggestions',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _suggestions.map((suggestion) => GestureDetector(
                      onTap: () => _selectSuggestion(suggestion),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          
          // Résultats de recherche
          if (_isSearching) ...[
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_searchResults.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun résultat trouvé',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Essayez avec d\'autres mots-clés',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // En-tête des résultats
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_searchResults.length} résultat(s) pour "$_currentQuery"',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showFilters,
                            icon: const Icon(Icons.tune, size: 16),
                            label: const Text('Filtres'),
                          ),
                        ],
                      ),
                    ),
                    
                    // Grille des résultats
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: _searchResults[index],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ]
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recherchez des produits',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tapez le nom d\'un produit ou d\'une catégorie',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
