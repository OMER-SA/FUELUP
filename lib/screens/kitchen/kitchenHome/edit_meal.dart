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
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late String _selectedCategory;
  late TextEditingController _kitchenNameController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _recipieFormKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> recpeControllers = [];
  bool loading = false;
  bool _isAvailable = true;
  late TextEditingController _proteinController;
  XFile? _imageFile;
  final ImagePicker _picker = ImagePicker();

  static const List<String> _allTags = [
    'balanced', 'plain', 'boiled', 'steamed', 'fresh',
    'colorful', 'varied', 'healthy',
    'energetic', 'spicy', 'bright', 'novel', 'pepper',
    'warm', 'comfort_food', 'herbal', 'light', 'mild',
    'heavy', 'fatty', 'caffeine', 'alcohol', 'sugar',
    'protein', 'iron', 'b12', 'omega3', 'magnesium', 'fiber',
    'complex_carb', 'whole_grain', 'greens', 'low_fat',
    'high_protein',
  ];

  static const List<String> _allAllergens = [
    'gluten', 'dairy', 'eggs', 'soy', 'shellfish', 'fish',
    'tree_nuts', 'peanuts', 'sesame',
  ];

  static const List<String> _allDietaryLabels = [
    'vegetarian', 'vegan', 'halal', 'gluten_free',
    'high_protein', 'low_fat',
  ];

  static const List<String> _prepStyles = [
    'boiled', 'steamed', 'grilled', 'fried', 'raw', 'baked',
  ];

  late Set<String> _selectedTags;
  late Set<String> _selectedAllergens;
  late Set<String> _selectedDietaryLabels;
  late String _prepStyle;

  @override
  void initState() {
    super.initState();
    debugPrint("widget.meal: ${widget.meal}");
    _nameController = TextEditingController(text: widget.meal['mealName']);
    _descriptionController =
        TextEditingController(text: widget.meal['description'] ?? '');
    _priceController =
        TextEditingController(text: widget.meal['price'].toString());
    _selectedCategory = widget.meal['category'];
    _isAvailable = (widget.meal['available'] as bool?) ?? true;
    _kitchenNameController =
        TextEditingController(text: widget.meal['kitchenName']);
    _proteinController = TextEditingController(
        text: (widget.meal['protein'] ?? '').toString());

    _selectedTags = Set<String>.from(
        List<String>.from(widget.meal['tags'] ?? [])
            .where((t) => _allTags.contains(t)));
    _selectedAllergens = Set<String>.from(
        List<String>.from(widget.meal['allergens'] ?? [])
            .where((t) => _allAllergens.contains(t)));
    _selectedDietaryLabels = Set<String>.from(
        List<String>.from(widget.meal['dietaryLabels'] ?? [])
            .where((t) => _allDietaryLabels.contains(t)));
    final rawPrepStyle = widget.meal['prepStyle'] ?? '';
    _prepStyle =
        _prepStyles.contains(rawPrepStyle) ? rawPrepStyle : _prepStyles.first;

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
    _proteinController.dispose();
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
                    const SizedBox(height: 16),
                    _buildNutritionFields(),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Available for ordering'),
                      value: _isAvailable,
                      onChanged: (value) =>
                          setState(() => _isAvailable = value),
                    ),
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

  DropdownButtonFormField<String> _buildCategoryDropdown() {
    final categories = MealCategories.values.toSet().toList();
    final String? safeValue =
        categories.contains(_selectedCategory) ? _selectedCategory : null;

    return DropdownButtonFormField<String>(
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      iconSize: 28,
      iconEnabledColor: defaultColors.primaryColor,
      decoration: const InputDecoration(labelText: "Category"),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Select the category";
        }
        return null;
      },
      hint: const Text("Plz! select a category of food"),
      borderRadius: BorderRadius.circular(4),
      value: safeValue,
      items: categories
          .map((cat) => DropdownMenuItem<String>(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
    );
  }

  Column _buildNutritionFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meal Tags',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _allTags.map((tag) {
            final selected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag.replaceAll('_', ' ')),
              selected: selected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          'Allergens',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _allAllergens.map((tag) {
            final selected = _selectedAllergens.contains(tag);
            return FilterChip(
              label: Text(tag.replaceAll('_', ' ')),
              selected: selected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedAllergens.add(tag);
                  } else {
                    _selectedAllergens.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          'Dietary Labels',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _allDietaryLabels.map((tag) {
            final selected = _selectedDietaryLabels.contains(tag);
            return FilterChip(
              label: Text(tag.replaceAll('_', ' ')),
              selected: selected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedDietaryLabels.add(tag);
                  } else {
                    _selectedDietaryLabels.remove(tag);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _proteinController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            label: Text('Protein (g) Optional'),
            hintText: '0',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _prepStyle,
          decoration: const InputDecoration(
            label: Text('Prep Style'),
          ),
          items: _prepStyles
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _prepStyle = val);
          },
        ),
      ],
    );
  }

  void _saveMeal() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        // Pattern C guard: verify the temp file still exists before uploading.
        final file = File(_imageFile!.path);
        if (!await file.exists()) {
          throw Exception(
              'The selected image file no longer exists. Please pick it again.');
        }
        imageUrl = await dbService.uploadMealPicture(
            _imageFile!, widget.meal['idMeal']);
      }

      final normalizedTags = _selectedTags
          .map((t) => t.toLowerCase().replaceAll(' ', '_').trim())
          .where((t) => _allTags.contains(t))
          .toList();
      final normalizedAllergens = _selectedAllergens
          .map((t) => t.toLowerCase().replaceAll(' ', '_').trim())
          .where((t) => _allAllergens.contains(t))
          .toList();
      final normalizedDietaryLabels = _selectedDietaryLabels
          .map((t) => t.toLowerCase().replaceAll(' ', '_').trim())
          .where((t) => _allDietaryLabels.contains(t))
          .toList();

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
        // Only overwrite mealPicture when a new image was actually uploaded;
        // otherwise the existing URL from widget.meal is preserved via spread.
        if (imageUrl != null) 'mealPicture': imageUrl,
        'available': _isAvailable,
        'tags': normalizedTags,
        'allergens': normalizedAllergens,
        'dietaryLabels': normalizedDietaryLabels,
        'protein': double.tryParse(_proteinController.text.trim()) ?? 0.0,
        'prepStyle': _prepStyle,
      };

      debugPrint("Updated Meal: $updatedMeal");
      await dbService.updateKitchenMeal(updatedMeal);

      if (mounted) context.pop(true);
    } catch (e) {
      debugPrint('UPDATE_MEAL_ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update meal: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      // Always clears the spinner — whether update succeeded, failed, or timed out.
      if (mounted) setState(() => loading = false);
    }
  }
}
