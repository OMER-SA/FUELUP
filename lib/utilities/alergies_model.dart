import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:diet_app/utilities/constants.dart';

class AllergyPredictor {
  Interpreter? _interpreter;

  final List<String> modelRecognizedAllergies = CommonAllergies.intolerances;
  final List<String> modelRecognizedOutput = CommonAllergies.outputAllergies;

  // Load the TFLite model
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/alergy_model/allergies_model_ann.tflite',
        options: InterpreterOptions()..threads = 1,
      );
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading TFLite model: $e');
    }
  }

  Future<List<String>> predict(List<String> userAllergies, double bmi) async {
    if (_interpreter == null) {
      print("Interpreter is not initialized.");
      return [];
    }

    try {
      // Prepare input with the specified structure
      List<double> input = _prepareInput(userAllergies, bmi);
      print("input: ${input}");
      Float32List modelInput = Float32List.fromList(input);
      print("input: ${modelInput}");

      // Define the output shape based on model expectations
      var output = List.generate(
          2, (_) => List.filled(modelRecognizedOutput.length, 0.0));

      // Run the model
      _interpreter?.run(modelInput, output);

      print("Raw model Output ${output}");
      // Decode the model output
      return _interpretAllergies(
          output[1], userAllergies.isEmpty ? 1 : 0.5, userAllergies);
    } catch (e) {
      print("Error during prediction: $e");
      return [];
    }
  }

  List<double> _prepareInput(List<String> userAllergies, double bmi) {
    List<double> incrementalInts =
        List<double>.generate(14, (index) => index.toDouble());
    List<double> paddingZeros = [0.0, 0.0];

    List<double> allergyFlags = modelRecognizedAllergies
        .map((allergy) =>
            userAllergies.contains(allergy.toLowerCase()) ? 1.0 : 0.0)
        .toList();

    double bmiValue = bmi;

    List<double> input = [
      ...incrementalInts,
      ...paddingZeros,
      ...allergyFlags,
      bmiValue
    ];

    return input;
  }

  List<String> _interpretAllergies(
      List<num> modelOutput, double threshold, List<String> userAllergies) {
    List<String> predictedAllergies = [...userAllergies];
    for (int i = 0; i < modelOutput.length; i++) {
      if (modelOutput[i] > threshold) {
        predictedAllergies.add(modelRecognizedOutput[i]);
      }
    }
    return predictedAllergies;
  }
}
