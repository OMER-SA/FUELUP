import 'dart:developer' as developer;

import 'package:diet_app/components/loading.dart';
import 'package:diet_app/components/profile/bmi_guage.dart';
import 'package:diet_app/components/profile/profile_card.dart';
import 'package:diet_app/firebase/firebase_storage.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DefaultColors defaultColors = DefaultColors();
  bool loading = false;
  bool imgLoading = false;
  final FirebaseDataStorage _firebaseStorage = FirebaseDataStorage();
  bool _isPickerActive = false;

  double calculatBmi(int weigth, double height) {
    if (weigth == 0 || height == 0) {
      return 0;
    }
    double heightInMeter = height / 100;
    double bmi = weigth / (heightInMeter * heightInMeter);
    return bmi;
  }

  Future<void> _pickAndUploadImage() async {
    if (_isPickerActive) {
      debugPrint('Image picker is already active');
      return;
    }

    setState(() {
      _isPickerActive = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        debugPrint('No image selected');
        return;
      }
      imgLoading = true;
      XFile imageFile = XFile(image.path);
      if (!mounted) return;
      String customerId = context.read<UserIdProvider>().getUuid.toString();

      String downloadURL = await _firebaseStorage.uploadProfilePicture(
          imageFile, customerId, 'customer');
      if (mounted) {
        await context
            .read<CustomerProvider>()
            .updateProfilePicturePathToDB(downloadURL, customerId);
      }

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile picture')),
        );
      }
    } finally {
      setState(() {
        _isPickerActive = false;
        imgLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final CustomerProvider customerProvider = context.watch<CustomerProvider>();
    final double bmi = customerProvider.calculateBmi();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Material(
                  elevation: 4,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  color: defaultColors.secondaryColor,
                  child: SizedBox(
                    width: 132.0,
                    height: 132.0,
                    child: ClipOval(
                      child: customerProvider.getProfilePicture != null
                          ? Image.network(
                              customerProvider.getProfilePicture.toString(),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              'assets/global/Family Values - Avatar.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: imgLoading
                      ? const LoadingSpinner()
                      : CircleAvatar(
                          backgroundColor: defaultColors.primaryColor,
                          radius: 20,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.white),
                            onPressed:
                                _isPickerActive ? null : _pickAndUploadImage,
                          ),
                        ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Name, Email, Phone
            ProfileCard(
              name:
                  "${customerProvider.getFirstName ?? ""} ${customerProvider.getLastName ?? ""}",
              title: 'Name',
              btnPressed: () => context.go('/profile/updateName'),
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            ProfileCard(
              name: customerProvider.getPhone ?? '',
              title: 'Phone',
              btnPressed: () => context.go('/profile/updatePhone'),
              icon: Icons.phone,
            ),
            const SizedBox(height: 16),
            ProfileCard(
              name: customerProvider.getAddress ?? '',
              title: 'Address',
              btnPressed: () => context.go('/profile/updateAddress'),
              icon: Icons.location_on,
            ),
            SizedBox(height: 16),

            // Age, Height, Weight
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Physical Info',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(
                          icon: Icon(Icons.edit,
                              color: defaultColors.primaryColor),
                          onPressed: () {
                            context.go('/profile/updatePhysicalInformation');
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn("Age",
                            "${customerProvider.getAge ?? ''}", Icons.cake),
                        _buildInfoColumn(
                            "Height",
                            "${customerProvider.getHeight ?? ''} cm",
                            Icons.height),
                        _buildInfoColumn(
                            "Weight",
                            "${customerProvider.getWeight ?? ''} kg",
                            Icons.fitness_center),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Allergies',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(
                          icon: Icon(Icons.edit,
                              color: defaultColors.primaryColor),
                          onPressed: () =>
                              context.go('/profile/updateAlergies'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if(customerProvider.getAllergies!.isEmpty)
                    Text("No Allergy Selected"),
                    if (customerProvider.getAllergies != null)
                      Wrap(
                        alignment: WrapAlignment.start,
                        runAlignment: WrapAlignment.start,
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                            customerProvider.getAllergies!.length,
                            (index) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: defaultColors.primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                    customerProvider.getAllergies![index]))),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.restaurant_menu,
                    color: defaultColors.primaryColor, size: 32),
                title: const Text('Food Preferences',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    const Text('Manage allergies and dietary choices'),
                trailing: Icon(Icons.chevron_right,
                    color: defaultColors.primaryColor),
                onTap: () => context.go('/profile/dietaryPreferences'),
              ),
            ),
            SizedBox(height: 16),

            // BMI Gauge
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: BmiGuage(bmi: bmi),
              ),
            ),
            SizedBox(height: 16),

            // My Goal Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('My Goal',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        TextButton.icon(
                          onPressed: () =>
                              context.go('/profile/goalSetting'),
                          icon: Icon(Icons.flag,
                              color: defaultColors.primaryColor, size: 18),
                          label: Text(
                              customerProvider.getTargetWeight != null
                                  ? 'Edit Goal'
                                  : 'Set Goal',
                              style: TextStyle(
                                  color: defaultColors.primaryColor)),
                        ),
                      ],
                    ),
                    if (customerProvider.getTargetWeight != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoColumn(
                              'Current',
                              '${customerProvider.getWeight ?? 0} kg',
                              Icons.monitor_weight),
                          Icon(Icons.arrow_forward,
                              color: defaultColors.primaryColor),
                          _buildInfoColumn(
                              'Target',
                              '${customerProvider.getTargetWeight!.toStringAsFixed(1)} kg',
                              Icons.flag),
                        ],
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Set a target weight to track progress',
                            style: TextStyle(color: Colors.grey[500])),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Daily Calories Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.local_fire_department,
                    color: defaultColors.primaryColor, size: 32),
                title: const Text('Calorie Calculator',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Calculate your daily calorie needs'),
                trailing: Icon(Icons.chevron_right,
                    color: defaultColors.primaryColor),
                onTap: () => context.go('/profile/calorieCalculator'),
              ),
            ),
            SizedBox(height: 16),


            Container(
              child: !loading
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          style: ButtonStyle(
                            padding: WidgetStatePropertyAll(
                                EdgeInsets.symmetric(vertical: 3.5)),
                            shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12)))),
                            backgroundColor: WidgetStatePropertyAll(
                                defaultColors.primaryColor),
                            side: WidgetStatePropertyAll(BorderSide(
                                width: 0.5,
                                color: defaultColors.richBlackColor)),
                          ),
                          onPressed: _handleLogout,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Icon(
                                  Icons.logout,
                                  color: Colors.white,
                                )
                              ],
                            ),
                          )),
                    )
                  : const LoadingSpinner(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: defaultColors.primaryColor),
        SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        SizedBox(height: 4),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Future<void> _handleLogout() async {
    setState(() => loading = true);
    try {
      await context.read<UserIdProvider>().logout();
    } catch (e) {
      if (mounted) {
        developer.log('⚠️  PROFILE_LOGOUT_IGNORED: error=$e');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
        developer.log('✅ LOGOUT_NAVIGATION_DONE: route=/auth/login');
        context.go('/auth/login');
      }
    }
  }
}
