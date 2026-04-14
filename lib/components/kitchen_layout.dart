import 'dart:async';

import 'package:diet_app/components/profile/get_kitchen_location.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/providers/chef_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/get_app_bar_title.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:diet_app/firebase/realtime_database.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:diet_app/utilities/order_status.dart';

class KitchenLayout extends StatefulWidget {
  final Widget child;
  final GoRouterState state;
  const KitchenLayout({super.key, required this.child, required this.state});

  @override
  State<KitchenLayout> createState() => _KitchenLayoutState();
}

class _KitchenLayoutState extends State<KitchenLayout> {
  final DefaultColors _colors = DefaultColors();
  final DBService dbService = DBService();
  int currentIndex = 0;
  bool _isInitialized = false;
  final RealDataBaseService _dbService = RealDataBaseService();
  int _orderCount = 0;
  StreamSubscription<DatabaseEvent>? _orderSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadChefData();
      _isInitialized = true;
    }
  }

  Future<void> _loadChefData() async {
    final String userId = context.read<UserIdProvider>().getUuid ?? '';

    final chefData = await dbService.getCheff(userId);
    if (chefData != null && mounted) {
      final chefProvider = context.read<CheffProvider>();
      chefProvider.setCheff(
        kitchenName: chefData['kitchenName'],
        phoneNumber: chefData['phone'],
        address: chefData['address'],
        profilePicture: chefData['profilePicture'],
      );
      if (!chefProvider.chefHasAddress) {
        await getLocation(context);
      }
    }
  }

  final Map<String, String> routeTitls = {
    '/kitchen/addMeal': 'Add Meal',
    '/kitchen/profile/updateName': 'Update Name',
    '/kitchen/profile/updatePhone': 'Update Phone',
    '/kitchen/profile/updateAddress': 'Update Address',
    '/kitchen/profile': 'Kitchen Profile',
  };

  final List<String> routesWithNoBackButton = [
    '/kitchen/home',
    '/kitchen/addMeal',
    '/kitchen/profile'
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrderCount();
    _setupOrderListener();
  }

  Future<void> _fetchOrderCount() async {
    final chefData = context.read<UserIdProvider>();
    final kitchenId = chefData.getUuid;

    if (kitchenId != null) {
      List<String> orderStatus = [];
      final orders = await _dbService.fetchOrdersByKitchenId(kitchenId);
      for (var element in orders) {
        if (element['status'] != OrderStatus.received) {
          orderStatus.add(element['status']);
        }
      }
      setState(() {
        _orderCount = orderStatus.length;
      });
    }
  }

  void _setupOrderListener() {
    final chefData = context.read<UserIdProvider>();
    final kitchenId = chefData.getUuid;

    if (kitchenId != null) {
      _orderSubscription = FirebaseDatabase.instance
          .ref()
          .child('orders')
          .orderByChild('kitchenId')
          .equalTo(kitchenId)
          .onValue
          .listen((event) {
        if (event.snapshot.value != null) {
          List<String> orderStatus = [];
          final orders =
              (event.snapshot.value as Map<dynamic, dynamic>).values.toList();
          for (var element in orders) {
            if (element['status'] != OrderStatus.received) {
              orderStatus.add(element['status']);
            }
          }
          setState(() {
            _orderCount = orderStatus.length;
          });
        } else {
          setState(() {
            _orderCount = 0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String location = widget.state.uri.toString();

    if (location.startsWith('/kitchen/home')) {
      currentIndex = 0;
    } else if (location.startsWith('/kitchen/addMeal')) {
      currentIndex = 1;
    } else if (location.startsWith('/kitchen/profile')) {
      currentIndex = 2;
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(
          getRouteTitle(location, routeTitls),
          // "${chefData.getKitchenName} kitchen",
          style: TextStyle(
            color: _colors.primaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: !routesWithNoBackButton.contains(location)
            ? IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                icon: const Icon(Icons.arrow_back))
            : null,
        actions: [
          location != '/kitchen/orders'
              ? shoppingBagButton(context, _orderCount.toInt(), _colors)
              : Container(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: _colors.primaryColor,
        unselectedItemColor: _colors.richBlackColor,
        currentIndex: currentIndex,
        selectedIconTheme: const IconThemeData(size: 32),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add Meal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onTap: _onTap,
      ),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: widget.child,
        ),
      ),
    );
  }

  void _onTap(int index) {
    setState(() {
      currentIndex = index;
    });
    switch (index) {
      case 0:
        context.go('/kitchen/home');
        break;
      case 1:
        context.go('/kitchen/addMeal');
        break;
      case 2:
        context.go('/kitchen/profile');
        break;
      default:
        context.go('/kitchen/home');
        break;
    }
  }

  IconButton shoppingBagButton(
      BuildContext context, int itemsLen, DefaultColors defaultColors) {
    return IconButton(
        onPressed: () {
          context.push('/kitchen/orders');
        },
        icon: Stack(
          children: [
            const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 25,
              ),
            ),
            Positioned(
              bottom: 12,
              right: 2,
              child: itemsLen > 0
                  ? Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4.5),
                      decoration: BoxDecoration(
                          color: defaultColors.redColor.withValues(alpha: 0.8),
                          shape: BoxShape.circle),
                      child: Text(
                        itemsLen < 10 ? itemsLen.toString() : '9+',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ));
  }
}




// final newOrder =
//               Map<String, dynamic>.from(event.snapshot.value as Map);
//           final mealData =
//               await _dbService.getMealById(newOrder['mealId'].toString());
//           newOrder['mealData'] = mealData;
//           final chefData =
//               await _dbService.getCheff(newOrder['kitchenId'].toString());
//           newOrder['chefData'] = chefData;



//             final updatedOrder =
//               Map<String, dynamic>.from(event.snapshot.value as Map);
//           final mealData =
//               await _dbService.getMealById(updatedOrder['mealId'].toString());
//           updatedOrder['mealData'] = mealData;
//           final chefData =
//               await _dbService.getCheff(updatedOrder['kitchenId'].toString());
//           updatedOrder['chefData'] = chefData;
