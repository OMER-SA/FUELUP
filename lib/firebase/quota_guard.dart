import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';

class QuotaGuard {
  QuotaGuard._();

  static final QuotaGuard instance = QuotaGuard._();

  bool _quotaExceeded = false;
  DateTime? _triggeredAt;
  bool _uiNoticeShown = false;

  bool get quotaExceeded => _quotaExceeded;
  DateTime? get triggeredAt => _triggeredAt;

  void resetSession() {
    _quotaExceeded = false;
    _triggeredAt = null;
    _uiNoticeShown = false;
    developer.log('QUOTA_GUARD_RESET');
  }

  bool consumeUiNoticeFlag() {
    if (_uiNoticeShown) {
      return false;
    }
    _uiNoticeShown = true;
    return true;
  }

  bool markIfQuotaExceeded(Object error, {required String operation}) {
    if (!_isQuotaError(error)) {
      return false;
    }

    if (!_quotaExceeded) {
      _quotaExceeded = true;
      _triggeredAt = DateTime.now();
      developer.log('QUOTA_EXCEEDED_TRIGGERED: operation=$operation at=$_triggeredAt');
    } else {
      developer.log('QUOTA_EXCEEDED_ALREADY_ACTIVE: operation=$operation');
    }
    return true;
  }

  String userFacingMessage() {
    final now = DateTime.now();
    DateTime nextReset = DateTime(now.year, now.month, now.day, 12);
    if (!now.isBefore(nextReset)) {
      nextReset = nextReset.add(const Duration(days: 1));
    }
    final remaining = nextReset.difference(now);
    final hours = remaining.inHours;

    if (hours > 0) {
      return "We've reached today's usage limit. Please try again later. System will reset at 12 PM. Try again in about $hours hour${hours == 1 ? '' : 's'}.";
    }

    return "We've reached today's usage limit. Please try again later. System will reset at 12 PM.";
  }

  bool _isQuotaError(Object error) {
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      final message = (error.message ?? '').toLowerCase();
      return code == 'resource-exhausted' ||
          message.contains('resource_exhausted') ||
          message.contains('resource-exhausted') ||
          message.contains('quota exceeded');
    }

    final text = error.toString().toLowerCase();
    return text.contains('resource_exhausted') ||
        text.contains('resource-exhausted') ||
        text.contains('quota exceeded');
  }
}
