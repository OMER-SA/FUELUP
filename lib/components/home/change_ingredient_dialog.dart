import 'package:flutter/material.dart';
import 'package:diet_app/utilities/constants.dart';

Future<void> changeIngredientDialog(
    BuildContext context,
    Map<String, dynamic> currentIngredient,
    Map<String, dynamic> originalIngredient) async {
  DefaultColors defaultColors = DefaultColors();

  String currentMeasurementString = currentIngredient['measurement'];
  double? currentMeasurement = double.tryParse(
      currentMeasurementString.replaceAll(RegExp(r'[^0-9.]'), ''));

  String measurementUnit =
      currentMeasurementString.replaceAll(RegExp(r'[0-9.]'), '').trim();

  String originalMeasurementString = originalIngredient['measurement'];
  double? originalMeasurement = double.tryParse(
      originalMeasurementString.replaceAll(RegExp(r'[^0-9.]'), ''));

  double minMeasurement = 1;
  double maxMeasurement =
      (originalMeasurement != null ? originalMeasurement * 2 : 100);

  // Default if the originalMeasurement is invalid
  if (originalMeasurement == null) {
    maxMeasurement = 100;
  }

  bool invalidMeasurement = currentMeasurement == null;

  return await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Change ${currentIngredient['ingredient']}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Current Measurement: ${currentIngredient['measurement']}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (invalidMeasurement) // Show error if measurement is invalid
                    Text(
                      "Error: Invalid measurement format. Chef didn't Enter the valid measurement",
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  if (!invalidMeasurement) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adjust Measurement: ${currentMeasurement!.toStringAsFixed(0)} $measurementUnit',
                          style: TextStyle(fontSize: 16),
                        ),
                        Slider(
                          activeColor: defaultColors.primaryColor,
                          value: currentMeasurement ?? 0,
                          min: minMeasurement,
                          max: maxMeasurement,
                          divisions: (maxMeasurement - minMeasurement).toInt(),
                          label: currentMeasurement!.toStringAsFixed(0),
                          onChanged: (double value) {
                            setState(() {
                              currentMeasurement = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: defaultColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (currentMeasurement != null) {
                            currentIngredient['measurement'] =
                                '${currentMeasurement!.toStringAsFixed(0)} $measurementUnit';
                          }
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
