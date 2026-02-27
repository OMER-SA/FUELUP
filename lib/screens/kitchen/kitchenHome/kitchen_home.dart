import 'package:auto_height_grid_view/auto_height_grid_view.dart';
import 'package:diet_app/components/kitchen/kitchen_delete_meal_modal.dart';
import 'package:diet_app/components/loading.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/providers/chef_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class KitchenHomeScreen extends StatefulWidget {
  const KitchenHomeScreen({super.key});

  @override
  State<KitchenHomeScreen> createState() => _KitchenHomeScreenState();
}

class _KitchenHomeScreenState extends State<KitchenHomeScreen> {
  late Future<List<Map<String, dynamic>>> mealsFuture;
  final DBService dbService = DBService();

  @override
  void initState() {
    super.initState();
    mealsFuture = _loadMeals();
  }

  Future<List<Map<String, dynamic>>> _loadMeals() async {
    final userId = context.read<UserIdProvider>().getUuid;
    dynamic meals = await dbService.getKitchenMeals(userId.toString());
    return meals;
  }

  reloadPage() async {
    setState(() {
      mealsFuture = _loadMeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final DefaultColors colors = DefaultColors();
    return FutureBuilder(
      future: mealsFuture,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingSpinner();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data.length == 0) {
          return _buildEmptyKitchenWidget(colors, context);
        } else {
          final data = snapshot.data;
          return Column(
            children: [
              _buildKitchenHeader(colors, data.length),
              Flexible(
                flex: 1,
                child: AutoHeightGridView(
                  // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  //   crossAxisCount: 2,
                  //   crossAxisSpacing: 16,
                  //   mainAxisSpacing: 16,
                  //   childAspectRatio: 0.75,
                  // ),
                  rowCrossAxisAlignment: CrossAxisAlignment.center,
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: data.length,
                  builder: (context, index) {
                    return _buildMealCard(context, data[index], colors);
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildKitchenHeader(DefaultColors colors, length) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 16),
      decoration: BoxDecoration(
        color: colors.primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${context.read<CheffProvider>().getKitchenName}'s Kitchen",
            style: TextStyle(
              fontSize: 28,
              color: colors.maroonColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Manage your meals and offerings",
            style: TextStyle(
              fontSize: 16,
              color: colors.greyColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                length == 1 ? "$length Meal" : "$length Meals",
                style: TextStyle(
                  fontSize: 18,
                  color: colors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/kitchen/addMeal');
                },
                icon: Icon(Icons.add, color: colors.primaryColor),
                label: Text(
                  "Add Meal",
                  style: TextStyle(color: colors.primaryColor),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryColor.withOpacity(0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(
      BuildContext context, Map<String, dynamic> meal, DefaultColors colors) {
    return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 100,
                color: colors.secondaryColor.withOpacity(0.1),
                alignment: Alignment.center,
                child: meal['mealPicture'] != null
                    ? Image.network(
                        meal['mealPicture'],
                        fit: BoxFit.fitWidth,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Icon(Icons.restaurant_menu,
                        size: 64, color: colors.greyColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['mealName'],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: PKR ${meal['price']}',
                    style: TextStyle(fontSize: 14, color: colors.primaryColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${meal['category']}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: colors.greyColor),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: colors.lightGreenColor),
                  onPressed: () async {
                    final result = await context
                        .push<bool>('/kitchen/home/edit', extra: meal);
                    if (result == true) {
                      reloadPage();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colors.redColor),
                  onPressed: () async {
                    await deleteMealDialog(
                      context,
                      onDelete: () async {
                        await dbService.deleteKitchenMeal(
                            mealId: meal['idMeal']);
                      },
                    );

                    reloadPage();
                  },
                ),
              ],
            ),
          ],
        ));
  }

  Center _buildEmptyKitchenWidget(DefaultColors colors, BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/kitchen/empty.svg',
                width: 200,
                height: 200,
              ),
              const SizedBox(
                height: 20,
              ),
              Text(
                'Unfortunately, we dont have any data about the Meals your kitchen is offering',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.richBlackColor),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    style: ButtonStyle(
                      padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 3.5)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)))),
                      backgroundColor:
                          WidgetStatePropertyAll(colors.primaryColor),
                      side: WidgetStatePropertyAll(BorderSide(
                          width: 0.5, color: colors.richBlackColor)),
                    ),
                    onPressed: () {
                      context.go('/kitchen/addMeal');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Add Meals',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
