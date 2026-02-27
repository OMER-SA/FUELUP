import 'package:diet_app/components/loading.dart';
import 'package:diet_app/components/profile/bmi_data_widget.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class UpdatePhysicalIndormationScren extends StatefulWidget {
  final int age;
  final double height;
  final int weight;
  const UpdatePhysicalIndormationScren(
      {super.key,
      required this.age,
      required this.height,
      required this.weight});

  @override
  State<UpdatePhysicalIndormationScren> createState() =>
      _UpdatePhysicalIndormationScrenState();
}

class _UpdatePhysicalIndormationScrenState
    extends State<UpdatePhysicalIndormationScren> {
  final DefaultColors defaultColors = DefaultColors();
  bool isLoading = false;
  late int age;
  late double height;
  late int weight;

  @override
  void initState() {
    super.initState();
    age = widget.age;
    height = widget.height;
    weight = widget.weight;
  }

  @override
  Widget build(BuildContext context) {
    final customerData = context.watch<CustomerProvider>();
    final userProvider = context.watch<UserIdProvider>();
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/profile/Healthy habit-bro.svg',
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 24),
            BmiDataWidget(
                age: age,
                height: height,
                weight: weight,
                ageChange: (value) => {
                      setState(() {
                        age = value;
                      })
                    },
                heightChange: (value) => {
                      setState(() {
                        height = value;
                      })
                    },
                weightChange: (value) => {
                      setState(() {
                        weight = value;
                      })
                    }),
            const SizedBox(height: 24),
            isLoading
                ? const LoadingSpinner()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                          });
                          await customerData.setPhysicalInformation(
                              customerId: userProvider.getUuid.toString(),
                              age: age,
                              height: height,
                              weight: weight);
                          setState(() {
                            isLoading = false;
                          });
                          if (context.mounted) {
                            context.pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: defaultColors.primaryColor),
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        )),
                  ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'))
          ],
        ),
      ),
    );
  }
}
