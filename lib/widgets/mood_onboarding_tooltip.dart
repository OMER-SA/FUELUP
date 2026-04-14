import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoodOnboardingTooltip extends StatefulWidget {
  const MoodOnboardingTooltip({super.key});

  @override
  State<MoodOnboardingTooltip> createState() => _MoodOnboardingTooltipState();
}

class _MoodOnboardingTooltipState extends State<MoodOnboardingTooltip> {
  static const String _prefKey = 'mood_onboarded';

  bool _visible = false;
  bool _checked = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleTooltip();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _scheduleTooltip() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || prefs.getBool(_prefKey) == true) {
      _checked = true;
      return;
    }

    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) {
        return;
      }

      setState(() => _visible = true);
      _timer = Timer(const Duration(seconds: 10), _dismiss);
    });
    _checked = true;
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);

    if (!mounted) return;
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible && _checked) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !_visible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _visible ? 1 : 0,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _dismiss,
            child: Container(
              color: Colors.transparent,
              alignment: Alignment.topCenter,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              padding: const EdgeInsets.only(bottom: 96),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        'Works in any language',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Let FuelUp know how you feel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the mic, speak for a few seconds, and we\'ll suggest meals that match your mood and health goals.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton(
                                onPressed: _dismiss,
                                child: const Text('Got it'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}