import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for managing BMI history readings in Firestore
///
/// Stores readings in: bmi_history/{customerId}/readings/{docId}
class BmiHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a new BMI reading
  Future<void> addReading({
    required String customerId,
    required double bmi,
    required int weight,
    required double height,
    String? note,
  }) async {
    try {
      await _firestore
          .collection('bmi_history')
          .doc(customerId)
          .collection('readings')
          .add({
        'bmi': bmi,
        'weight': weight,
        'height': height,
        'note': note ?? '',
        'recordedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding BMI reading: $e');
      rethrow;
    }
  }

  /// Get BMI history for a customer, ordered by date
  ///
  /// [months] — how many months of history to fetch (default: 6)
  Future<List<Map<String, dynamic>>> getHistory({
    required String customerId,
    int months = 6,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: months * 30));

      final snapshot = await _firestore
          .collection('bmi_history')
          .doc(customerId)
          .collection('readings')
          .where('recordedAt', isGreaterThan: Timestamp.fromDate(cutoff))
          .orderBy('recordedAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'bmi': (data['bmi'] as num).toDouble(),
          'weight': (data['weight'] as num).toInt(),
          'height': (data['height'] as num).toDouble(),
          'note': data['note'] ?? '',
          'recordedAt': (data['recordedAt'] as Timestamp?)?.toDate() ??
              DateTime.now(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching BMI history: $e');
      return [];
    }
  }

  /// Get the most recent BMI reading
  Future<Map<String, dynamic>?> getLatestReading({
    required String customerId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('bmi_history')
          .doc(customerId)
          .collection('readings')
          .orderBy('recordedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();
      return {
        'id': doc.id,
        'bmi': (data['bmi'] as num).toDouble(),
        'weight': (data['weight'] as num).toInt(),
        'height': (data['height'] as num).toDouble(),
        'note': data['note'] ?? '',
        'recordedAt': (data['recordedAt'] as Timestamp?)?.toDate() ??
            DateTime.now(),
      };
    } catch (e) {
      debugPrint('Error fetching latest BMI reading: $e');
      return null;
    }
  }

  /// Delete a specific reading
  Future<void> deleteReading({
    required String customerId,
    required String readingId,
  }) async {
    try {
      await _firestore
          .collection('bmi_history')
          .doc(customerId)
          .collection('readings')
          .doc(readingId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting BMI reading: $e');
      rethrow;
    }
  }
}
