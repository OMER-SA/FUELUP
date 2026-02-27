import 'package:diet_app/components/loading.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/get_user_location.dart';
import 'package:diet_app/utilities/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class UpdateAddress extends StatefulWidget {
  const UpdateAddress({super.key});

  @override
  State<UpdateAddress> createState() => _UpdateAddressState();
}

class _UpdateAddressState extends State<UpdateAddress> {
  final DefaultColors defaultColors = DefaultColors();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserIdProvider>(context, listen: false);
    final customerProvider =
        Provider.of<CustomerProvider>(context, listen: false);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/profile/undraw_delivery_address_re_cjca.svg',
                width: 250,
                height: 250,
              ),
              const SizedBox(height: 24),
              Text(
                "Enter your Address as you'd like it to appear in the app.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _addressController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "This address is required";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: "Enter your address",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const LoadingSpinner()
                  : Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: defaultColors.greyColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              setState(() {
                                _isLoading = true;
                              });
                              getUserAddress().then((value) {
                                setState(() {
                                  _addressController.text = value;
                                });
                              }).catchError((onError) {
                                FlutterToast.showToast(
                                    onError, defaultColors.redColor);
                              }).whenComplete(() {
                                setState(() => _isLoading = false);
                              });
                            },
                            child: const Text('Get Address',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white)),
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: defaultColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isLoading = true;
                                });
                                await customerProvider.updateAddress(
                                    address: _addressController.text,
                                    customerID:
                                        userProvider.getUuid.toString());
                                setState(() {
                                  _isLoading = false;
                                });
                                if (context.mounted) {
                                  context.pop();
                                }
                              }
                            },
                            child: const Text('Update Address',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel',
                    style: TextStyle(
                        fontSize: 16, color: defaultColors.primaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
