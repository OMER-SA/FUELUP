import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class UpdateAlergiesScreen extends StatefulWidget {
  const UpdateAlergiesScreen({super.key});

  @override
  State<UpdateAlergiesScreen> createState() => _UpdateAlergiesScreenState();
}

class _UpdateAlergiesScreenState extends State<UpdateAlergiesScreen> {
  final DefaultColors defaultColors = DefaultColors();
  late List<Map<String, dynamic>> allergiesList;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final customerProvider = context.read<CustomerProvider>();
    allergiesList = CommonAllergies.allergies.map((allergy) {
      return {
        ...allergy,
        'isSelected': customerProvider.getAllergies?.contains(allergy['name'])
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.read<CustomerProvider>();
    final userProvider = context.read<UserIdProvider>();
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/profile/Pollen Allergy-bro.svg',
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 5,
              runSpacing: -5,
              children: List.generate(allergiesList.length, (int index) {
                return ChoiceChip(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  showCheckmark: false,
                  selectedColor: defaultColors.secondaryColor,
                  label: Text(allergiesList[index]['name']),
                  selected: allergiesList[index]['isSelected'],
                  onSelected: (bool value) {
                    setState(() => allergiesList[index]['isSelected'] = value);
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() => loading = true);
                        List<String> selectedAllergies = allergiesList
                            .where((allergy) => allergy['isSelected'])
                            .map((allergy) => allergy['name'] as String)
                            .toList();

                        String customerId = userProvider.getUuid.toString();

                        await customerProvider.setAllergies(
                            selectedAllergies: selectedAllergies,
                            customerId: customerId);
                        setState(() => loading = false);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: defaultColors.primaryColor),
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
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
