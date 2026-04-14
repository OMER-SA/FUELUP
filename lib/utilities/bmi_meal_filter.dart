import 'dart:math' as math;

/// Utility for filtering and recommending meals based on BMI category
class BmiMealFilter {
  static const double _goalEpsilonKg = 0.25;
  static const double _lossTolerance = 0.20;
  static const double _gainTolerance = 0.15;
  static const double _maintainTolerance = 0.15;
  static const double _minProteinForGain = 25;

  /// Get BMI category string
  static String getBmiCategory(double bmi) {
    if (bmi <= 0) return 'unknown';
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25.0) return 'normal';
    if (bmi < 30.0) return 'overweight';
    return 'obese';
  }

  /// Get recommended calorie range for a meal based on BMI
  ///
  /// Returns a map with 'min' and 'max' calorie values per serving
  static Map<String, int> getRecommendedCalorieRange(double bmi) {
    final category = getBmiCategory(bmi);
    switch (category) {
      case 'underweight':
        return {'min': 500, 'max': 1200};
      case 'normal':
        return {'min': 300, 'max': 700};
      case 'overweight':
        return {'min': 200, 'max': 450};
      case 'obese':
        return {'min': 150, 'max': 350};
      default:
        return {'min': 0, 'max': 9999};
    }
  }

  /// Check if a meal's calorie count matches the BMI recommendation
  static bool isMealRecommended(double bmi, int? mealCalories) {
    if (mealCalories == null || mealCalories <= 0) return false;
    final range = getRecommendedCalorieRange(bmi);
    return mealCalories >= range['min']! && mealCalories <= range['max']!;
  }

  /// Get recommendation label for UI display
  static String getRecommendationLabel(
    double bmi, {
    double? currentWeight,
    double? targetWeight,
  }) {
    final goalType = getGoalType(
      currentWeight: currentWeight,
      targetWeight: targetWeight,
    );

    switch (goalType) {
      case 'loss':
        return 'Lower-calorie meals that support a calorie deficit';
      case 'gain':
        return 'Higher-calorie, higher-protein meals to support muscle gain';
      case 'maintain':
        return 'Balanced meals to help maintain your current weight';
    }

    final category = getBmiCategory(bmi);
    switch (category) {
      case 'underweight':
        return 'High-energy meals to help you gain';
      case 'normal':
        return 'Balanced meals to maintain your weight';
      case 'overweight':
        return 'Lighter meals to support your goals';
      case 'obese':
        return 'Low-calorie meals for healthy weight loss';
      default:
        return 'All meals';
    }
  }

  /// Get badge text for a meal card
  static String? getMealBadge(double bmi, int? mealCalories) {
    if (!isMealRecommended(bmi, mealCalories)) return null;
    final category = getBmiCategory(bmi);
    switch (category) {
      case 'underweight':
        return 'Energy Boost';
      case 'normal':
        return 'Good Choice';
      case 'overweight':
      case 'obese':
        return 'Light & Healthy';
      default:
        return null;
    }
  }

  /// Get calorie label for meal detail page
  static String getCalorieAdvice(double bmi, int? mealCalories) {
    if (mealCalories == null || mealCalories <= 0) {
      return 'Calorie info not available';
    }
    if (isMealRecommended(bmi, mealCalories)) {
      return 'Matches your BMI goal';
    }

    final range = getRecommendedCalorieRange(bmi);
    if (mealCalories > range['max']!) {
      return 'Higher calories than recommended for your goal';
    }
    return 'Lower calories than recommended for your goal';
  }

  static String getGoalType({
    required double? currentWeight,
    required double? targetWeight,
  }) {
    if (currentWeight == null ||
        targetWeight == null ||
        !currentWeight.isFinite ||
        !targetWeight.isFinite ||
        currentWeight <= 0 ||
        targetWeight <= 0) {
      return 'maintain';
    }

    final difference = targetWeight - currentWeight;
    if (difference.abs() <= _goalEpsilonKg) {
      return 'maintain';
    }

    return difference > 0 ? 'gain' : 'loss';
  }

  static double? _asDouble(dynamic value) {
    if (value is num) {
      final converted = value.toDouble();
      return converted.isFinite ? converted : null;
    }

    if (value == null) return null;

    final converted = double.tryParse(value.toString().trim());
    if (converted == null || !converted.isFinite) {
      return null;
    }

    return converted;
  }

  /// Filter a list of meals to get only recommended ones, factoring in goal and calories
  static List<Map<String, dynamic>> filterRecommendedMeals(
    double bmi,
    List<Map<String, dynamic>> meals,
    double currentWeight,
    double targetWeight,
    double? goalCalories,
  ) {
    if (bmi <= 0 || meals.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final goalType = getGoalType(
      currentWeight: currentWeight,
      targetWeight: targetWeight,
    );
    final bmiRange = getRecommendedCalorieRange(bmi);
    final sanitizedGoalCalories =
        goalCalories != null && goalCalories.isFinite && goalCalories > 0
            ? goalCalories
            : null;
    final perMealTarget =
        sanitizedGoalCalories != null ? sanitizedGoalCalories / 3 : null;

    final filtered = <Map<String, dynamic>>[];

    for (final meal in meals) {
      final calories = _asDouble(meal['calories']);
      if (calories == null || calories <= 0) {
        continue;
      }

      final protein = _asDouble(meal['protein']);
      final bmiMinCalories = bmiRange['min']!.toDouble();
      final bmiMaxCalories = bmiRange['max']!.toDouble();

      bool matchesGoal;
      String badge;

      switch (goalType) {
        case 'loss':
          final minCalories = perMealTarget != null
              ? math.max(100, perMealTarget * (1 - _lossTolerance))
              : bmiMinCalories;
          final maxCalories = perMealTarget != null
              ? math.min(perMealTarget, bmiMaxCalories)
              : bmiMaxCalories;
          matchesGoal = calories >= minCalories && calories <= maxCalories;
          badge = 'Weight Loss';
          break;
        case 'gain':
          final minCalories = perMealTarget != null
              ? perMealTarget * (1 - _gainTolerance)
              : math.max(bmiMinCalories, 500);
          final maxCalories = perMealTarget != null
              ? perMealTarget * (1 + _gainTolerance)
              : math.max(bmiMaxCalories, minCalories);
          matchesGoal = calories >= minCalories &&
              calories <= maxCalories &&
              (protein ?? 0) >= _minProteinForGain;
          badge = 'Muscle Gain';
          break;
        case 'maintain':
          final minCalories = perMealTarget != null
              ? perMealTarget * (1 - _maintainTolerance)
              : bmiMinCalories;
          final maxCalories = perMealTarget != null
              ? perMealTarget * (1 + _maintainTolerance)
              : bmiMaxCalories;
          matchesGoal = calories >= minCalories && calories <= maxCalories;
          badge = 'Maintain';
          break;
        default:
          matchesGoal =
              calories >= bmiMinCalories && calories <= bmiMaxCalories;
          badge = 'Recommended';
      }

      if (!matchesGoal) {
        continue;
      }

      final recommendedMeal = Map<String, dynamic>.from(meal);
      recommendedMeal['goalBadge'] = badge;
      recommendedMeal['calories'] = calories.round();
      if (protein != null) {
        recommendedMeal['protein'] = protein.round();
      }
      filtered.add(recommendedMeal);
    }

    return filtered;
  }

  /// Sort meals by recommendation relevance
  /// Recommended meals first, then others
  static List<Map<String, dynamic>> sortByRecommendation(
    double bmi,
    List<Map<String, dynamic>> meals,
  ) {
    final recommended = <Map<String, dynamic>>[];
    final others = <Map<String, dynamic>>[];

    for (final meal in meals) {
      final calories = _asDouble(meal['calories'])?.round();
      if (isMealRecommended(bmi, calories)) {
        recommended.add(meal);
      } else {
        others.add(meal);
      }
    }

    return [...recommended, ...others];
  }
}
