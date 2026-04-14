import 'dart:async';

import 'package:diet_app/components/loading.dart';
import 'package:diet_app/components/profile/bmi_data_widget.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/modals/complete_profile_modal.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/get_user_location.dart';
import 'package:diet_app/utilities/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> completeProfileDialog(
    BuildContext context, void Function() relaodPage,
    {bool dissmissable = false}) async {
  return await showDialog<void>(
      barrierDismissible: dissmissable,
      context: context,
      builder: (BuildContext context) {
        DefaultColors defaultColors = DefaultColors();
        final customerData = context.watch<CustomerProvider>();

        DBService dbService = DBService();
        double height = customerData.getHeight ?? 0;
        int weight = customerData.getWeight ?? 0;
        int age = customerData.getAge ?? 0;

        List<String> selectedAllergies = [];
        bool loading = false;
        bool addressLoading = false;

        // Use addressLoading in a conditional statement

        String heightError = '';
        String ageError = '';
        String weightError = '';
        String addressError = '';
        TextEditingController addressController =
            TextEditingController(text: customerData.getAddress ?? '');

        return StatefulBuilder(
          builder: (context, setState) {
            if (customerData.getAddress == null) {
              setState(() {
                addressLoading = true;
              });
              Future<String> userPosition = getUserAddress();
              userPosition
                  .then((value) => {
                        if (context.mounted)
                          context
                              .read<CustomerProvider>()
                              .setAddress(address: value),
                        setState(() {
                          addressLoading = false;
                        })
                      })
                  .catchError((onError) =>
                      {FlutterToast.showToast(onError, defaultColors.redColor)})
                  .whenComplete(() {
                setState(() => addressLoading = false);
              });
            }

            if (selectedAllergies.isEmpty &&
                customerData.getAllergies != null) {
              selectedAllergies = List<String>.from(customerData.getAllergies!);
              for (var allergy in CommonAllergies.allergies) {
                allergy['isSelected'] =
                    selectedAllergies.contains(allergy['name']);
              }
            }

            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Complete Your Profile",
                          style: TextStyle(
                              fontSize: 22,
                              color: defaultColors.richBlackColor,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        BmiDataWidget(
                          age: customerData.getAge ?? 0,
                          weight: customerData.getWeight ?? 0,
                          height: customerData.getHeight ?? 0,
                          heightChange: (changedHeight) {
                            setState(() => height = changedHeight);
                          },
                          ageChange: (changedAge) {
                            setState(() {
                              age = changedAge;
                            });
                          },
                          weightChange: (changedWeight) {
                            setState(() {
                              weight = changedWeight;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Choose Your Allergies",
                          style: TextStyle(
                              fontSize: 22,
                              color: defaultColors.richBlackColor,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                            spacing: 5,
                            runSpacing: -5,
                            children: List.generate(
                                CommonAllergies.allergies.length, (int index) {
                              return ChoiceChip(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                showCheckmark: false,
                                selectedColor: defaultColors.secondaryColor,
                                label: Text(
                                    CommonAllergies.allergies[index]['name']),
                                selected: CommonAllergies.allergies[index]
                                    ['isSelected'],
                                onSelected: (bool value) {
                                  setState(() {
                                    CommonAllergies.allergies[index]
                                        ['isSelected'] = value;
                                    if (value) {
                                      selectedAllergies.add(CommonAllergies
                                          .allergies[index]['name']);
                                    } else {
                                      selectedAllergies.remove(CommonAllergies
                                          .allergies[index]['name']);
                                    }
                                  });
                                },
                              );
                            })),
                        const SizedBox(height: 10),
                        addressLoading
                            ? const LoadingSpinner()
                            : TextField(
                                controller: addressController,
                                decoration: const InputDecoration(
                                    label: Text(
                                      "Address",
                                    ),
                                    hintText: "Enter your address"),
                              ),
                        const SizedBox(height: 10),
                        if (heightError.isNotEmpty)
                          Text(heightError,
                              style: TextStyle(color: defaultColors.redColor)),
                        if (ageError.isNotEmpty)
                          Text(ageError,
                              style: TextStyle(color: defaultColors.redColor)),
                        if (weightError.isNotEmpty)
                          Text(weightError,
                              style: TextStyle(color: defaultColors.redColor)),
                        if (addressError.isNotEmpty)
                          Text(addressError,
                              style: TextStyle(color: defaultColors.redColor)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            loading
                                ? const LoadingSpinner()
                                : ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor: WidgetStatePropertyAll(
                                            defaultColors.primaryColor)),
                                    onPressed: () async {
                                      debugPrint("Height: $height, weight: $weight, age: $age");
                                      if (height == 0 ||
                                          weight == 0 ||
                                          age == 0) {
                                        if (height == 0) {
                                          heightError = "Height must not be 0";
                                        } else {
                                          heightError = '';
                                        }
                                        if (weight == 0) {
                                          weightError = "Weight must not be 0";
                                        } else {
                                          weightError = '';
                                        }
                                        if (age == 0) {
                                          ageError = "Age must not be 0";
                                        } else {
                                          ageError = '';
                                        }
                                        if (addressController.text.isEmpty) {
                                          addressError = "Address is required";
                                        } else {
                                          addressError = '';
                                        }

                                        setState(() {});
                                        return;
                                      }
                                      ageError = '';
                                      weightError = '';
                                      heightError = '';
                                      addressError = '';
                                      selectedAllergies = CommonAllergies
                                          .allergies
                                          .where((allergy) =>
                                              allergy['isSelected'] == true)
                                          .map((allergy) =>
                                              allergy['name'] as String)
                                          .toList();

                                      final String uuid =
                                          Provider.of<UserIdProvider>(context,
                                                  listen: false)
                                              .getUuid
                                              .toString();
                                      setState(() {
                                        loading = true;
                                      });
                                      await dbService
                                          .updateCustomerData(
                                              CompleteProfileData(
                                                  uuid: uuid,
                                                  age: age,
                                                  weight: weight,
                                                  address: addressController
                                                      .text
                                                      .trim(),
                                                  height: height,
                                                  commonAlergies:
                                                      selectedAllergies))
                                          .then((value) {
                                        relaodPage();
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      }).whenComplete(() {
                                        setState(() => loading = false);
                                      });
                                    },
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    )),
                          ],
                        ),
                      ],
                    ),
                  )),
            );
          },
        );
      });
}
