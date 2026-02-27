import 'package:diet_app/components/loading.dart';
import 'package:diet_app/providers/chef_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class KitchenUpdateNameScreen extends StatefulWidget {
  const KitchenUpdateNameScreen({super.key});

  @override
  State<KitchenUpdateNameScreen> createState() =>
      _KitchenUpdateNameScreenState();
}

class _KitchenUpdateNameScreenState extends State<KitchenUpdateNameScreen> {
  final DefaultColors defaultColors = DefaultColors();
  final TextEditingController _kitchenNameController = TextEditingController();
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    final chefProvider = context.read<CheffProvider>();
    final userProvider = context.read<UserIdProvider>();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/profile/ID Card.svg',
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 24),
            Text(
              "Enter your name as you'd like it to appear in the app.",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildTextField(_kitchenNameController, 'Kitchen Name'),
            const SizedBox(height: 32),
            _isLoading
                ? const LoadingSpinner()
                : _buildUpdateButton(chefProvider, userProvider),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Enter your $label',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.person_outline),
      ),
    );
  }

  Widget _buildUpdateButton(
      CheffProvider customerProvider, UserIdProvider userProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: defaultColors.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () => _updateName(customerProvider, userProvider),
        child: const Text('Update Name',
            style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  Future<void> _updateName(
      CheffProvider chefProvider, UserIdProvider userProvider) async {
    setState(() => _isLoading = true);

    try {
      await chefProvider.setKitchenName(
          kitchenName: _kitchenNameController.text,
          cheffId: userProvider.getUuid.toString());
          
      if (mounted) {
        context.pop();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
