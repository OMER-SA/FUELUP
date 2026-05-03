import 'package:diet_app/models/mood_types.dart';
import 'package:diet_app/utilities/bmi_meal_filter.dart';
import 'package:diet_app/utilities/tag_based_mood_detector.dart';

class MoodMealFilter {
  static const Map<String, List<String>> _dietaryConflicts = {
    'vegetarian': ['meat', 'beef', 'chicken', 'fish', 'seafood', 'shellfish'],
    'vegan': [
      'meat',
      'beef',
      'chicken',
      'fish',
      'seafood',
      'shellfish',
      'dairy',
      'egg',
      'honey',
    ],
    'halal': ['non_halal', 'pork', 'alcohol'],
    'kosher': ['non_kosher', 'pork', 'shellfish'],
    'keto': ['high_carb', 'sugar', 'refined_carb'],
    'low_carb': ['high_carb', 'refined_carb', 'sugar'],
    'low_fat': ['high_fat', 'fatty', 'fried'],
    'dairy_free': ['dairy'],
    'gluten_free': ['gluten', 'wheat'],
  };

  static Map<String, double> _resolveWeights({
    required MoodType? mood,
    required double bmi,
    required double currentWeight,
    required double targetWeight,
  }) {
    double moodW = 0.35;
    double calorieW = 0.30;
    double bmiW = 0.20;
    double goalW = 0.15;

    final weightDiff = (targetWeight - currentWeight).abs();
    final isUnderweight = bmi < 18.5;
    final isOverweight = bmi >= 25.0;
    final isObese = bmi >= 30.0;
    final isUrgentGoal = weightDiff > 10;
    final isUnpleasant = mood == MoodType.unpleasant;
    final isEnergetic = mood == MoodType.surprise;

    if (isUnpleasant && isUnderweight) {
      moodW = 0.40;
      calorieW = 0.15;
      bmiW = 0.30;
      goalW = 0.15;
    } else if (isEnergetic && isObese) {
      moodW = 0.25;
      calorieW = 0.40;
      bmiW = 0.25;
      goalW = 0.10;
    } else if (isUnpleasant && isOverweight) {
      moodW = 0.30;
      calorieW = 0.30;
      bmiW = 0.25;
      goalW = 0.15;
    } else if (isUrgentGoal) {
      moodW = 0.20;
      calorieW = 0.40;
      bmiW = 0.25;
      goalW = 0.15;
    } else if (isObese) {
      moodW = 0.25;
      calorieW = 0.40;
      bmiW = 0.20;
      goalW = 0.15;
    }

    final total = moodW + calorieW + bmiW + goalW;
    return {
      'mood': moodW / total,
      'calorie': calorieW / total,
      'bmi': bmiW / total,
      'goal': goalW / total,
    };
  }

  static String _resolveWeightProfile({
    required MoodType? mood,
    required double bmi,
    required double currentWeight,
    required double targetWeight,
  }) {
    final weightDiff = (targetWeight - currentWeight).abs();
    final isUnderweight = bmi < 18.5;
    final isOverweight = bmi >= 25.0;
    final isObese = bmi >= 30.0;
    final isUrgentGoal = weightDiff > 10;
    final isUnpleasant = mood == MoodType.unpleasant;
    final isEnergetic = mood == MoodType.surprise;

    if (isUnpleasant && isUnderweight) {
      return 'calm_mind_first';
    }

    if (isEnergetic && isObese) {
      return 'calorie_controlled';
    }

    if (isUnpleasant && isOverweight) {
      return 'health_balance';
    }

    if (isUrgentGoal) {
      return 'goal_focused';
    }

    if (isObese) {
      return 'calorie_controlled';
    }

    return 'mood_priority';
  }

  static List<Map<String, dynamic>> rankMeals({
    required List<Map<String, dynamic>> meals,
    required MoodType? mood,
    required double bmi,
    required double currentWeight,
    required double targetWeight,
    required double goalCalories,
    required List<String> allergies,
    required List<String> dietaryPrefs,
  }) {
    if (meals.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final normalizedAllergies = allergies
        .map(_normalizeTag)
        .where((value) => value.isNotEmpty)
        .toSet();
    final normalizedPrefs = dietaryPrefs
        .map(_normalizeTag)
        .where((value) => value.isNotEmpty)
        .toSet();
    final bmiRange = BmiMealFilter.getRecommendedCalorieRange(bmi);
    final defaultPerMealTarget =
        ((bmiRange['min']! + bmiRange['max']!) / 2).toDouble();
    final targetPerMeal = goalCalories.isFinite && goalCalories > 0
        ? goalCalories / 3.0
        : defaultPerMealTarget;
    final effectiveCurrentWeight =
        currentWeight.isFinite && currentWeight > 0 ? currentWeight : 0.0;
    final effectiveTargetWeight =
        targetWeight.isFinite && targetWeight > 0
            ? targetWeight
            : effectiveCurrentWeight;
    final weights = _resolveWeights(
      mood: mood,
      bmi: bmi,
      currentWeight: effectiveCurrentWeight,
      targetWeight: effectiveTargetWeight,
    );
    final weightProfile = _resolveWeightProfile(
      mood: mood,
      bmi: bmi,
      currentWeight: effectiveCurrentWeight,
      targetWeight: effectiveTargetWeight,
    );

    final filtered = meals.where((meal) {
      final mealAllergens = _extractStringValues(meal['allergens']);
      final mealTags = _extractTags(meal);
      final allMealAllergenFields = {
        ...mealAllergens,
        ...mealTags,
      };

      final hasAllergen = normalizedAllergies.any(
        (allergy) => allMealAllergenFields.contains(allergy),
      );
      if (hasAllergen) {
        return false;
      }

      final mealDietaryLabels = _extractStringValues(meal['dietaryLabels']);

      for (final pref in normalizedPrefs) {
        if (pref == 'vegetarian' &&
            !mealDietaryLabels.contains('vegetarian') &&
            !mealDietaryLabels.contains('vegan')) {
          return false;
        }

        if (pref == 'vegan' && !mealDietaryLabels.contains('vegan')) {
          return false;
        }

        if (pref == 'halal' && !mealDietaryLabels.contains('halal')) {
          return false;
        }
      }

      if (mealDietaryLabels.isEmpty &&
          mealTags.isNotEmpty &&
          _violatesDietaryPreferences(mealTags, normalizedPrefs)) {
        return false;
      }

      return true;
    }).map((meal) => Map<String, dynamic>.from(meal)).toList();

    if (filtered.isEmpty) {
      return meals
          .map((meal) {
            final fallback = Map<String, dynamic>.from(meal);
            _attachMoodMetadata(
              fallback,
              mood: mood,
              score: 0.0,
              weightProfile: weightProfile,
              allFiltered: true,
            );
            return fallback;
          })
          .toList(growable: false);
    }

    final preferTags = mood == null
        ? const <String>[]
        : MoodTypeConfig.moodFoodTags[mood]!['prefer']!;
    final avoidTags = mood == null
        ? const <String>[]
        : MoodTypeConfig.moodFoodTags[mood]!['avoid']!;

    for (final meal in filtered) {
      final mealTags = _extractTags(meal);
      final calories = _asDouble(meal['calories']) ?? targetPerMeal;
      final protein = _asDouble(meal['protein']) ??
          _asDouble(meal['proteinGrams']) ??
          0.0;
      final moodScore = mood == null
          ? 0.5
          : _calculateMoodScore(
              tags: mealTags,
              preferTags: preferTags,
              avoidTags: avoidTags,
            );
      final calorieScore = _calculateCalorieScore(
        mealCalories: calories,
        targetPerMeal: targetPerMeal,
      );
      final bmiScore = _calculateBmiScore(
        bmi: bmi,
        mealCalories: calories,
        targetPerMeal: targetPerMeal,
      );
      final goalScore = _calculateGoalDirectionScore(
        currentWeight: effectiveCurrentWeight,
        targetWeight: effectiveTargetWeight,
        mealCalories: calories,
        targetPerMeal: targetPerMeal,
        protein: protein,
      );

      final score = (moodScore * weights['mood']!) +
          (calorieScore * weights['calorie']!) +
          (bmiScore * weights['bmi']!) +
          (goalScore * weights['goal']!);

      _attachMoodMetadata(
        meal,
        mood: mood,
        score: score.clamp(0.0, 1.0),
        weightProfile: weightProfile,
      );
    }

    filtered.sort((left, right) {
      final rightScore = _asDouble(right['_score']) ?? 0.0;
      final leftScore = _asDouble(left['_score']) ?? 0.0;
      return rightScore.compareTo(leftScore);
    });

    return filtered;
  }

  /// Strict matcher for voice-model labels only.
  /// Accepted userMood values: neutral, happy, surprise, unpleasant.
  static List<Map<String, dynamic>> getRecommendedMeals({
    required List<Map<String, dynamic>> meals,
    required String userMood,
  }) {
    if (meals.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final normalizedUserMood = TagBasedMoodDetector.normalizeVoiceMoodLabel(userMood);
    final effectiveMood = normalizedUserMood ?? 'neutral';

    final ranked = meals.map((meal) {
      final cloned = Map<String, dynamic>.from(meal);
      final tags = _extractTags(cloned);
      final mealMood = TagBasedMoodDetector.mapTagsToVoiceMood(tags);
      final strictMatch = mealMood == effectiveMood;

      // Strict mood-first scoring.
      final score = strictMatch ? 1.0 : 0.2;

      cloned['_voiceMood'] = mealMood;
      cloned['_userVoiceMood'] = effectiveMood;
      cloned['_strictMoodMatch'] = strictMatch;
      cloned['_score'] = score;
      return cloned;
    }).toList(growable: false);

    ranked.sort((left, right) {
      final rightScore = _asDouble(right['_score']) ?? 0.0;
      final leftScore = _asDouble(left['_score']) ?? 0.0;
      return rightScore.compareTo(leftScore);
    });

    return ranked;
  }

  static double _calculateMoodScore({
    required List<String> tags,
    required List<String> preferTags,
    required List<String> avoidTags,
  }) {
    if (preferTags.isEmpty) {
      return 0.5;
    }

    final preferHits = tags.where(preferTags.contains).length;
    final avoidHits = tags.where(avoidTags.contains).length;

    var moodScore = (preferHits / preferTags.length).clamp(0.0, 1.0);
    moodScore -= avoidHits * 0.15;

    return moodScore.clamp(0.0, 1.0);
  }

  static double _calculateCalorieScore({
    required double mealCalories,
    required double targetPerMeal,
  }) {
    if (!mealCalories.isFinite || !targetPerMeal.isFinite || targetPerMeal <= 0) {
      return 0.0;
    }

    final diff = (mealCalories - targetPerMeal).abs() / targetPerMeal;
    return (1.0 - diff).clamp(0.0, 1.0);
  }

  static double _calculateBmiScore({
    required double bmi,
    required double mealCalories,
    required double targetPerMeal,
  }) {
    if (!mealCalories.isFinite || !targetPerMeal.isFinite || targetPerMeal <= 0) {
      return 0.0;
    }

    final calorieScore = _calculateCalorieScore(
      mealCalories: mealCalories,
      targetPerMeal: targetPerMeal,
    );

    if (bmi < 18.5) {
      return mealCalories >= targetPerMeal
          ? 1.0
          : (mealCalories / targetPerMeal).clamp(0.0, 1.0);
    }

    if (bmi < 25.0) {
      return calorieScore;
    }

    if (bmi < 30.0) {
      return mealCalories <= targetPerMeal
          ? 1.0
          : (1.0 - ((mealCalories - targetPerMeal) / targetPerMeal))
              .clamp(0.0, 1.0);
    }

    return (1.0 - (mealCalories / (targetPerMeal * 1.5))).clamp(0.0, 1.0);
  }

  static double _calculateGoalDirectionScore({
    required double currentWeight,
    required double targetWeight,
    required double mealCalories,
    required double targetPerMeal,
    required double protein,
  }) {
    final weightDiff = targetWeight - currentWeight;

    if (weightDiff < -2) {
      return mealCalories < targetPerMeal ? 1.0 : 0.4;
    }

    if (weightDiff > 2) {
      return protein >= 25 ? 1.0 : (protein / 25.0).clamp(0.0, 1.0);
    }

    return 0.7;
  }

  static void _attachMoodMetadata(
    Map<String, dynamic> meal, {
    required MoodType? mood,
    required double score,
    required String weightProfile,
    bool allFiltered = false,
  }) {
    final badge = mood == null
        ? ''
        : (MoodTypeConfig.badgeLabels[mood] ??
            MoodTypeConfig.badgeLabels[MoodType.neutral]!);
    final colorValue = mood == null
        ? 0xFF888888
        : (MoodTypeConfig.colorValues[mood] ??
            MoodTypeConfig.colorValues[MoodType.neutral]!);

    meal['_score'] = score;
    meal['_mood'] = mood?.name;
    meal['_moodBadge'] = badge;
    meal['_moodColor'] = colorValue;
    meal['_weightProfile'] = weightProfile;
    if (allFiltered) {
      meal['_allFiltered'] = true;
    }
  }

  static bool _violatesDietaryPreferences(
    List<String> tags,
    Set<String> dietaryPrefs,
  ) {
    for (final pref in dietaryPrefs) {
      final conflicts = _dietaryConflicts[pref];
      if (conflicts == null || conflicts.isEmpty) {
        continue;
      }

      final normalizedConflicts = conflicts.map(_normalizeTag).toSet();
      if (_matchesAnyTag(tags, normalizedConflicts)) {
        return true;
      }
    }

    return false;
  }

  static bool _matchesAnyTag(List<String> tags, Set<String> values) {
    if (tags.isEmpty || values.isEmpty) {
      return false;
    }

    for (final value in values) {
      for (final tag in tags) {
        if (tag == value || tag.contains(value) || value.contains(tag)) {
          return true;
        }
      }
    }

    return false;
  }

  static List<String> _extractTags(Map<String, dynamic> meal) {
    return _extractStringValues(meal['tags']);
  }

  static List<String> _extractStringValues(dynamic rawValues) {
    if (rawValues is List) {
      return rawValues
          .map((value) => _normalizeTag(value.toString()))
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }

    if (rawValues is String) {
      return rawValues
          .split(',')
          .map(_normalizeTag)
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }

    return <String>[];
  }

  static String _normalizeTag(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[\s-]+'), '_');
  }

  static double? _asDouble(dynamic value) {
    if (value is num) {
      final converted = value.toDouble();
      return converted.isFinite ? converted : null;
    }

    if (value == null) {
      return null;
    }

    final converted = double.tryParse(value.toString().trim());
    if (converted == null || !converted.isFinite) {
      return null;
    }

    return converted;
  }
}
