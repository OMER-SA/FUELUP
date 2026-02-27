import 'dart:async';

import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BmiDataWidget extends StatefulWidget {
  final int age;
  final double height;
  final int weight;
  final Function(int) ageChange;
  final Function(double) heightChange;
  final Function(int) weightChange;
  const BmiDataWidget(
      {super.key,
      required this.ageChange,
      required this.heightChange,
      required this.weightChange,
      required this.age,
      required this.height,
      required this.weight});

  @override
  State<BmiDataWidget> createState() => _BmiDataWidgetState();
}

class _BmiDataWidgetState extends State<BmiDataWidget> {
  final DefaultColors colors = DefaultColors();
  late double height;
  late int weight;
  late int age;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    height = widget.height;
    weight = widget.weight;
    age = widget.age;
  }

  late TextEditingController heightController =
      TextEditingController(text: height.toString());
  late TextEditingController ageController =
      TextEditingController(text: age.toString());
  late TextEditingController weightController =
      TextEditingController(text: weight.toString());

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Height (cm)",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300),
        ),
        const SizedBox(
          height: 10,
        ),
        SizedBox(
          width: 120,
          child: TextField(
            textAlign: TextAlign.center,
            decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: colors.primaryColor, width: 4))),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            controller: heightController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
              LengthLimitingTextInputFormatter(5),
            ],
            onChanged: (value) {
              setState(() {
                height = double.tryParse(value) ?? height;
              });
              widget.heightChange(height);
            },
            onSubmitted: (value) {
              setState(() {
                height = double.tryParse(value) ?? height;
              });
              widget.heightChange(height);
            },
          ),
        ),
        Slider(
            activeColor: colors.primaryColor,
            min: 0.00,
            max: 250.00,
            value: height.clamp(0.0, 250.0),
            onChanged: (onChanged) {
              setState(() {
                height = double.parse(onChanged.toStringAsFixed(1));
                heightController.text = height.toStringAsFixed(1);
              });
              widget.heightChange(height);
            }),
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            Flexible(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Age In Years ",
                        style: TextStyle(
                            color: colors.richBlackColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w300),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(3),
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600),
                          controller: ageController,
                          onChanged: (value) {
                            setState(() {
                              age = int.tryParse(value) ?? age;
                            });
                            widget.ageChange(age);
                          },
                          onSubmitted: (value) {
                            setState(() {
                              age = int.tryParse(value) ?? age;
                            });
                            widget.ageChange(age);
                          },
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Material(
                            color: colors.primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                            child: GestureDetector(
                              onTapCancel: () {
                                timer?.cancel();
                              },
                              onTapUp: (details) {
                                timer?.cancel();
                              },
                              onLongPressEnd: (details) {
                                timer?.cancel();
                              },
                              onLongPressStart: (details) {
                                if (age > 0) {
                                  timer = Timer.periodic(
                                      const Duration(milliseconds: 50), (t) {
                                    if (age > 0) {
                                      setState(() {
                                        age = age - 1;
                                        ageController.text = age.toString();
                                      });
                                      widget.ageChange(age);
                                    }
                                    if (age < 0) {
                                      setState(() {
                                        age = 0;
                                        ageController.text = 0.toString();
                                      });
                                      widget.ageChange(age);
                                    }
                                  });
                                }
                              },
                              onTap: () {
                                if (age > 0) {
                                  setState(() {
                                    age = age - 1;
                                    ageController.text = age.toString();
                                  });
                                  widget.ageChange(age);
                                }
                                if (age < 0) {
                                  setState(() {
                                    age = 0;
                                    ageController.text = 0.toString();
                                  });
                                  widget.ageChange(age);
                                }
                              },
                              child: const Icon(
                                Icons.remove,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          Material(
                            color: colors.primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                            child: GestureDetector(
                              onTapCancel: () {
                                timer?.cancel();
                              },
                              onTapUp: (details) {
                                timer?.cancel();
                              },
                              onLongPressEnd: (details) {
                                timer?.cancel();
                              },
                              onLongPressStart: (details) {
                                timer = Timer.periodic(
                                    const Duration(milliseconds: 50), (t) {
                                  setState(() {
                                    age = age + 1;
                                    ageController.text = age.toString();
                                  });
                                  widget.ageChange(age);
                                });
                              },
                              onTap: () {
                                setState(() {
                                  age = age + 1;
                                  ageController.text = age.toString();
                                });
                                widget.ageChange(age);
                              },
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            Flexible(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Weight (kg)",
                        style: TextStyle(
                            color: colors.richBlackColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w300),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(3),
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600),
                          controller: weightController,
                          onChanged: (value) {
                            setState(() {
                              weight = int.tryParse(value) ?? weight;
                            });
                            widget.weightChange(weight);
                          },
                          onSubmitted: (value) {
                            setState(() {
                              weight = int.tryParse(value) ?? weight;
                            });
                            widget.weightChange(weight);
                          },
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Material(
                            color: colors.primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                            child: GestureDetector(
                              onTapCancel: () {
                                timer?.cancel();
                              },
                              onTapUp: (details) {
                                timer?.cancel();
                              },
                              onLongPressEnd: (details) {
                                timer?.cancel();
                              },
                              onLongPressStart: (details) {
                                if (weight > 0) {
                                  timer = Timer.periodic(
                                      const Duration(milliseconds: 50), (t) {
                                    if (weight > 0) {
                                      setState(() {
                                        weight = weight - 1;
                                        weightController.text =
                                            weight.toString();
                                      });
                                      widget.weightChange(weight);
                                    }
                                    if (weight < 0) {
                                      setState(() {
                                        weight = 0;
                                        weightController.text =
                                            weight.toString();
                                      });
                                      widget.weightChange(weight);
                                    }
                                  });
                                }
                              },
                              onTap: () {
                                if (weight > 0) {
                                  setState(() {
                                    weight = weight - 1;
                                    weightController.text = weight.toString();
                                  });
                                  widget.weightChange(weight);
                                }
                                if (weight < 0) {
                                  setState(() {
                                    weight = 0;
                                    weightController.text = weight.toString();
                                  });
                                  widget.weightChange(weight);
                                }
                              },
                              child: const Icon(
                                Icons.remove,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 30,
                          ),
                          Material(
                            color: colors.primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)),
                            child: GestureDetector(
                              onTapCancel: () {
                                timer?.cancel();
                              },
                              onTapUp: (details) {
                                timer?.cancel();
                              },
                              onLongPressEnd: (details) {
                                timer?.cancel();
                              },
                              onLongPressStart: (details) {
                                timer = Timer.periodic(
                                    const Duration(milliseconds: 50), (t) {
                                  setState(() {
                                    weight = weight + 1;
                                    weightController.text = weight.toString();
                                  });
                                  widget.weightChange(weight);
                                });
                              },
                              onTap: () {
                                setState(() {
                                  weight = weight + 1;
                                  weightController.text = weight.toString();
                                });
                                widget.weightChange(weight);
                              },
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
