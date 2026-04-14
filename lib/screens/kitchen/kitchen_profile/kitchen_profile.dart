import 'dart:developer' as developer;

import 'package:diet_app/components/loading.dart';
import 'package:diet_app/components/profile/profile_card.dart';
import 'package:diet_app/firebase/auth_service.dart';
import 'package:diet_app/firebase/firebase_storage.dart';
import 'package:diet_app/providers/chef_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class KitchenProfileScreen extends StatefulWidget {
  const KitchenProfileScreen({super.key});

  @override
  State<KitchenProfileScreen> createState() => _KitchenProfileScreenState();
}

class _KitchenProfileScreenState extends State<KitchenProfileScreen> {
  bool loading = false;
  DefaultColors defaultColors = DefaultColors();
  final Authentication authentication = Authentication();
  bool imgLoading = false;
  final FirebaseDataStorage _firebaseStorage = FirebaseDataStorage();
  bool _isPickerActive = false;

  Future<void> _pickAndUploadImage() async {
    if (_isPickerActive) {
      debugPrint('Image picker is already active');
      return;
    }

    setState(() {
      _isPickerActive = true;
      imgLoading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        debugPrint('No image selected');
        return;
      }

      XFile imageFile = XFile(image.path);
      if (!mounted) return;
      String customerId = context.read<UserIdProvider>().getUuid.toString();

      String downloadURL = await _firebaseStorage.uploadProfilePicture(
          imageFile, customerId, 'customer');

      if (!mounted) return;
      await context
          .read<CheffProvider>()
          .updateProfilePicturePathToDB(downloadURL, customerId);

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
    final cheffCredentials = context.watch<CheffProvider>();
    debugPrint(
        "cheffCredentials.getProfilePicture::::::: ${cheffCredentials.getProfilePicture}");
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
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
                    child: cheffCredentials.getProfilePicture != null
                        ? Image.network(
                            cheffCredentials.getProfilePicture.toString(),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
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
                          icon:
                              const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed:
                              _isPickerActive ? null : _pickAndUploadImage,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProfileCard(
            icon: Icons.person,
            name: cheffCredentials.getKitchenName.toString(),
            title: 'Kitchen Name',
            btnPressed: () {
              context.push('/kitchen/profile/updateName');
            },
          ),
          const SizedBox(height: 10),
          ProfileCard(
            icon: Icons.location_on,
            name: cheffCredentials.getAddress.toString(),
            title: 'Address',
            btnPressed: () {
              context.push('/kitchen/profile/updateAddress');
            },
          ),
          // const SizedBox(height: 10),
          ProfileCard(
            icon: Icons.phone,
            name: cheffCredentials.getPhoneNumber.toString(),
            title: 'Phone Number',
            btnPressed: () {
              context.push('/kitchen/profile/updatePhone');
            },
          ),
          const SizedBox(height: 10),
          Container(
            child: !loading
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        style: ButtonStyle(
                          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 3.5)),
                          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)))),
                          backgroundColor: WidgetStatePropertyAll(
                              defaultColors.primaryColor),
                          side: WidgetStatePropertyAll(BorderSide(
                              width: 0.5, color: defaultColors.richBlackColor)),
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
    );
  }

  Future<void> _handleLogout() async {
    setState(() => loading = true);
    try {
      await context.read<UserIdProvider>().logout();
    } catch (e) {
      if (mounted) {
        developer.log('⚠️  KITCHEN_LOGOUT_IGNORED: error=$e');
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
