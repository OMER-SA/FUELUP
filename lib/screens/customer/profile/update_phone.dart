import 'package:diet_app/components/loading.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class UpdatePhoneScreen extends StatefulWidget {
  const UpdatePhoneScreen({super.key});

  @override
  State<UpdatePhoneScreen> createState() => _UpdatePhoneScreenState();
}

class _UpdatePhoneScreenState extends State<UpdatePhoneScreen> {
  bool _isLoading = false;
  final DefaultColors defaultColors = DefaultColors();
  late final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserIdProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/profile/phone.svg',
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 24),
            Text(
              "Enter your phone number as you'd like it to appear in the app.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: "Enter your phone number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                if (value.length != 11) {
                  return 'Phone number should be 11 digits';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const LoadingSpinner()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: defaultColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        await customerProvider.setPhone(
                            phone: _phoneController.text,
                            customerId: userProvider.getUuid.toString());
                        setState(() {
                          _isLoading = false;
                        });
                        if (context.mounted) {
                          context.pop();
                        }
                      },
                      child: const Text('Update Phone',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
