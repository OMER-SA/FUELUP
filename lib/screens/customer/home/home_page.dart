import 'dart:async';

import 'package:diet_app/components/loading.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/models/mood_types.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/utilities/bmi_meal_filter.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/mood_meal_filter.dart';
import 'package:diet_app/utilities/voice_mood_detector.dart';
import 'package:diet_app/widgets/meal_image.dart';
import 'package:diet_app/widgets/mood_onboarding_tooltip.dart';
import 'package:diet_app/widgets/mood_picker_sheet.dart';
import 'package:diet_app/widgets/voice_mood_button.dart';
import 'package:flutter/material.dart';
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
  late final VoiceMoodDetector _moodDetector;

  @override
  void initState() {
    super.initState();
    _moodDetector = VoiceMoodDetector();
    _warmMoodDetector();
    _loadData();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _warmMoodDetector() async {
    await _moodDetector.load();
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

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecommendedSection(),
                _buildCategoriesSection(),
                const SizedBox(height: 20),
                _buildKitchenMealsSection(),
              ],
            ),
          ),
        ),
        const MoodOnboardingTooltip(),
      ],
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
                : _defaultColor.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _defaultColor.primaryColor.withValues(alpha: 0.3),
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

  bool _mealHasAllergens(
      Map<String, dynamic> meal, List<String> customerAllergies) {
    if (customerAllergies.isEmpty) return false;

    String normalize(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');

    bool fuzzyMatch(String field, String allergy) {
      final stem = allergy.replaceAll(RegExp(r's$'), '');
      final pattern = RegExp(r'\b' + RegExp.escape(stem) + r's?\b');
      return pattern.hasMatch(field);
    }

    for (final allergy in customerAllergies) {
      final normalizedAllergy = normalize(allergy);

      // Check meal['allergens']
      final allergens = meal['allergens'];
      final allergenList = allergens is List
          ? allergens.map((e) => normalize(e.toString())).toList()
          : allergens is String
              ? allergens.split(',').map(normalize).toList()
              : <String>[];
      if (allergenList.any((a) =>
          a == normalizedAllergy ||
          a.contains(normalizedAllergy) ||
          normalizedAllergy.contains(a))) {
        return true;
      }

      // Check meal['tags']
      final tags = meal['tags'];
      final tagList = tags is List
          ? tags.map((e) => normalize(e.toString())).toList()
          : tags is String
              ? tags.split(',').map(normalize).toList()
              : <String>[];
      if (tagList.any((t) =>
          t == normalizedAllergy ||
          t.contains(normalizedAllergy) ||
          normalizedAllergy.contains(t))) {
        return true;
      }

      // Check recipe ingredients
      final recipe = meal['recipie'] as List<dynamic>?;
      if (recipe != null) {
        for (final item in recipe) {
          final ingredientName =
              (item['ingredient'] ?? '').toString().toLowerCase();
          if (fuzzyMatch(ingredientName, allergy)) return true;
        }
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
                      child: MealImage(
                        meal: meal,
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
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
                                color: Colors.black.withValues(alpha: 0.2),
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
                      if (meal['calories'] != null && meal['calories'] > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.local_fire_department,
                                  color: Colors.orange[600], size: 14),
                              const SizedBox(width: 2),
                              Text(
                                '${meal['calories']} kcal',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
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

  Widget _buildRecommendedSection() {
    final provider = context.watch<CustomerProvider>();
    final currentMood = provider.currentMood;
    final bmi = provider.calculateBmi();
    final currentWeight = provider.getWeight?.toDouble() ?? 0.0;
    final targetWeight = provider.getTargetWeight ?? currentWeight;
    final goalCalories = provider.goalCalories ?? _fallbackGoalCalories(bmi);

    if (bmi <= 0 || _groupedMeals.isEmpty) {
      return const SizedBox.shrink();
    }

    final allMeals = _groupedMeals.values
        .expand((meals) => meals)
        .whereType<Map<String, dynamic>>()
        .toList();

    if (allMeals.isEmpty) {
      return const SizedBox.shrink();
    }

    final recommended = MoodMealFilter.rankMeals(
      meals: allMeals,
      mood: currentMood,
      bmi: bmi,
      currentWeight: currentWeight,
      targetWeight: targetWeight,
      goalCalories: goalCalories,
      allergies: provider.allergies,
      dietaryPrefs: provider.dietaryPreferences,
    ).take(5).toList(growable: false);

    if (recommended.isEmpty) {
      return const SizedBox.shrink();
    }

    final label = BmiMealFilter.getRecommendationLabel(
      bmi,
      currentWeight: currentWeight,
      targetWeight: targetWeight,
    );
    final recommendedTitle = currentMood == null
        ? 'Recommended for you'
        : 'Recommended for your ${MoodTypeConfig.displayLabels[currentMood] ?? currentMood.name} mood';
    final moodColor = Color(
      MoodTypeConfig.colorValues[currentMood] ??
          MoodTypeConfig.colorValues[MoodType.neutral]!,
    );
    final moodLabel = MoodTypeConfig.displayLabels[currentMood] ??
        currentMood?.name ??
        'neutral';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR MOOD TODAY',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      recommendedTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _defaultColor.richBlackColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/profile/dietaryPreferences'),
                child: const Text('Set food preferences'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: VoiceMoodButton(
            detector: _moodDetector,
            onMoodDetected: (mood, confidence, source) {
              if (mood == null) {
                return;
              }
              unawaited(
                  provider.setMood(
                  mood,
                  confidence: confidence,
                  source: source,
                ),
              );
            },
          ),
        ),
        if (currentMood != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final selectedMood = await showMoodPickerSheet(
                  context,
                  selectedMood: currentMood,
                );
                if (!mounted || selectedMood == null) {
                  return;
                }
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: moodColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: moodColor.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: moodColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  moodLabel,
                                  style: TextStyle(
                                    color: moodColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                    color: (provider.moodSource == MoodSource.voice)
                                      ? Colors.purple.withValues(alpha: 0.10)
                                      : Colors.grey.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      provider.moodSource == MoodSource.voice
                                          ? Icons.mic
                                          : Icons.touch_app,
                                      size: 10,
                                      color: provider.moodSource == MoodSource.voice
                                          ? Colors.purple
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      provider.moodSource == MoodSource.voice
                                          ? 'Voice'
                                          : 'Manual',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: provider.moodSource == MoodSource.voice
                                            ? Colors.purple
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _moodMealCopy(currentMood),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        unawaited(
                          context.read<CustomerProvider>().clearMood(),
                        );
                      },
                      child: Icon(Icons.close, size: 16, color: moodColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: 92,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommended.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final meal = recommended[index];
                    final mealName =
                        (meal['mealName']?.toString().trim().isNotEmpty ?? false)
                            ? meal['mealName'].toString().trim()
                            : 'Meal';
                    final price = meal['price']?.toString() ?? '--';
                    final calories = meal['calories'] is num
                        ? (meal['calories'] as num).round()
                        : int.tryParse(meal['calories']?.toString() ?? '');
                    final badge = meal['_moodBadge']?.toString() ??
                        meal['goalBadge']?.toString() ??
                        BmiMealFilter.getMealBadge(bmi, calories) ??
                      MoodTypeConfig.badgeLabels[MoodType.neutral];
                    final badgeColorValue =
                        (meal['_moodColor'] as num?)?.toInt() ??
                        MoodTypeConfig.colorValues[currentMood] ??
                        MoodTypeConfig.colorValues[MoodType.neutral]!;
                    final badgeColor = Color(badgeColorValue);

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 180,
                        child: InkWell(
                          onTap: () => context.go('/home/meal-detail', extra: meal),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: MealImage(
                                          meal: meal,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    if (badge != null)
                                      Positioned(
                                        top: 6,
                                        left: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: badgeColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                badge,
                                                style: TextStyle(
                                                  color: badgeColor,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (meal['_allFiltered'] == true)
                                      Positioned(
                                        bottom: 6,
                                        left: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.65),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Preferences too strict',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mealName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$price Rs',
                                            style: TextStyle(
                                              color: _defaultColor.primaryColor,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (calories != null)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.local_fire_department,
                                                  size: 12,
                                                  color: Colors.orange[600],
                                                ),
                                                Text(
                                                  '$calories kcal',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.orange[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
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
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _moodMealCopy(MoodType mood) {
    switch (mood) {
      case MoodType.unpleasant:
        return 'Showing meals to calm your mind';
      case MoodType.surprise:
        return 'Showing meals to lift your energy';
      case MoodType.happy:
        return 'Showing balanced meals for your great mood';
      case MoodType.neutral:
        return 'Showing meals optimised for your goals';
    }
  }

  double _fallbackGoalCalories(double bmi) {
    final range = BmiMealFilter.getRecommendedCalorieRange(bmi);
    return ((range['min']! + range['max']!) / 2) * 3.0;
  }
}
