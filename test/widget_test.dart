import 'package:diet_app/utilities/voice_mood_detector.dart';
import 'package:diet_app/widgets/voice_mood_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Voice mood button renders idle state',
      (WidgetTester tester) async {
    final detector = VoiceMoodDetector();
    addTearDown(detector.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: VoiceMoodButton(
              detector: detector,
              onMoodDetected: (_, __, ___) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('How are you feeling?'), findsOneWidget);
    expect(find.text('Tap and speak'), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
  });
}
