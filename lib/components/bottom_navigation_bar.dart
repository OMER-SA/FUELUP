import 'package:diet_app/components/cart/delete_all_item_dialog.dart';
import 'package:diet_app/components/profile/complete_profile_modal.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/providers/cart_provider.dart';
import 'package:diet_app/utilities/get_app_bar_title.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:diet_app/firebase/realtime_database.dart';

class BottomNavigationBarPage extends StatefulWidget {
  const BottomNavigationBarPage(
      {super.key, required this.child, required this.state});
  final Widget child;
  final GoRouterState state;

  @override
  State<BottomNavigationBarPage> createState() =>
      _BottomNavigationBarPageState();
}

class _BottomNavigationBarPageState extends State<BottomNavigationBarPage> {
  int currentIndex = 0;
  final DBService dbService = DBService();
  DefaultColors defaultColors = DefaultColors();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isInitialized = false;
  String address = '';

  final Map<String, String> routeTitles = {
    '/recipie': 'Details',
    '/checkout': 'Check Out',
    '/completeProfile': 'Complete Profile',
    '/profile/updateName': 'Update Name',
    '/profile/updateEmail': 'Update Email',
    '/profile/updatePhone': 'Update Phone',
    '/profile/updateAddress': 'Update Address',
    '/profile/updateAlergies': 'Update Allergies',
    '/home/meal-detail': 'Meal Details',
    '/orders': 'Your Orders',
  };
  final List<String> routesWithNoBackButton = ['/home', '/profile'];

  final RealDataBaseService _dbService = RealDataBaseService();
  final DBService databaseService = DBService();
  int _notificationCount = 0;
  StreamSubscription<DatabaseEvent>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
    _setupNotificationListener();
  }

  Future<void> _fetchNotificationCount() async {
    final userId = context.read<UserIdProvider>().getUuid;
    if (userId != null) {
      List<String> orderStatus = [];
      final notifications = await _dbService.fetchOrdersByUserId(userId);
      for (var element in notifications) {
        if (element['status'] != 'Order Recieved') {
          orderStatus.add(element['status']);
        }
      }
      setState(() {
        _notificationCount = orderStatus.length;
      });
    }
  }

  void _setupNotificationListener() {
    final userId = context.read<UserIdProvider>().getUuid;
    if (userId != null) {
      _notificationSubscription = FirebaseDatabase.instance
          .ref()
          .child('orders') // Change 'notifications' to 'orders'
          .orderByChild('customerId') // Change 'userId' to 'customerId'
          .equalTo(userId)
          .onValue
          .listen((event) {
        if (event.snapshot.value != null) {
          List<String> orderStatus = [];
          final orders =
              (event.snapshot.value as Map<dynamic, dynamic>).values.toList();
          for (var element in orders) {
            if (element['status'] != 'Order Recieved') {
              orderStatus.add(element['status']);
            }
          }
          setState(() {
            _notificationCount = orderStatus.length;
          });
        } else {
          setState(() {
            _notificationCount = 0;
          });
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadCustomerData();
      _isInitialized = true;
    }
  }

  Future<void> _loadCustomerData() async {
    final UserIdProvider user = context.read<UserIdProvider>();
    final customerData = await dbService.getCustomer(user.getUuid.toString());

    if (customerData != null) {
      if (mounted) {
        final CustomerProvider customerProvider =
            context.read<CustomerProvider>();
        customerProvider.setCustomerData(
          address: customerData['address'],
          age: customerData['age'] ?? 0,
          allergies: customerData['alergies'] ?? [],
          firstName: customerData['firstName'],
          lastName: customerData['lastName'],
          phone: customerData['phone'],
          profilePicture: customerData['profilePicture'],
          weight: customerData['weight'] ?? 0,
          fcmToken: user.getFcmToken,
          height: customerData['height'] ?? 0,
        );

        if (!customerProvider.customerHasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            completeProfileDialog(context, _loadCustomerData);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int cartItemsLen = context.watch<CartProvider>().itemCount;
    final String routeInformation = widget.state.uri.toString();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(getRouteTitle(routeInformation, routeTitles)),
        leading: !routesWithNoBackButton.contains(routeInformation)
            ? IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    GoRouter.of(context).pop(context);
                  }
                },
                icon: const Icon(Icons.arrow_back))
            : null,
        actions: [
          routeInformation != '/orders'
              ? notificationButton(context, defaultColors)
              : const SizedBox(),
          routeInformation != '/cart'
              ? cartButton(context, cartItemsLen, defaultColors)
              : clearCartButton(cartItemsLen, context, defaultColors),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedItemColor: defaultColors.primaryColor,
        unselectedItemColor: defaultColors.richBlackColor,
        currentIndex: currentIndex,
        selectedIconTheme: const IconThemeData(size: 32),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.food_bank_outlined), label: 'Shope'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onTap: _onTap,
      ),
      body: widget.child,
    );
  }

  IconButton clearCartButton(
      int cartItemsLen, BuildContext context, DefaultColors defaultColors) {
    return IconButton(
        onPressed: () {
          if (cartItemsLen > 0) {
            deleteAllCartItemDialog(context);
          }
        },
        icon: Icon(
          Icons.delete_outline_rounded,
          color: defaultColors.redColor,
        ));
  }

  IconButton cartButton(
      BuildContext context, int cartItemsLen, DefaultColors defaultColors) {
    return IconButton(
        onPressed: () {
          context.push('/cart');
        },
        icon: Stack(
          children: [
            const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 25,
              ),
            ),
            Positioned(
              bottom: 12,
              right: 2,
              child: cartItemsLen > 0
                  ? Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4.5),
                      decoration: BoxDecoration(
                          color: defaultColors.redColor.withOpacity(0.8),
                          shape: BoxShape.circle),
                      child: Text(
                        cartItemsLen < 10 ? cartItemsLen.toString() : '9+',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    )
                  : Container(),
            ),
          ],
        ));
  }

  IconButton notificationButton(
      BuildContext context, DefaultColors defaultColors) {
    return IconButton(
        onPressed: () {
          context.push('/orders');
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
              child: _notificationCount > 0
                  ? Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(4.5),
                      decoration: BoxDecoration(
                          color: defaultColors.redColor.withOpacity(0.8),
                          shape: BoxShape.circle),
                      child: Text(
                        _notificationCount < 10
                            ? _notificationCount.toString()
                            : '9+',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    )
                  : Container(),
            ),
          ],
        ));
  }

  void _onTap(index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/profile');
        break;
      default:
        context.go('/home');
        break;
    }
    setState(() {
      currentIndex = index;
    });
  }
}
