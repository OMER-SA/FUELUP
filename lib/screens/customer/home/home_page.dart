import 'package:flutter/material.dart';
import 'package:diet_app/components/loading.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DBService _dbService = DBService();
  final DefaultColors _defaultColor = DefaultColors();

  String _selectedCategory = 'All';
  List<String> _categories = ['All'];
  Map<String, List<Map<String, dynamic>>> _groupedMeals = {};
  bool _isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!_mounted) return;
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadCategories(),
        _loadKitchenMeals(),
      ]);
    } catch (e) {
      _showErrorSnackBar('Failed to load data: $e');
    } finally {
      if (_mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final fetchedCategories = await _dbService.getCategories();
      if (_mounted) {
        setState(() {
          _categories = [
            'All',
            ...fetchedCategories.map((item) => item['category'] as String)
          ];
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load categories: $e');
    }
  }

  Future<void> _loadKitchenMeals() async {
    try {
      final fetchedGroupedMeals =
          await _dbService.getMeals(category: _selectedCategory);

      if (_mounted) {
        setState(() {
          _groupedMeals = fetchedGroupedMeals;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load kitchen meals: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (_mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: LoadingSpinner());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoriesSection(),
          const SizedBox(height: 20),
          _buildKitchenMealsSection(),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return _categories.length > 1
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildCategoryList()
            ],
          )
        : Container();
  }

  Widget _buildCategoryList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.asMap().entries.map((entry) {
          return _buildCategoryItem(entry.key, entry.value);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryItem(int index, String category) {
    bool isSelected = category == _selectedCategory;
    return Padding(
      padding: EdgeInsets.only(
        left: index == 0 ? 16 : 0,
        right: 12,
      ),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 175),
          curve: Curves.ease,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? _defaultColor.primaryColor
                : _defaultColor.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _defaultColor.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Text(
            category,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKitchenMealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Kitchen Meals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _groupedMeals.isNotEmpty
            ? _buildGroupedMeals()
            : _buildNoDataAvailable(),
      ],
    );
  }

  Widget _buildNoDataAvailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_meals,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No meals available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new meals!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedMeals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _groupedMeals.entries.toList().asMap().entries.map((chefEntry) {
        return _buildChefSection(chefEntry.key, chefEntry.value);
      }).toList(),
    );
  }

  Widget _buildChefSection(
      int chefIndex, MapEntry<String, List<Map<String, dynamic>>> entry) {
    List<Map<String, dynamic>> filteredMeals = _selectedCategory == 'All'
        ? entry.value
        : entry.value
            .where((meal) => meal['category'] == _selectedCategory)
            .toList();

    if (filteredMeals.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            'Chef: ${filteredMeals.first['kitchenName']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: filteredMeals.asMap().entries.map((mealEntry) {
                    return _buildMealCard(mealEntry.key, mealEntry.value);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Check if a meal contains any ingredients matching the customer's allergies
  bool _mealHasAllergens(
      Map<String, dynamic> meal, List<String> customerAllergies) {
    if (customerAllergies.isEmpty) return false;
    final recipe = meal['recipie'] as List<dynamic>?;
    if (recipe == null || recipe.isEmpty) return false;

    for (var item in recipe) {
      final ingredientName =
          (item['ingredient'] ?? '').toString().toLowerCase();
      for (var allergy in customerAllergies) {
        final pattern = RegExp(
          r'\b' +
              RegExp.escape(allergy.replaceAll(RegExp(r's$'), '')) +
              r's?\b',
        );
        if (pattern.hasMatch(ingredientName)) return true;
      }
    }
    return false;
  }

  Widget _buildMealCard(int mealIndex, Map<String, dynamic> meal) {
    final customerProvider =
        Provider.of<CustomerProvider>(context, listen: false);
    final customerAllergies = customerProvider.getAllergies
            ?.map((e) => e.toString().toLowerCase())
            .toList() ??
        [];
    final hasAllergens = _mealHasAllergens(meal, customerAllergies);

    return Padding(
      padding: EdgeInsets.only(
        left: mealIndex == 0 ? 16.0 : 0,
        right: 16.0,
        bottom: 16.0,
      ),
      child: SizedBox(
        width: 230,
        child: InkWell(
          onTap: () {
            context.go('/home/meal-detail', extra: meal);
          },
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _defaultColor.primaryColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                        ),
                        child: meal['mealPicture'] == null
                            ? const Icon(Icons.fastfood)
                            : ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: Image.network(
                                  meal['mealPicture'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    if (hasAllergens)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _defaultColor.warningColor,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Contains Allergens',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['mealName'],
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Price: ${meal['price']} Rs',
                        style: TextStyle(
                            color: _defaultColor.primaryColor,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${meal['category']}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meal['description'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
