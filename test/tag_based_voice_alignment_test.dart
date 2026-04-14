import 'package:diet_app/utilities/mood_meal_filter.dart';
import 'package:diet_app/utilities/tag_based_mood_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Voice mood alignment', () {
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

    test('uses exact voice model labels', () {
      expect(
        TagBasedMoodDetector.voiceMoods,
        equals(const <String>['neutral', 'happy', 'surprise', 'unpleasant']),
      );
    });

    test('mapped meal mood is always one of voice labels', () {
      for (final meal in meals) {
        final mapped = TagBasedMoodDetector.mapTagsToVoiceMood(meal['tags'] as List<dynamic>);
        expect(TagBasedMoodDetector.voiceMoods.contains(mapped), isTrue);
      }
    });

    test('returns non-empty recommendations for each voice mood', () {
      for (final mood in TagBasedMoodDetector.voiceMoods) {
        final recommended = MoodMealFilter.getRecommendedMeals(
          meals: meals,
          userMood: mood,
        );

        expect(recommended, isNotEmpty);
      }
    });

    test('top recommendation strictly matches requested voice mood', () {
      for (final mood in TagBasedMoodDetector.voiceMoods) {
        final recommended = MoodMealFilter.getRecommendedMeals(
          meals: meals,
          userMood: mood,
        );

        final top = recommended.first;
        expect(top['_voiceMood'], equals(mood));
        expect(top['_strictMoodMatch'], isTrue);
      }
    });
  });
}
