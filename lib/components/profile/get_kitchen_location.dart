import 'package:diet_app/components/loading.dart';
import 'package:diet_app/providers/chef_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/get_user_location.dart';
import 'package:diet_app/utilities/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> getLocation(BuildContext context) async {
  return await showDialog(
    barrierDismissible: true,
    context: context,
    builder: (context) {
      final chefData = context.watch<CheffProvider>();
      TextEditingController addressController =
          TextEditingController(text: chefData.getAddress ?? '');
      bool addressLoading = false;
      bool loading = false;
      bool addressFetched = false; // Track if we've already tried to fetch

      final DefaultColors defaultColors = DefaultColors();
      final GlobalKey<FormState> key = GlobalKey<FormState>();
      return StatefulBuilder(builder: (context, setState) {
        // Only attempt to fetch address once if address is null and we haven't tried yet
        if (chefData.getAddress == null && !addressLoading && !addressFetched) {
          addressFetched = true;
          setState(() => addressLoading = true);
          getUserAddress().then((value) {
            if (context.mounted && value.isNotEmpty) {
              context.read<CheffProvider>().setAddress(value);
              addressController.text = value;
            }
          }).catchError((onError) {
            FlutterToast.showToast(onError.toString(), defaultColors.redColor);
          }).whenComplete(() {
            if (context.mounted) {
              setState(() => addressLoading = false);
            }
          });
        }
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kitchen Address",
                    style: TextStyle(
                        fontSize: 22,
                        color: defaultColors.richBlackColor,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  addressLoading
                      ? const LoadingSpinner()
                      : TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Address is required";
                            }
                            return null;
                          },
                          controller: addressController,
                          decoration: const InputDecoration(
                              label: Text(
                                "Address",
                              ),
                              hintText: "Enter your address"),
                        ),
                  const SizedBox(
                    height: 16,
                  ),
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
                                if (key.currentState!.validate()) {
                                  setState(() => loading = true);
                                  final chefId = Provider.of<UserIdProvider>(
                                          context,
                                          listen: false)
                                      .getUuid;
                                  await chefData.updateAddress(
                                      address: addressController.text.trim(),
                                      chefId: chefId.toString());
                                  setState(() => loading = false);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }
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
            ),
          ),
        );
      });
    },
  );
}
