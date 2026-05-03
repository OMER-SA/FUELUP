import 'package:auto_height_grid_view/auto_height_grid_view.dart';
import 'package:diet_app/components/home/change_ingredient_dialog.dart';
import 'package:diet_app/modals/cart_item.dart';
import 'package:diet_app/providers/cart_provider.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/utilities/alergies_model.dart';
import 'package:diet_app/utilities/bmi_meal_filter.dart';
import 'package:diet_app/utilities/toast.dart';
import 'package:diet_app/widgets/meal_image.dart';
import 'package:flutter/material.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:provider/provider.dart';

class MealDetailScreen extends StatefulWidget {
  final Map<String, dynamic> meal;
  const MealDetailScreen({super.key, required this.meal});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  int quantity = 1;
  late List<bool> selectedIngredients;
  late CartItem currentCartItem;
  final AllergyPredictor _predictor = AllergyPredictor();
  List<String> ingredientsThatUserCannotTake = [];
  final DefaultColors defaultColor = DefaultColors();
  late List<Map<String, dynamic>> originalRecipe;
  late final List<FlipCardController> _flipCardController;
  late final List<TextEditingController> ingredientControllers;
  late final List<TextEditingController> measurementControllers;

  @override
  void initState() {
    super.initState();
    originalRecipe = (widget.meal['recipie'] as List<dynamic>)
        .map((ingredient) => Map<String, dynamic>.from(ingredient))
        .toList();

    selectedIngredients =
        List.generate(widget.meal['recipie'].length, (index) => true);
    _flipCardController = List.generate(
        widget.meal['recipie'].length, (index) => FlipCardController());

    ingredientControllers = (widget.meal['recipie'] as List<dynamic>)
        .map((item) =>
            TextEditingController(text: item['ingredient'].toString().trim()))
        .toList();

    measurementControllers = (widget.meal['recipie'] as List<dynamic>)
        .map((item) =>
            TextEditingController(text: item['measurement'].toString().trim()))
        .toList();

    updateCurrentCartItem();

    // Load predictor model and run prediction for allergies
    _predictor.loadModel().then((value) => _runPrediction());
  }

  // Run allergy prediction based on user profile
  Future<void> _runPrediction() async {
    final customerProvider =
        Provider.of<CustomerProvider>(context, listen: false);

    // Retrieve user allergies and BMI from provider
    List<String> userAllergies =
        (customerProvider.getAllergies as List<dynamic>)
            .map((e) => e.toString().toLowerCase())
            .toList();
    double bmiInput = customerProvider.calculateBmi();

    try {
      // Run prediction model with commonAllergies, userAllergies, and BMI
      var rawResult = await _predictor.predict(userAllergies, bmiInput);

      // Check prediction results and update state
      if (rawResult.isNotEmpty) {
        setState(() {
          // Store ingredients user cannot take
          ingredientsThatUserCannotTake =
              rawResult.map((e) => e.toString().toLowerCase()).toSet().toList();
          debugPrint("Ingredients user cannot take: $ingredientsThatUserCannotTake");

          // Only uncheck CHANGEABLE ingredients that match allergens.
          // Non-changeable (mandatory) ingredients stay CHECKED — we show
          // a warning instead of destroying the meal.
          selectedIngredients =
              List.generate(widget.meal['recipie'].length, (index) {
            final ingredientName =
                widget.meal['recipie'][index]['ingredient'].toLowerCase();
            final isChangeAble =
                widget.meal['recipie'][index]['isChangeAble'] == true;
            final matchesAllergen =
                ingredientsThatUserCannotTake.any((allergy) {
              final pattern = RegExp(r'\b' +
                  RegExp.escape(allergy.replaceAll(RegExp(r's$'), '')) +
                  r's?\b');
              return pattern.hasMatch(ingredientName);
            });

            // If it's changeable AND matches an allergen → uncheck it
            // If it's mandatory (non-changeable) → keep checked regardless
            if (matchesAllergen && isChangeAble) {
              return false; // uncheck
            }
            return true; // keep checked
          });
        });
      }
    } catch (e) {
      debugPrint("Error during prediction Meal Detail: $e");
    }
  }

  // Update cart item details based on selected ingredients
  void updateCurrentCartItem() {
    List<Map<String, dynamic>> selectedRecipe = [];
    for (int i = 0; i < widget.meal['recipie'].length; i++) {
      if (selectedIngredients[i]) {
        selectedRecipe.add(widget.meal['recipie'][i]);
      }
    }
    currentCartItem = CartItem(
      description: widget.meal['description'],
      name: widget.meal['mealName'],
      kitchenId: widget.meal['cheffId'],
      quantity: quantity,
      price: widget.meal['price'],
      category: widget.meal['category'],
      kitchenName: widget.meal['kitchenName'],
      recipieId: widget.meal['idMeal'],
      recipie: selectedRecipe,
      mealPicture: widget.meal['mealPicture'],
    );
  }

  // Increment and decrement quantity
  void incrementQuantity() {
    setState(() {
      quantity++;
      updateCurrentCartItem();
    });
  }

  void decrementQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
        updateCurrentCartItem();
      });
    }
  }

  /// Build a warning banner listing allergens found in this meal
  Widget _buildAllergenWarningBanner() {
    if (ingredientsThatUserCannotTake.isEmpty) return const SizedBox.shrink();

    // Find which meal ingredients actually match allergens
    List<String> conflictingIngredients = [];
    for (var item in widget.meal['recipie']) {
      final ingredientName =
          (item['ingredient'] ?? '').toString().toLowerCase();
      for (var allergy in ingredientsThatUserCannotTake) {
        final pattern = RegExp(
          r'\b' +
              RegExp.escape(allergy.replaceAll(RegExp(r's$'), '')) +
              r's?\b',
        );
        if (pattern.hasMatch(ingredientName) &&
            !conflictingIngredients
                .contains(item['ingredient'].toString().trim())) {
          conflictingIngredients.add(item['ingredient'].toString().trim());
        }
      }
    }

    if (conflictingIngredients.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: defaultColor.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: defaultColor.warningColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: defaultColor.warningColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allergen Warning',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: defaultColor.warningColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This meal contains ingredients that may conflict with your dietary restrictions: ${conflictingIngredients.join(", ")}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cartProvider = context.read<CartProvider>();
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal Image
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: MealImage(
                    meal: widget.meal,
                    fit: BoxFit.cover,
                  ),
                ),
                // Allergen Warning Banner
                _buildAllergenWarningBanner(),
                // Quantity Control
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: defaultColor.primaryColor.withValues(alpha: 0.03),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: decrementQuantity),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: defaultColor.primaryColor.withValues(alpha: 0.1),
                        ),
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: defaultColor.primaryColor),
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: incrementQuantity),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(widget.meal['mealName'],
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                          Text(
                            '${widget.meal['price']} Rs',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: defaultColor.primaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Chef Name and Category
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Chef: ${widget.meal['kitchenName']}',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600])),
                          Text('Category: ${widget.meal['category']}',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Calorie & BMI Advice
                      _buildCalorieAndAdvice(),
                      const SizedBox(height: 16),
                      // Description
                      const Text('Description',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(widget.meal['description'],
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      const Text('Ingredients',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // Ingredients List with FlipCard
                      AutoHeightGridView(
                        rowCrossAxisAlignment: CrossAxisAlignment.start,
                        crossAxisCount: screenWidth > 600 ? 3 : 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: widget.meal['recipie'].length,
                        builder: (context, index) {
                          final isChangeAble = widget.meal['recipie'][index]
                                  ['isChangeAble'] ==
                              true;
                          final String ingredient = widget.meal['recipie']
                                  [index]['ingredient']
                              .toString()
                              .trim();
                          final String measurement = widget.meal['recipie']
                                  [index]['measurement']
                              .toString()
                              .trim();
                          final bool isFlipable = isChangeAble &&
                              !selectedIngredients[index] &&
                              ingredientsThatUserCannotTake.any((allergy) {
                                final pattern = RegExp(r'\b' +
                                    RegExp.escape(
                                        allergy.replaceAll(RegExp(r's$'), '')) +
                                    r's?\b');
                                return pattern
                                    .hasMatch(ingredient.toLowerCase());
                              });
                          final bool isAllergen =
                              ingredientsThatUserCannotTake.any((allergy) {
                            final pattern = RegExp(r'\b' +
                                RegExp.escape(
                                    allergy.replaceAll(RegExp(r's$'), '')) +
                                r's?\b');
                            return pattern.hasMatch(ingredient.toLowerCase());
                          });

                          return FlipCard(
                            rotateSide: RotateSide.bottom,
                            controller: _flipCardController[index],
                            backWidget: _buildBackWidget(index),
                            frontWidget: _buildFrontWidget(
                                index,
                                isChangeAble,
                                ingredient,
                                measurement,
                                isFlipable,
                                isAllergen),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Order Button
        _buildOrderButton(cartProvider),
      ],
    );
  }

  Widget _buildBackWidget(int index) {
    return Row(
      children: [
        Flexible(
          child: Column(
            children: [
              TextField(
                  controller: ingredientControllers[index],
                  decoration: InputDecoration(labelText: "Ingredient")),
              SizedBox(height: 10),
              TextField(
                  controller: measurementControllers[index],
                  decoration: InputDecoration(labelText: "Measurement")),
            ],
          ),
        ),
        SizedBox(width: 5),
        Column(
          children: [
            IconButton(
                onPressed: () => _flipCardController[index].flipcard(),
                icon: Icon(Icons.close, color: defaultColor.redColor)),
            IconButton(
              onPressed: () {
                setState(() {
                  widget.meal['recipie'][index]['ingredient'] =
                      ingredientControllers[index].text.trim();
                  widget.meal['recipie'][index]['measurement'] =
                      measurementControllers[index].text.trim();
                  updateCurrentCartItem();
                  _flipCardController[index].flipcard();
                });
              },
              icon: Icon(Icons.check, color: defaultColor.lightGreenColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrontWidget(int index, bool isChangeAble, String ingredient,
      String measurement, bool isFlipable, bool isAllergen) {
    return GestureDetector(
      onTap: () async {
        if (isFlipable) {
          _flipCardController[index].flipcard();
        } else if (!isChangeAble && !selectedIngredients[index]) {
          FlutterToast.showToast("$ingredient is marked unchangeable by chef",
              defaultColor.redColor);
        } else if (isChangeAble && selectedIngredients[index]) {
          await changeIngredientDialog(
              context, widget.meal['recipie'][index], originalRecipe[index]);
          setState(() {
            updateCurrentCartItem();
          });
        } else if (!selectedIngredients[index]) {
          FlutterToast.showToast(
              "Please select $ingredient first before making any changes.",
              defaultColor.warningColor);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isAllergen
              ? defaultColor.warningColor.withValues(alpha: 0.08)
              : defaultColor.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAllergen
                ? defaultColor.warningColor.withValues(alpha: 0.5)
                : defaultColor.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              activeColor: defaultColor.primaryColor.withValues(alpha: 0.8),
              value: selectedIngredients[index],
              onChanged: isChangeAble
                  ? (bool? value) {
                      if (value == false &&
                          selectedIngredients.where((item) => item).length ==
                              1) {
                        return;
                      }
                      setState(() {
                        selectedIngredients[index] = value!;
                        updateCurrentCartItem();
                      });
                    }
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ingredient,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: selectedIngredients[index]
                                ? TextDecoration.none
                                : TextDecoration.lineThrough,
                            color: isAllergen
                                ? defaultColor.warningColor
                                : isChangeAble
                                    ? defaultColor.richBlackColor
                                    : defaultColor.greyColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAllergen)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: defaultColor.warningColor,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    measurement,
                    style: TextStyle(
                      fontSize: 12,
                      color: isChangeAble ? Colors.grey[600] : Colors.grey[400],
                      decoration: selectedIngredients[index]
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderButton(CartProvider cartProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: () {
          cartProvider.addItem(currentCartItem, context);
        },
        icon: const Icon(Icons.shopping_cart, color: Colors.white),
        label: Text('Add to cart ($quantity)',
            style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: defaultColor.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCalorieAndAdvice() {
    final calories = widget.meal['calories'] as int?;
    final bmi = Provider.of<CustomerProvider>(context, listen: false)
        .calculateBmi();

    if (calories == null || calories <= 0) {
      return const SizedBox.shrink();
    }

    final advice = BmiMealFilter.getCalorieAdvice(bmi, calories);
    final isRecommended = BmiMealFilter.isMealRecommended(bmi, calories);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecommended
            ? defaultColor.lightGreenColor.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isRecommended
              ? defaultColor.lightGreenColor.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department,
              color: Colors.orange[700], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$calories kcal per serving',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  advice,
                  style: TextStyle(
                    fontSize: 13,
                    color: isRecommended
                        ? defaultColor.lightGreenColor
                        : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
