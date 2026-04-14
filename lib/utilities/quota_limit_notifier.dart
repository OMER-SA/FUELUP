import 'package:diet_app/firebase/quota_guard.dart';
import 'package:flutter/material.dart';

class QuotaLimitNotifier {
  static Future<void> showIfNeeded(BuildContext context) async {
    if (!context.mounted || !QuotaGuard.instance.quotaExceeded) {
      return;
    }

    if (!QuotaGuard.instance.consumeUiNoticeFlag()) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Service Limit Reached'),
          content: Text(QuotaGuard.instance.userFacingMessage()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
