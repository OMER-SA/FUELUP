enum MoodType {
  neutral,
  happy,
  surprise,
  unpleasant,
}

class MoodTypeConfig {
  static const List<String> voiceMoodLabels = <String>[
    'neutral',
    'happy',
    'surprise',
    'unpleasant',
  ];

  static const Map<MoodType, Map<String, List<String>>> moodFoodTags = {
    MoodType.neutral: {
      'prefer': ['balanced', 'plain', 'boiled', 'steamed', 'fresh'],
      'avoid': <String>[],
    },
    MoodType.happy: {
      'prefer': ['balanced', 'colorful', 'fresh', 'varied', 'healthy'],
      'avoid': <String>[],
    },
    MoodType.surprise: {
      'prefer': ['energetic', 'spicy', 'bright', 'novel', 'pepper'],
      'avoid': ['heavy', 'fatty'],
    },
    MoodType.unpleasant: {
      'prefer': ['warm', 'comfort_food', 'herbal', 'light', 'mild'],
      'avoid': ['caffeine', 'spicy', 'alcohol', 'sugar'],
    },
  };

  static const Map<MoodType, String> displayLabels = {
    MoodType.neutral: 'Neutral',
    MoodType.happy: 'Happy',
    MoodType.surprise: 'Surprised',
    MoodType.unpleasant: 'Unpleasant',
  };

  static const Map<MoodType, String> badgeLabels = {
    MoodType.neutral: 'Balanced',
    MoodType.happy: 'Balanced',
    MoodType.surprise: 'Energy lift',
    MoodType.unpleasant: 'Calm boost',
  };

  static const Map<MoodType, int> colorValues = {
    MoodType.neutral: 0xFF546E7A,
    MoodType.happy: 0xFF2E7D32,
    MoodType.surprise: 0xFF1565C0,
    MoodType.unpleasant: 0xFFB45309,
  };

  static MoodType? normalizeMood(dynamic input) {
    if (input == null) {
      return null;
    }

    if (input is MoodType) {
      return input;
    }

    if (input is String) {
      final normalized = input.trim().toLowerCase();
      for (final mood in MoodType.values) {
        if (mood.name == normalized) {
          return mood;
        }
      }
    }

    return null;
  }

  static String moodToLabel(MoodType mood) {
    return mood.name;
  }

  static MoodType fromVoiceLabel(String? label) {
    final normalized = normalizeMood(label);
    return normalized ?? MoodType.neutral;
  }
}

// Backward-compatible config namespace used by existing detector code.
// All values are sourced from the unified MoodTypeConfig model.
class MoodConfig {
  static const List<String> serModelLabels = MoodTypeConfig.voiceMoodLabels;

  static const Map<MoodType, String> moodLabels = MoodTypeConfig.displayLabels;

  static const Map<MoodType, String> moodBadgeLabel = MoodTypeConfig.badgeLabels;

  static const Map<MoodType, int> moodColor = MoodTypeConfig.colorValues;

  static const Map<MoodType, Map<String, List<String>>> moodFoodTags =
      MoodTypeConfig.moodFoodTags;

  static MoodType moodFromSerLabel(String? label) {
    return MoodTypeConfig.fromVoiceLabel(label);
  }
}