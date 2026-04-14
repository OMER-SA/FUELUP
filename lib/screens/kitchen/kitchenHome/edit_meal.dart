import 'package:diet_app/components/loading.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditMealScreen extends StatefulWidget {
  final Map<String, dynamic> meal;
  const EditMealScreen({super.key, required this.meal});

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  final DBService dbService = DBService();
  final DefaultColors defaultColors = DefaultColors();
  final List<DropdownMenuItem> mealCategories = MealCategories.categories;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late String _selectedCategory;
  late TextEditingController _kitchenNameController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _recipieFormKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> recpeControllers = [];
  bool loading = false;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    debugPrint("widget.meal: ${widget.meal}");
    _nameController = TextEditingController(text: widget.meal['mealName']);
    _descriptionController =
        TextEditingController(text: widget.meal['discription'] ?? '');
    _priceController =
        TextEditingController(text: widget.meal['price'].toString());
    _selectedCategory = widget.meal['category'];
    _kitchenNameController =
        TextEditingController(text: widget.meal['kitchenName']);
    for (var item in widget.meal['recipie']) {
      recpeControllers.add({
        "measurement": TextEditingController(text: item['measurement']),
        "ingredient": TextEditingController(text: item['ingredient']),
        "calories": TextEditingController(text: (item['calories'] ?? 0).toString()),
        "isChangeAble": item['isChangeAble'],
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _kitchenNameController.dispose();
    for (var controller in recpeControllers) {
      controller['measurement'].dispose();
      controller['ingredient'].dispose();
      controller['calories'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const LoadingSpinner()
        : Scaffold(
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGetMealPicture(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Basic Information'),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 16),
                    _buildMealNameAndPrice(),
                    const SizedBox(height: 16),
                    _buildDescription(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Recipe'),
                    _buildRecipeSection(),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: _buildUpdateMealButton(),
          );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: defaultColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildUpdateMealButton() {
    return Container(
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
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: defaultColors.primaryColor,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () async {
          if (_formKey.currentState!.validate() &&
              _recipieFormKey.currentState!.validate()) {
            _saveMeal();
          }
        },
        child: const Text(
          "Update Meal",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Column _buildRecipeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Form(
          key: _recipieFormKey,
          child: Column(
            children: [
              ...recpeControllers.asMap().entries.map((entry) {
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
              recpeControllers.add({
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
                TextFormField(
                  controller: controller['measurement'],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Measurement is required";
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    label: Text("Measurement"),
                    hintText: "Enter Quantity of Ingredient",
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: controller['calories'],
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    label: Text("Calories (kcal)"),
                    hintText: "Enter calories",
                  ),
                ),
              ],
            ),
          ),
          if (recpeControllers.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    recpeControllers.removeAt(index);
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

  TextFormField _buildDescription() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        label: Text("Description Optional"),
        hintText: "Enter Description",
      ),
    );
  }

  Widget _buildGetMealPicture() {
    return Center(
      child: InkWell(
        onTap: _selectImage,
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
          child: ClipOval(
            child: _imageFile != null
                ? Image.file(
                    File(_imageFile!.path),
                    fit: BoxFit.cover,
                    width: 150,
                    height: 150,
                  )
                : widget.meal['mealPicture'] != null
                    ? Image.network(
                        widget.meal['mealPicture'],
                        fit: BoxFit.cover,
                        width: 150,
                        height: 150,
                      )
                    : Icon(
                        Icons.camera_alt,
                        size: 60,
                        color: defaultColors.greyColor,
                      ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = XFile(pickedFile.path);
      });
    }
  }

  Row _buildMealNameAndPrice() {
    return Row(
      children: [
        Flexible(
          child: TextFormField(
            controller: _nameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Meal name is required";
              }
              return null;
            },
            decoration: const InputDecoration(
              label: Text("Meal Name"),
              hintText: "Enter Ingredient",
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

  void _saveMeal() async {
    setState(() {
      loading = true;
    });

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl =
          await dbService.uploadMealPicture(_imageFile!, widget.meal['idMeal']);
    }

    final updatedMeal = {
      ...widget.meal,
      'mealName': _nameController.text,
      'description': _descriptionController.text,
      'price': int.tryParse(_priceController.text) ?? 0,
      'category': _selectedCategory,
      'kitchenName': _kitchenNameController.text,
      'recipie': recpeControllers
          .map((controller) => {
                'measurement': controller['measurement'].text,
                'ingredient': controller['ingredient'].text,
                'calories': int.tryParse(controller['calories'].text) ?? 0,
                'isChangeAble': controller['isChangeAble'],
              })
          .toList(),
      'calories': recpeControllers.fold<int>(0, (sum, c) {
        return sum + (int.tryParse(c['calories'].text) ?? 0);
      }),
      if (imageUrl != null) 'mealPicture': imageUrl,
    };

    debugPrint("Updated Meal: $updatedMeal");

    await dbService.updateKitchenMeal(updatedMeal);
    setState(() {
      loading = false;
    });
    if (mounted) {
      context.pop(true); // Return true to indicate a change was made
    }
  }
}
