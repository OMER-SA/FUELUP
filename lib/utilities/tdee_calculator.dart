/// TDEE (Total Daily Energy Expenditure) Calculator
/// Uses the Mifflin-St Jeor equation for BMR calculation
class TdeeCalculator {
  static const double _goalEpsilonKg = 0.25;

  /// Activity level multipliers for TDEE calculation
  static const Map<String, double> activityMultipliers = {
    'sedentary': 1.2, // Little or no exercise
    'light': 1.375, // Light exercise 1-3 days/week
    'moderate': 1.55, // Moderate exercise 3-5 days/week
    'active': 1.725, // Hard exercise 6-7 days/week
    'veryActive': 1.9, // Very hard exercise, physical job
  };

  /// Activity level display labels
  static const Map<String, String> activityLabels = {
    'sedentary': 'Sedentary (little or no exercise)',
    'light': 'Lightly Active (1-3 days/week)',
    'moderate': 'Moderately Active (3-5 days/week)',
    'active': 'Very Active (6-7 days/week)',
    'veryActive': 'Extra Active (physical job + exercise)',
  };

  /// Calculate BMR using Mifflin-St Jeor equation
  ///
  /// [weightKg] - weight in kilograms
  /// [heightCm] - height in centimeters
  /// [age] - age in years
  /// [isMale] - true for male, false for female
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
  }) {
    // Mifflin-St Jeor Equation:
    // Male:   BMR = 10 x weight(kg) + 6.25 x height(cm) - 5 x age(y) + 5
    // Female: BMR = 10 x weight(kg) + 6.25 x height(cm) - 5 x age(y) - 161
    final bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return isMale ? bmr + 5 : bmr - 161;
  }

  /// Calculate TDEE from BMR and activity level
  ///
  /// [bmr] - Basal Metabolic Rate
  /// [activityLevel] - one of: sedentary, light, moderate, active, veryActive
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    final multiplier = activityMultipliers[activityLevel] ?? 1.2;
    return bmr * multiplier;
  }

  /// Calculate daily calorie target based on goal.
  static double calculateGoalCalories({
    required double tdee,
    required double currentWeight,
    required double targetWeight,
  }) {
    final difference = targetWeight - currentWeight;

    if (difference.abs() <= _goalEpsilonKg) {
      return tdee;
    }

    if (difference > 0) {
      return tdee + 500;
    }

    return (tdee - 500).clamp(1200, tdee);
  }

  /// Calculate all values at once for convenience
  static Map<String, double> calculateAll({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
    required String activityLevel,
    double? targetWeight,
  }) {
    final bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      isMale: isMale,
    );

    final tdee = calculateTDEE(bmr: bmr, activityLevel: activityLevel);

    final goalCalories = targetWeight != null
        ? calculateGoalCalories(
            tdee: tdee,
            currentWeight: weightKg,
            targetWeight: targetWeight,
          )
        : tdee;

    // Macro split (balanced): 30% protein, 40% carbs, 30% fat
    final proteinGrams = (goalCalories * 0.30) / 4;
    final carbGrams = (goalCalories * 0.40) / 4;
    final fatGrams = (goalCalories * 0.30) / 9;

    return {
      'bmr': bmr,
      'tdee': tdee,
      'goalCalories': goalCalories,
      'proteinGrams': proteinGrams,
      'carbGrams': carbGrams,
      'fatGrams': fatGrams,
    };
  }

  /// Get a human-readable goal description
  static String getGoalDescription(double currentWeight, double targetWeight) {
    final diff = (currentWeight - targetWeight).abs();
    if (diff <= _goalEpsilonKg) return 'Maintain current weight';
    if (currentWeight > targetWeight) {
      return 'Lose ${diff.toStringAsFixed(1)} kg';
    }
    return 'Gain ${diff.toStringAsFixed(1)} kg';
  }

  /// Estimate weeks to reach target weight
  /// Assumes ~0.5 kg change per week with 500 kcal surplus/deficit
  static int estimateWeeksToGoal(double currentWeight, double targetWeight) {
    final diff = (currentWeight - targetWeight).abs();
    return (diff / 0.5).ceil();
  }
}
