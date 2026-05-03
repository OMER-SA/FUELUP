/// Resolves a food image URL for a meal.
/// Priority:
///   1. meal['mealPicture'] if it is a non-null, non-empty string
///      (chef-uploaded image)
///   2. Unsplash Source URL built from meal name + tags
///      (deterministic based on meal name for consistency)
class MealImageResolver {
  MealImageResolver._();

  static String resolve(Map<String, dynamic> meal) {
    final uploaded = meal['mealPicture'];
    if (uploaded != null && uploaded is String && uploaded.isNotEmpty) {
      return uploaded;
    }

    final keyword = _buildKeyword(meal);
    final encoded = Uri.encodeComponent(keyword);
    final seed = _seedFrom(meal['mealName'] as String? ?? 'food');
    return 'https://source.unsplash.com/400x300/?food,$encoded&sig=$seed';
  }

  static String _buildKeyword(Map<String, dynamic> meal) {
    final name = (meal['mealName'] as String? ?? '').toLowerCase();
    final tags = List<String>.from(
      (meal['tags'] as List?)?.map((e) => e.toString()) ?? [],
    );

    const stopWords = {
      'with', 'and', 'the', 'a', 'in', 'on', 'of',
      'fresh', 'plain', 'mild', 'warm', 'grilled',
    };

    final nameWords = name
        .split(RegExp(r'[\s\-_]+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .take(2)
        .toList();

    const visualTags = {
      'spicy', 'colorful', 'soup', 'salad', 'rice',
      'chicken', 'salmon', 'pasta', 'wrap', 'bowl',
    };
    final boostTag = tags.firstWhere(
      (t) => visualTags.contains(t),
      orElse: () => '',
    );

    final parts = [...nameWords, if (boostTag.isNotEmpty) boostTag];
    return parts.isEmpty ? 'healthy food' : parts.join(',');
  }

  static int _seedFrom(String input) {
    var hash = 0;
    for (final c in input.codeUnits) {
      hash = (hash * 31 + c) & 0x7FFFFFFF;
    }
    return hash % 1000;
  }
}
