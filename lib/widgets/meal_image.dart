import 'package:cached_network_image/cached_network_image.dart';
import 'package:diet_app/utilities/meal_image_resolver.dart';
import 'package:flutter/material.dart';

/// Displays a meal image with loading placeholder and error fallback.
/// Automatically resolves the best available image URL:
///   - chef-uploaded picture if present
///   - Unsplash food photo derived from the meal name/tags otherwise
class MealImage extends StatelessWidget {
  final Map<String, dynamic> meal;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const MealImage({
    super.key,
    required this.meal,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final url = MealImageResolver.resolve(meal);

    final image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade100,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              meal['category'] as String? ?? 'Meal',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
