import 'package:diet_app/components/loading.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/providers/chef_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:io';

class KitchenAddMealScreen extends StatefulWidget {
  const KitchenAddMealScreen({super.key});

  @override
  State<KitchenAddMealScreen> createState() => _KitchenAddMealScreenState();
}

class _KitchenAddMealScreenState extends State<KitchenAddMealScreen> {
  final DBService _dbService = DBService();
  final DefaultColors defaultColors = DefaultColors();
  String _selectedCategory = 'No Category Selected';
  final List<DropdownMenuItem> mealCategories = MealCategories.categories;

  final GlobalKey<FormState> _mealFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _recipieFormKey = GlobalKey<FormState>();
  final TextEditingController _mealNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discriptionController = TextEditingController();

  bool loading = false;

  List<Map<String, dynamic>> recpieControllers = [
    {
      "measurement": TextEditingController(),
      "ingredient": TextEditingController(),
      "calories": TextEditingController(),
      "isChangeAble": true
    }
  ];

  XFile? _image;
  bool _isPickerActive = false;

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Add Meal Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: defaultColors.richBlackColor,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading:
                      Icon(Icons.camera_alt, color: defaultColors.primaryColor),
                  title: const Text('Take Photo'),
                  subtitle: const Text('Use camera to take a picture'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library,
                      color: defaultColors.primaryColor),
                  title: const Text('Pick from Gallery'),
                  subtitle: const Text('Choose from your photo library'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickerActive) {
      return;
    }

    setState(() {
      _isPickerActive = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image == null) {
        return;
      }

      setState(() {
        _image = XFile(image.path);
      });
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      setState(() {
        _isPickerActive = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const LoadingSpinner()
        : Scaffold(
            body: Form(
              key: _mealFormKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildGetMealPicture(),
                    const SizedBox(height: 16),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    _buildMealNameAndPrice(),
                    const SizedBox(height: 16),
                    _buildDescription(),
                    const SizedBox(height: 24),
                    _buildRecipeSection(),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: _buildCreateMealButton(),
          );
  }

  Widget _buildGetMealPicture() {
    return Center(
      child: InkWell(
        onTap: _isPickerActive ? null : _showImageSourceOptions,
        customBorder: CircleBorder(),
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: defaultColors.secondaryColor.withValues(alpha: 0.1),
            border: Border.all(
              width: 2,
              color: defaultColors.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          child: _image != null
              ? ClipOval(
                  child: Image.file(
                    File(_image!.path),
                    fit: BoxFit.cover,
                    width: 150,
                    height: 150,
                  ),
                )
              : Icon(
                  Icons.camera_alt,
                  size: 60,
                  color: defaultColors.greyColor,
                ),
        ),
      ),
    );
  }

  DropdownButtonFormField _buildCategoryDropdown() {
    return DropdownButtonFormField(
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      iconSize: 28,
      iconEnabledColor: defaultColors.primaryColor,
      decoration: const InputDecoration(labelText: "Category"),
      validator: (value) {
        if (value == null || value == 'No Category Selected') {
          return "Select the category";
        }
        return null;
      },
      hint: const Text("Plz! select a category of food"),
      borderRadius: BorderRadius.circular(4),
      initialValue: _selectedCategory,
      items: mealCategories,
      onChanged: (value) {
        if (value is String) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
    );
  }

  Row _buildMealNameAndPrice() {
    return Row(
      children: [
        Flexible(
          child: TextFormField(
            controller: _mealNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Meal name is required";
              }
              return null;
            },
            decoration: const InputDecoration(
              label: Text("Meal Name"),
              hintText: "Enter Meal Name",
            ),
          ),
        ),
        const SizedBox(width: 20),
        Flexible(
          child: TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Price is required";
              }
              return null;
            },
            decoration: InputDecoration(
              prefix: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "PKR",
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    color: defaultColors.richBlackColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              label: const Text("Price"),
              hintText: "0",
            ),
          ),
        ),
      ],
    );
  }

  TextFormField _buildDescription() {
    return TextFormField(
      controller: _discriptionController,
      decoration: const InputDecoration(
        label: Text("Discription Optional"),
        hintText: "Enter Discription",
      ),
    );
  }

  Column _buildRecipeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recipe",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: defaultColors.richBlackColor,
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _recipieFormKey,
          child: Column(
            children: [
              ...recpieControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return _buildIngredientItem(index, controller);
              }),
              const SizedBox(height: 16),
              _buildAddIngredientButton(),
            ],
          ),
        ),
      ],
    );
  }

  Padding _buildIngredientItem(int index, Map<String, dynamic> controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Flexible(
            child: Column(
              children: [
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: TextFormField(
                        controller: controller['ingredient'],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Ingredient is required";
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          label: Text("Ingredient"),
                          hintText: "Enter Ingredient Name",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TextFormField(
                            readOnly: true,
                            decoration: const InputDecoration(
                              label: Text("is changeable ?"),
                            ),
                          ),
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              activeThumbColor: defaultColors.lightGreenColor,
                              value: controller['isChangeAble'],
                              onChanged: (bool value) {
                                setState(() {
                                  controller['isChangeAble'] = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: TextFormField(
                        controller: controller['measurement'],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Measurement is required";
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          label: Text("Measurement"),
                          hintText: "Enter Quantity",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: TextFormField(
                        controller: controller['calories'],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Calories required";
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          label: Text("Calories"),
                          hintText: "kcal",
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (recpieControllers.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    recpieControllers.removeAt(index);
                  });
                },
                child: Icon(
                  Icons.close,
                  color: defaultColors.redColor,
                ),
              ),
            )
        ],
      ),
    );
  }

  Container _buildAddIngredientButton() {
    return Container(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor:
              WidgetStatePropertyAll(defaultColors.lightGreenColor),
        ),
        onPressed: () {
          if (_recipieFormKey.currentState!.validate()) {
            setState(() {
              recpieControllers.add({
                "measurement": TextEditingController(),
                "ingredient": TextEditingController(),
                "calories": TextEditingController(),
                "isChangeAble": true
              });
            });
          }
        },
        child: const Text(
          'Add Ingredient',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Container _buildCreateMealButton() {
    final userIdProvider = context.watch<UserIdProvider>();
    final cheffCredentials = context.watch<CheffProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: loading
          ? const LoadingSpinner()
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: defaultColors.primaryColor,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (_mealFormKey.currentState!.validate() &&
                    _recipieFormKey.currentState!.validate()) {
                  setState(() {
                    loading = true;
                  });
                  try {
                    String? mealId = await _dbService.storeMeal(
                      category: _selectedCategory,
                      cheffId: userIdProvider.getUuid.toString(),
                      kitchenName: cheffCredentials.getKitchenName.toString(),
                      mealName: _mealNameController.text.trim(),
                      price: _priceController.text.trim(),
                      discription: _discriptionController.text.trim(),
                      recipie: recpieControllers,
                    );

                    if (mealId != null && _image != null) {
                      if (!mounted) return;
                      String downloadURL = await context
                          .read<CheffProvider>()
                          .uploadAndUpdateMealPicture(
                            imageFile: _image!,
                            cheffId: userIdProvider.getUuid.toString(),
                            mealId: mealId,
                          );
                      debugPrint('Meal picture uploaded: $downloadURL');
                    }

                    FlutterToast.showToast("Meal Created Successfully",
                        defaultColors.lightGreenColor);
                    if (mounted) {
                      context.go('/kitchen/home');
                    }
                  } catch (error) {
                    FlutterToast.showToast(
                        "Error While Creating Meal", defaultColors.redColor);
                  } finally {
                    setState(() {
                      loading = false;
                    });
                  }
                }
              },
              child: const Text(
                "Create Meal",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }
}
