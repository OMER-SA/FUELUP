import 'dart:async';

import 'package:diet_app/models/mood_types.dart';
import 'package:diet_app/utilities/voice_mood_detector.dart';
import 'package:diet_app/widgets/mood_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum _VoiceButtonState {
  idle,
  listening,
  tooShort,
  processing,
  result,
  error,
}

class VoiceMoodButton extends StatefulWidget {
  const VoiceMoodButton({
    super.key,
    required this.onMoodDetected,
    required this.detector,
  });

  final void Function(MoodType? mood, double confidence, MoodSource source)
      onMoodDetected;
  final VoiceMoodDetector detector;

  @override
  State<VoiceMoodButton> createState() => _VoiceMoodButtonState();
}

class _VoiceMoodButtonState extends State<VoiceMoodButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  _VoiceButtonState _state = _VoiceButtonState.idle;
  Completer<void>? _stopCompleter;
  Timer? _resetTimer;
  MoodType? _lastMood;
  MoodType? _pendingMood;
  double _pendingConfidence = 0.0;
  int _elapsedSeconds = 0;
  int _sessionId = 0;
  bool _sessionCancelled = false;
  MoodResultStatus? _errorStatus;
  String? _errorMessage;

  static const int _minimumSeconds = 3;
  static const int _maximumSeconds = 8;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (_state == _VoiceButtonState.listening ||
        _state == _VoiceButtonState.processing) {
      return;
    }

    _resetTimer?.cancel();
    final sessionId = ++_sessionId;
    final stopCompleter = Completer<void>();
    _stopCompleter = stopCompleter;
    _sessionCancelled = false;

    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!disableAnimations) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }

    setState(() {
      _state = _VoiceButtonState.listening;
      _elapsedSeconds = 0;
      _pendingMood = null;
      _pendingConfidence = 0.0;
      _errorMessage = null;
      _errorStatus = null;
    });

    late final Future<MoodResult> detectionFuture;
    try {
      detectionFuture = widget.detector.recordAndDetect(
        maxSeconds: _maximumSeconds,
        onSecondElapsed: (elapsed) {
          if (!mounted || sessionId != _sessionId || _sessionCancelled) {
            return;
          }

          setState(() {
            _elapsedSeconds = elapsed.clamp(0, _maximumSeconds);
          });

          if (elapsed >= _maximumSeconds && !stopCompleter.isCompleted) {
            stopCompleter.complete();
          }
        },
        stopSignal: () => stopCompleter.future,
      );
    } catch (error) {
      _pulseController.stop();
      _pulseController.reset();
      if (!mounted || sessionId != _sessionId || _sessionCancelled) {
        return;
      }

      setState(() {
        _state = _VoiceButtonState.error;
        _errorStatus = MoodResultStatus.error;
        _errorMessage = 'Voice detection could not start.';
      });
      debugPrint('VoiceMoodButton: failed to start detection — $error');
      return;
    }

    stopCompleter.future.then((_) {
      if (!mounted || sessionId != _sessionId || _sessionCancelled) {
        return;
      }

      if (_elapsedSeconds >= _minimumSeconds) {
        setState(() {
          _state = _VoiceButtonState.processing;
        });
      }
    });

    late final MoodResult result;
    try {
      result = await detectionFuture;
    } catch (error) {
      debugPrint('VoiceMoodButton: detection crashed — $error');
      if (!mounted || sessionId != _sessionId || _sessionCancelled) {
        return;
      }

      _pulseController.stop();
      _pulseController.reset();
      setState(() {
        _state = _VoiceButtonState.error;
        _errorStatus = MoodResultStatus.error;
        _errorMessage = 'Voice detection failed. Please try again.';
      });
      return;
    }

    if (!mounted || sessionId != _sessionId || _sessionCancelled) {
      return;
    }

    _pulseController.stop();
    _pulseController.reset();

    if (result.status == MoodResultStatus.tooShort) {
      setState(() {
        _state = _VoiceButtonState.tooShort;
        _errorMessage = null;
        _errorStatus = null;
      });
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && sessionId == _sessionId && _state == _VoiceButtonState.tooShort) {
          setState(() => _state = _VoiceButtonState.idle);
        }
      });
      return;
    }

    if (result.status == MoodResultStatus.permissionDenied) {
      setState(() {
        _state = _VoiceButtonState.error;
        _errorStatus = result.status;
        _errorMessage = 'Microphone access needed';
      });
      return;
    }

    if (result.status == MoodResultStatus.modelNotLoaded) {
      setState(() {
        _state = _VoiceButtonState.error;
        _errorStatus = result.status;
        _errorMessage = 'Voice check unavailable';
      });
      return;
    }

    if (result.status == MoodResultStatus.error) {
      setState(() {
        _state = _VoiceButtonState.error;
        _errorStatus = result.status;
        _errorMessage = 'Something went wrong while reading your voice.';
      });
      return;
    }

    setState(() {
      _pendingMood = result.mood;
      _pendingConfidence = result.confidence;
      _state = _VoiceButtonState.result;
    });
  }

  void _cancelListening() {
    if (_state != _VoiceButtonState.listening) {
      return;
    }

    _sessionCancelled = true;
    _sessionId += 1;
    if (!(_stopCompleter?.isCompleted ?? true)) {
      _stopCompleter?.complete();
    }
    _pulseController.stop();
    _pulseController.reset();
    _resetTimer?.cancel();
    setState(() {
      _state = _VoiceButtonState.idle;
      _elapsedSeconds = 0;
    });
  }

  Future<void> _finishWithMood(
    MoodType? mood, {
    double confidence = 0.0,
    required MoodSource source,
  }) async {
    widget.onMoodDetected(mood, confidence, source);
    if (!mounted) {
      return;
    }

    setState(() {
      _lastMood = mood;
      _pendingMood = mood;
      _pendingConfidence = confidence;
      _state = _VoiceButtonState.idle;
    });
  }

  Future<void> _useSelectedMood() async {
    final mood = _pendingMood;
    if (mood == null) {
      return;
    }

    await _finishWithMood(
      mood,
      confidence: _pendingConfidence,
      source: MoodSource.voice,
    );
  }

  Future<void> _openMoodPicker() async {
    final selectedMood = await showMoodPickerSheet(
      context,
      selectedMood: _pendingMood ?? _lastMood,
    );
    if (!mounted) {
      return;
    }

    if (selectedMood == null) {
      return;
    }

    setState(() {
      _lastMood = selectedMood;
      _pendingMood = selectedMood;
      _pendingConfidence = 0.0;
      _state = _VoiceButtonState.idle;
    });
  }

  Future<void> _skipMood() async {
    await _finishWithMood(null, source: MoodSource.unknown);
  }

  Future<void> _openSettings() async {
    await openAppSettings();
  }

  void _resetToIdle() {
    if (!mounted) {
      return;
    }

    setState(() {
      _state = _VoiceButtonState.idle;
      _pendingMood = null;
      _pendingConfidence = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _state == _VoiceButtonState.idle ? _startListening : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildStateContent(context),
        ),
      ),
    );
  }

  Widget _buildStateContent(BuildContext context) {
    switch (_state) {
      case _VoiceButtonState.idle:
        return _buildIdleState(context);
      case _VoiceButtonState.listening:
        return _buildListeningState(context);
      case _VoiceButtonState.tooShort:
        return _buildTooShortState(context);
      case _VoiceButtonState.processing:
        return _buildProcessingState(context);
      case _VoiceButtonState.result:
        return _buildResultState(context);
      case _VoiceButtonState.error:
        return _buildErrorState(context);
    }
  }

  Widget _buildIdleState(BuildContext context) {
    final lastMood = _lastMood;
    return Semantics(
      label: 'Detect mood from voice. Double tap to start recording.',
      button: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 2),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic_none_rounded,
              size: 32,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'How are you feeling?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap and speak',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (lastMood != null) ...[
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _openMoodPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Last: ${MoodTypeConfig.displayLabels[lastMood] ?? lastMood.name}  ·  Change',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListeningState(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final progress = (_elapsedSeconds / _maximumSeconds).clamp(0.0, 1.0);
    final activeColor = Theme.of(context).colorScheme.primary;
    final neutralColor = Theme.of(context).colorScheme.outlineVariant;
    final barColor = _elapsedSeconds >= _minimumSeconds ? activeColor : neutralColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Stop recording and detect mood',
          button: true,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!disableAnimations)
                ScaleTransition(
                  scale: _pulseScale,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: activeColor.withValues(alpha: 0.10),
                    ),
                  ),
                ),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor.withValues(alpha: disableAnimations ? 0.12 : 0.18),
                  border: Border.all(
                    color: activeColor.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.mic,
                  color: activeColor,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Listening...',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Speak naturally',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 8,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: constraints.maxWidth * progress,
                    color: barColor,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: _cancelListening,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () {
                if (_elapsedSeconds < _minimumSeconds) {
                  if (!(_stopCompleter?.isCompleted ?? true)) {
                    _stopCompleter?.complete();
                  }
                  setState(() => _state = _VoiceButtonState.tooShort);
                  _resetTimer?.cancel();
                  _resetTimer = Timer(const Duration(seconds: 3), () {
                    if (mounted && _state == _VoiceButtonState.tooShort) {
                      setState(() => _state = _VoiceButtonState.idle);
                    }
                  });
                  return;
                }

                if (!(_stopCompleter?.isCompleted ?? true)) {
                  _stopCompleter?.complete();
                }
              },
              child: const Text('Done ✓'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTooShortState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mic_none_rounded,
          size: 32,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        const Text(
          'Just a little more',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Hold for 3 seconds or more',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () {
            setState(() => _state = _VoiceButtonState.idle);
          },
          child: const Text('Try again'),
        ),
      ],
    );
  }

  Widget _buildProcessingState(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        SizedBox(height: 12),
        Text(
          'Reading your energy...',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildResultState(BuildContext context) {
    final mood = _pendingMood ?? MoodType.neutral;
    final color = Color(
      MoodTypeConfig.colorValues[mood] ?? MoodTypeConfig.colorValues[MoodType.neutral]!,
    );
    final confidence = _pendingConfidence.clamp(0.0, 1.0);
    final confidenceLabel = confidence >= 0.70
        ? 'Strong read'
        : confidence >= 0.50
            ? 'Best guess'
            : 'Not sure — is this right?';
    final showBar = confidence >= 0.50;
    final barOpacity = confidence >= 0.70 ? 1.0 : 0.6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic, size: 12, color: Colors.purple.shade400),
            const SizedBox(width: 4),
            Text(
              'Detected from your voice',
              style: TextStyle(
                fontSize: 11,
                color: Colors.purple.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'You seem ${MoodTypeConfig.displayLabels[mood] ?? mood.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (showBar) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 7,
              backgroundColor: color.withValues(alpha: 0.12),
              color: color.withValues(alpha: barOpacity),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            confidenceLabel,
            style: TextStyle(
              color: color.withValues(alpha: barOpacity),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else ...[
          Text(
            confidenceLabel,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          _mealContextCopy(mood),
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _useSelectedMood,
                child: const Text('Use this'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _resetToIdle,
                child: const Text('Try again'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _openMoodPicker,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.secondary,
            ),
            child: const Text(
              'Pick mood manually',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final isPermissionDenied = _errorStatus == MoodResultStatus.permissionDenied;
    final isModelError = _errorStatus == MoodResultStatus.modelNotLoaded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mic_off_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 30,
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage ?? 'Something went wrong.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          isPermissionDenied
              ? 'Allow microphone in Settings to use voice detection.'
              : 'You can still pick your mood below.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        if (isPermissionDenied) ...[
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _openSettings,
                  child: const Text('Open Settings'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _skipMood,
                  child: const Text('Skip'),
                ),
              ),
            ],
          ),
        ] else if (isModelError) ...[
          FilledButton(
            onPressed: _openMoodPicker,
            child: const Text('Pick mood manually'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _skipMood,
            child: const Text('Skip mood'),
          ),
        ] else ...[
          FilledButton(
            onPressed: _startListening,
            child: const Text('Try again'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _skipMood,
            child: const Text('Skip mood'),
          ),
        ],
      ],
    );
  }

  String _mealContextCopy(MoodType mood) {
    switch (mood) {
      case MoodType.unpleasant:
        return 'Showing meals to calm your mind';
      case MoodType.surprise:
        return 'Showing meals to lift your energy';
      case MoodType.happy:
        return 'Showing balanced meals for your great mood';
      case MoodType.neutral:
        return 'Showing meals optimised for your goals';
    }
  }
}
