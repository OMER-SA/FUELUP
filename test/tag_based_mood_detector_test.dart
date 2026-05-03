// ignore_for_file: avoid_print
import 'package:diet_app/utilities/mood_meal_filter.dart';
import 'package:diet_app/utilities/tag_based_mood_detector.dart';

void main() {
  const voiceMoods = ['neutral', 'happy', 'surprise', 'unpleasant'];

  final meals = <Map<String, dynamic>>[
    {
      'mealName': 'Steamed Veg Bowl',
      'tags': ['balanced', 'boiled', 'light'],
    },
    {
      'mealName': 'Fresh Chicken Salad',
      'tags': ['healthy', 'protein', 'fresh', 'low_calorie'],
    },
    {
      'mealName': 'Spicy Grilled Wrap',
      'tags': ['spicy', 'energetic', 'grilled', 'protein'],
    },
    {
      'mealName': 'Aloo Samosa',
      'tags': ['snack', 'fried', 'comfort_food', 'high_calorie', 'unhealthy'],
    },
  ];

  print('VOICE_MOODS: ${TagBasedMoodDetector.voiceMoods}');
  print('--- tag -> voice mood mapping ---');
  for (final meal in meals) {
    final mapped = TagBasedMoodDetector.mapTagsToVoiceMood(meal['tags'] as List<dynamic>);
    print('${meal['mealName']}: $mapped');
  }

  print('--- recommendation validation per voice mood ---');
  for (final mood in voiceMoods) {
    final recommended = MoodMealFilter.getRecommendedMeals(meals: meals, userMood: mood);
    final top = recommended.isNotEmpty ? recommended.first : null;

    if (recommended.isEmpty) {
      throw StateError('No meals returned for mood=$mood');
    }

    final topName = top?['mealName'] ?? 'unknown';
    final topMood = top?['_voiceMood'] ?? 'unknown';
    print('mood=$mood -> count=${recommended.length}, top=$topName ($topMood)');
  }

  print('Validation PASSED: all exact voice moods returned non-empty recommendations.');
}
