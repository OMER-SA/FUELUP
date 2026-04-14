import 'package:diet_app/models/mood_types.dart';

/// Tag-Based Mood Detection System
///
/// Infers user mood from meal tags (rule-based classification).
/// This is used as a fallback/augmentation for voice-based mood detection.
///
/// Key Design:
/// - No AI/ML required (pure rule logic)
/// - 100% deterministic (same tags → same mood)
/// - Works with guaranteed rule-based meal tags
/// - Handles all tag combinations
///
/// Mood Types (5 Primary):
/// 1. happy     - healthy, fresh, energizing meals
/// 2. stressed  - comfort foods, carbs, warmth
/// 3. tired     - heavy, rich, calorie-dense meals
/// 4. sad       - comfort foods, familiar, warm
/// 5. energetic - protein, light, fresh, active meals
///
/// Secondary moods (map to primary):
/// - calm       → stressed (counter-measure)
/// - anxious    → stressed (counter-measure)
/// - unknown    → neutral/balanced

class TagBasedMoodDetector {
  /// Exact labels emitted by the on-device voice SER model.
  static const List<String> voiceMoods = <String>[
    'neutral',
    'happy',
    'surprise',
    'unpleasant',
  ];

  /// Core scoring function constrained to exact voice model labels.
  static Map<String, int> getMoodScoresFromTags(List<dynamic> tags) {
    final stringTags = _normalizeTagList(tags);

    // Initialize only with exact voice outputs.
    final scores = {
      'neutral': 0,
      'happy': 0,
      'surprise': 0,
      'unpleasant': 0,
    };

    if (stringTags.isEmpty) {
      return scores;
    }

    // Comfort and heavy/fried meals align best with "unpleasant".
    if (_hasTag(stringTags, ['comfort_food', 'fried', 'high_calorie', 'heavy', 'fat_rich', 'unhealthy'])) {
      scores['unpleasant'] = scores['unpleasant']! + 3;
    }

    // Healthy/protein/light profiles align with positive classes.
    if (_hasTag(stringTags, ['protein', 'healthy', 'light', 'low_calorie', 'balanced', 'fresh'])) {
      scores['happy'] = scores['happy']! + 2;
    }

    // Stimulating tags indicate activation/novelty, closest to "surprise".
    if (_hasTag(stringTags, ['energetic', 'spicy', 'chili', 'pepper'])) {
      scores['surprise'] = scores['surprise']! + 3;
    }

    // Neutral baseline for balanced and non-polarized meals.
    if (_hasTag(stringTags, ['balanced', 'boiled', 'steamed', 'plain'])) {
      scores['neutral'] = scores['neutral']! + 2;
    }

    // Small neutral prior prevents empty recommendation buckets.
    scores['neutral'] = scores['neutral']! + 1;

    return scores;
  }

  /// Returns exactly one label from [voiceMoods].
  static String mapTagsToVoiceMood(List<dynamic> tags) {
    final scores = getMoodScoresFromTags(tags);
    return _selectVoiceMoodFromScores(scores);
  }

  static String _selectVoiceMoodFromScores(Map<String, int> scores) {
    const priorityOrder = <String>['happy', 'unpleasant', 'surprise', 'neutral'];
    final maxScore = scores.values.fold(0, (a, b) => a > b ? a : b);

    if (maxScore <= 0) {
      return 'neutral';
    }

    for (final label in priorityOrder) {
      if (scores[label] == maxScore) {
        return label;
      }
    }

    return 'neutral';
  }

  /// Strict normalization: only pass through documented model labels.
  static String? normalizeVoiceMoodLabel(String? rawMood) {
    if (rawMood == null) {
      return null;
    }

    final normalized = rawMood.trim().toLowerCase();
    if (voiceMoods.contains(normalized)) {
      return normalized;
    }

    return null;
  }

  /// Compatibility helper: map strict voice label back to the shared mood type.
  static MoodType getMoodFromScores(Map<String, int> scores) {
    if (scores.isEmpty) {
      return MoodType.neutral;
    }

    final voiceMood = _selectVoiceMoodFromScores(scores);
    return MoodTypeConfig.fromVoiceLabel(voiceMood);
  }

  /// All-in-one function: tags → MoodType
  ///
  /// Usage:
  ///   final mood = detectMoodFromTags(meal['tags'] ?? []);
  static MoodType detectMoodFromTags(List<dynamic> tags) {
    final voiceMood = mapTagsToVoiceMood(tags);
    return MoodTypeConfig.fromVoiceLabel(voiceMood);
  }

  /// Detailed mood detection with confidence
  ///
  /// Returns: (MoodType, confidence_0_to_1)
  /// Confidence = (topScore - secondScore) / (topScore + 1)
  static (MoodType, double) detectMoodWithConfidence(List<dynamic> tags) {
    final scores = getMoodScoresFromTags(tags);

    if (scores.values.isEmpty) {
      return (MoodType.neutral, 0.0);
    }

    final sortedScores = scores.values.toList()..sort((a, b) => b.compareTo(a));
    final topScore = sortedScores.isNotEmpty ? sortedScores[0] : 0;
    final secondScore = sortedScores.length > 1 ? sortedScores[1] : 0;

    final voiceMood = mapTagsToVoiceMood(tags);
    final mood = MoodTypeConfig.fromVoiceLabel(voiceMood);

    // Confidence: higher gap between top 2 = higher confidence
    final confidence = topScore == 0 ? 0.0 : ((topScore - secondScore) / (topScore + 1.0)).clamp(0.0, 1.0);

    return (mood, confidence);
  }

  /// Get detailed scoring breakdown
  ///
  /// Useful for debugging and understanding mood derivation
  static Map<String, dynamic> getDetailedAnalysis(List<dynamic> tags) {
    final stringTags = _normalizeTagList(tags);
    final scores = getMoodScoresFromTags(tags);
    final (mood, confidence) = detectMoodWithConfidence(tags);

    return {
      'normalizedTags': stringTags,
      'scores': scores,
      'detectedMood': _moodToString(mood),
      'voiceMood': mapTagsToVoiceMood(tags),
      'confidence': confidence,
      'maxScore': scores.values.fold(0, (a, b) => a > b ? a : b),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  /// Normalize tag list to lowercase strings
  static List<String> _normalizeTagList(List<dynamic> tags) {
    return tags
        .where((tag) => tag != null && tag is String && tag.isNotEmpty)
        .map((tag) => (tag as String).toLowerCase().trim())
        .toSet()
        .toList();
  }

  /// Check if any of the searchTerms exist in tags
  static bool _hasTag(List<String> tags, List<String> searchTerms) {
    final normalizedSearchTerms = searchTerms.map((t) => t.toLowerCase()).toSet();
    return tags.any((tag) => normalizedSearchTerms.contains(tag));
  }

  /// Convert enum to string
  static String _moodToString(MoodType mood) {
    switch (mood) {
      case MoodType.happy:
        return 'happy';
      case MoodType.surprise:
        return 'surprise';
      case MoodType.unpleasant:
        return 'unpleasant';
      case MoodType.neutral:
        return 'neutral';
    }
  }
}
