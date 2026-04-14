import 'dart:math' as math;

class MFCCExtractor {
  static const double _preEmphasis = 0.97;
  static const double _logFloor = 1e-10;

  static List<List<double>> extract(
    List<double> audioSamples, {
    int sampleRate = 22050,
    int numMFCC = 13,
    int frameSize = 2048,
    int hopSize = 512,
    int numFilters = 128,
  }) {
    if (audioSamples.isEmpty ||
        sampleRate <= 0 ||
        numMFCC <= 0 ||
        frameSize <= 0 ||
        hopSize <= 0 ||
        numFilters <= 0) {
      return <List<double>>[];
    }

    final emphasized = _applyPreEmphasis(audioSamples);
    final frames = _frameSignal(
      emphasized,
      frameSize: frameSize,
      hopSize: hopSize,
    );
    if (frames.isEmpty) {
      return <List<double>>[];
    }

    final window = _buildHanningWindow(frameSize);
    final filterBank = _buildMelFilterBank(
      sampleRate: sampleRate,
      frameSize: frameSize,
      numFilters: numFilters,
    );
    final coefficientCount = math.min(numMFCC, numFilters);
    final mfccFrames = <List<double>>[];

    for (final frame in frames) {
      final windowedFrame = List<double>.generate(
        frameSize,
        (index) => frame[index] * window[index],
        growable: false,
      );
      final powerSpectrum = _powerSpectrum(windowedFrame);
      final melEnergies = _applyMelFilterBank(powerSpectrum, filterBank);
      final logMelEnergies = melEnergies
          .map((energy) => math.log(math.max(energy, _logFloor)))
          .toList(growable: false);

      final coefficients = List<double>.filled(numMFCC, 0.0, growable: false);
      for (var coefficient = 0;
          coefficient < coefficientCount;
          coefficient++) {
        double sum = 0.0;
        for (var index = 0; index < numFilters; index++) {
          sum += logMelEnergies[index] *
              math.cos(
                math.pi * coefficient * (index + 0.5) / numFilters,
              );
        }
        coefficients[coefficient] = sum;
      }

      mfccFrames.add(coefficients);
    }

    return mfccFrames;
  }

  static List<List<double>> normalize(List<List<double>> mfcc) {
    if (mfcc.isEmpty) {
      return <List<double>>[];
    }

    final coefficientCount = mfcc.first.length;
    if (coefficientCount == 0) {
      return mfcc.map((_) => <double>[]).toList(growable: false);
    }

    final means = List<double>.filled(coefficientCount, 0.0, growable: false);
    final variances =
        List<double>.filled(coefficientCount, 0.0, growable: false);

    for (final frame in mfcc) {
      for (var index = 0; index < coefficientCount; index++) {
        means[index] += index < frame.length ? frame[index] : 0.0;
      }
    }

    final frameCount = mfcc.length.toDouble();
    for (var index = 0; index < coefficientCount; index++) {
      means[index] /= frameCount;
    }

    for (final frame in mfcc) {
      for (var index = 0; index < coefficientCount; index++) {
        final value = index < frame.length ? frame[index] : 0.0;
        final delta = value - means[index];
        variances[index] += delta * delta;
      }
    }

    final stdDevs =
        List<double>.filled(coefficientCount, 0.0, growable: false);
    for (var index = 0; index < coefficientCount; index++) {
      stdDevs[index] = math.sqrt(variances[index] / frameCount);
    }

    return mfcc
        .map(
          (frame) => List<double>.generate(coefficientCount, (index) {
            final value = index < frame.length ? frame[index] : 0.0;
            final stdDev = stdDevs[index];
            if (stdDev == 0 || !stdDev.isFinite) {
              return 0.0;
            }
            return (value - means[index]) / stdDev;
          }, growable: false),
        )
        .toList(growable: false);
  }

  static List<double> _applyPreEmphasis(List<double> audioSamples) {
    if (audioSamples.isEmpty) {
      return <double>[];
    }

    final emphasized =
        List<double>.filled(audioSamples.length, 0.0, growable: false);
    emphasized[0] = audioSamples[0];

    for (var index = 1; index < audioSamples.length; index++) {
      emphasized[index] =
          audioSamples[index] - (_preEmphasis * audioSamples[index - 1]);
    }

    return emphasized;
  }

  static List<List<double>> _frameSignal(
    List<double> signal, {
    required int frameSize,
    required int hopSize,
  }) {
    if (signal.isEmpty) {
      return <List<double>>[];
    }

    if (signal.length <= frameSize) {
      final padded = List<double>.filled(frameSize, 0.0, growable: false);
      for (var index = 0; index < signal.length; index++) {
        padded[index] = signal[index];
      }
      return <List<double>>[padded];
    }

    final frameCount = ((signal.length - frameSize) / hopSize).ceil() + 1;
    final frames = <List<double>>[];

    for (var frameIndex = 0; frameIndex < frameCount; frameIndex++) {
      final start = frameIndex * hopSize;
      final frame = List<double>.filled(frameSize, 0.0, growable: false);
      for (var offset = 0; offset < frameSize; offset++) {
        final sampleIndex = start + offset;
        if (sampleIndex >= signal.length) {
          break;
        }
        frame[offset] = signal[sampleIndex];
      }
      frames.add(frame);
    }

    return frames;
  }

  static List<double> _buildHanningWindow(int frameSize) {
    if (frameSize <= 1) {
      return List<double>.filled(frameSize, 1.0, growable: false);
    }

    return List<double>.generate(
      frameSize,
      (index) =>
          0.5 - (0.5 * math.cos((2 * math.pi * index) / (frameSize - 1))),
      growable: false,
    );
  }

  static List<double> _powerSpectrum(List<double> frame) {
    final frameSize = frame.length;
    final spectrumSize = (frameSize ~/ 2) + 1;
    final power = List<double>.filled(spectrumSize, 0.0, growable: false);

    for (var bin = 0; bin < spectrumSize; bin++) {
      double real = 0.0;
      double imaginary = 0.0;

      for (var sample = 0; sample < frameSize; sample++) {
        final angle = (2 * math.pi * bin * sample) / frameSize;
        real += frame[sample] * math.cos(angle);
        imaginary -= frame[sample] * math.sin(angle);
      }

      power[bin] = ((real * real) + (imaginary * imaginary)) / frameSize;
    }

    return power;
  }

  static List<List<double>> _buildMelFilterBank({
    required int sampleRate,
    required int frameSize,
    required int numFilters,
  }) {
    final nyquist = sampleRate / 2.0;
    final melLow = _hzToMel(0);
    final melHigh = _hzToMel(nyquist);

    final melPoints = List<double>.generate(
      numFilters + 2,
      (index) => melLow + ((melHigh - melLow) * index / (numFilters + 1)),
      growable: false,
    );
    final hzPoints =
        melPoints.map(_melToHz).toList(growable: false);
    final maxBin = frameSize ~/ 2;
    final bins = hzPoints
        .map(
          (hz) => (((frameSize + 1) * hz) / sampleRate)
              .floor()
              .clamp(0, maxBin),
        )
        .toList(growable: false);

    return List<List<double>>.generate(numFilters, (filterIndex) {
      final filter = List<double>.filled(maxBin + 1, 0.0, growable: false);
      final left = bins[filterIndex];
      final center = bins[filterIndex + 1];
      final right = bins[filterIndex + 2];

      if (center == left || right == center) {
        return filter;
      }

      for (var bin = left; bin < center; bin++) {
        filter[bin] = (bin - left) / (center - left);
      }
      for (var bin = center; bin <= right; bin++) {
        filter[bin] = (right - bin) / (right - center);
      }

      return filter;
    }, growable: false);
  }

  static List<double> _applyMelFilterBank(
    List<double> powerSpectrum,
    List<List<double>> filterBank,
  ) {
    return filterBank.map((filter) {
      double energy = 0.0;
      for (var index = 0; index < powerSpectrum.length; index++) {
        energy += powerSpectrum[index] * filter[index];
      }
      return energy;
    }).toList(growable: false);
  }

  static double _hzToMel(num frequencyHz) {
    return 2595 * math.log(1 + (frequencyHz / 700)) / math.ln10;
  }

  static double _melToHz(num mel) {
    return 700 * (math.pow(10, mel / 2595) - 1).toDouble();
  }
}
