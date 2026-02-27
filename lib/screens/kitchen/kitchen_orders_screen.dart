import 'dart:async';

import 'package:diet_app/components/loading.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/firebase/firebase_messaging.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/get_user_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:diet_app/firebase/realtime_database.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class KitchenOrdersScreen extends StatefulWidget {
  const KitchenOrdersScreen({super.key});

  @override
  State<KitchenOrdersScreen> createState() => _KitchenOrdersScreenState();
}

class _KitchenOrdersScreenState extends State<KitchenOrdersScreen> {
  final RealDataBaseService _dbService = RealDataBaseService();
  final DBService databaseService = DBService();
  final DefaultColors defaultColors = DefaultColors();
  final FirebaseNotificationService firebaseMessagingService =
      FirebaseNotificationService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  late StreamSubscription<DatabaseEvent>
      _ordersSubscription; // Remove the nullable type

  @override
  void initState() {
    super.initState();
    _setupOrdersListener();
  }

  @override
  void dispose() {
    _ordersSubscription.cancel();
    super.dispose();
  }

  void _setupOrdersListener() async {
    final chefData = context.read<UserIdProvider>();
    final kitchenId = chefData.getUuid;

    if (kitchenId != null) {
      _orders = await _dbService.fetchOrdersByKitchenId(kitchenId);

      _ordersSubscription =
          _dbService.listenToOrdersByKitchenId(kitchenId, (updatedOrders) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _orders = updatedOrders;
          });
        }
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String dateTimeFormate(String dateTime) {
    DateTime dateAndTime = DateTime.parse(dateTime);
    String formattedDate =
        DateFormat("d 'of' MMMM y, 'Time:' HH:mm").format(dateAndTime);
    return formattedDate;
  }

  @override
  Widget build(BuildContext context) {
    final defaultColors = DefaultColors();
    return _isLoading
        ? const Center(child: LoadingSpinner())
        : _orders.isEmpty
            ? Center(
                child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/global/undraw_no_data_re_kwbl.svg',
                      height: 200,
                      width: 200,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No orders found',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ))
            : ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  return _buildOrderCard(order, defaultColors);
                },
              );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, DefaultColors colors) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                      image: order['mealPicture'] != null
                          ? DecorationImage(
                              image: NetworkImage(order['mealPicture']),
                              fit: BoxFit.cover)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: defaultColors.greyColor)),
                  child: order['mealPicture'] == null
                      ? Icon(Icons.fastfood,
                          size: 60, color: colors.primaryColor)
                      : null,
                ),
                const SizedBox(
                  width: 15,
                ),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                          width: double.infinity,
                          child: _buildStatusDropdown(order, colors)),
                      const SizedBox(
                        height: 16,
                      ),
                      SizedBox(
                          width: double.infinity,
                          child: buildGetLocationButton(order['address']))
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            buildDetailText('Customer Name', '${order['customerName'] ?? ""}'),
            buildDetailText('Meal Name', '${order['mealName']}'),
            buildDetailText('Order Date', dateTimeFormate(order['orderDate'])),
            buildDetailText('Address', '${order['address']}'),
            buildDetailText('Quantity', '${order['quantity']}'),
            buildDetailText(
                'Total Price', '${order['price'] * order['quantity']} Rs'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Recipe:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...(order['recipe'] as List<dynamic>).map((item) => Text(
                          '${item['ingredient']} - ${item['measurement']}')),
                    ],
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Original Recipe:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...(order['originalRecipe'] as List<dynamic>).map(
                          (item) => Text(
                              '${item['ingredient']} - ${item['measurement']}')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ElevatedButton buildGetLocationButton(String address) {
    return ElevatedButton(
        style: ButtonStyle(
            padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 15, horizontal: 15)),
            elevation: const WidgetStatePropertyAll(0),
            shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            backgroundColor:
                WidgetStatePropertyAll(defaultColors.secondaryColor)),
        onPressed: () async {
          await getCordinatesFromAddress(address: address).then((value) async {
            double latitude = value['latitude'];
            double longitude = value['longitude'];

            try {
              String googleUrl =
                  'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
              if (await canLaunchUrl(Uri.parse(googleUrl))) {
                await launchUrl(Uri.parse(googleUrl),
                    mode: LaunchMode.externalApplication);
              } else {
                throw "Could not open the maps";
              }
            } catch (e) {
              if (mounted) {
                print("Errror: $e");
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Error'),
                      content: Text(
                          'Could not open Google Maps. Please try again later.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            }
          });
        },
        child: Text(
          "Get User Location",
          style: TextStyle(color: defaultColors.primaryColor),
        ));
  }

  Padding buildDetailText(String title, String info) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text.rich(TextSpan(
          children: <InlineSpan>[
            TextSpan(
                text: '$title: ',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            TextSpan(text: info),
          ],
        )));
  }

  Widget _buildStatusDropdown(
      Map<String, dynamic> order, DefaultColors colors) {
    // Define status options excluding "Delivered"
    List<String> statusOptions = [
      'Order Placed',
      'Preparing',
      'Ready',
      "Delivery in Progress",
      "Delivered"
    ];

    String currentStatus = order['status'] as String;
    bool isDelivered = currentStatus == 'Order Recieved';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primaryColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: isDelivered ? null : currentStatus,
          hint: Text(
            currentStatus,
            style: TextStyle(
                color: isDelivered
                    ? Colors.grey
                    : _getStatusColor(currentStatus, colors)),
          ),
          icon: Icon(Icons.arrow_drop_down, color: colors.primaryColor),
          iconSize: 24,
          elevation: 16,
          style: TextStyle(color: colors.primaryColor),
          onChanged: isDelivered
              ? null // Disable dropdown if status is "Delivered"
              : (String? newValue) {
                  if (newValue != null && newValue != currentStatus) {
                    setState(() {
                      order['status'] = newValue;
                    });
                    _updateOrderStatus(order, newValue);
                  }
                },
          items: statusOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(
                          isDelivered ? 'Delivered' : value, colors),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value,
                    style: TextStyle(fontSize: 13.5),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(
      Map<String, dynamic> order, String newStatus) async {
    print("orderIDas: ${order['customerId']}");
    final data = await databaseService.getUserFCMToken(order['customerId']);
    final mealData = await databaseService.getMealById(order['mealId']);
    String mealName = mealData!['mealName'];
    String status = order['status'];

    try {
      await _dbService.updateOrderStatus(order['orderId'], newStatus);
      String message = '';

      if (status == 'preparing') {
        message = "Your order '$mealName' is being prepared.";
      } else if (status == 'Ready') {
        message = "Your order '$mealName' is ready.";
      } else if (status == 'Delivered') {
        message = "Your order '$mealName' has been arrived.";
      } else {
        message = 'The Status of $mealName has been changed to $status';
      }
      if (data['fcmToken'] != '') {
        await FirebaseNotificationService.sendPushMessageToCustomer(
            body: message, token: data['fcmToken'].toString());
      }
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  Color _getStatusColor(String status, DefaultColors colors) {
    switch (status.toLowerCase()) {
      case 'order placed':
        return Colors.blue;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'delivered':
        return colors.primaryColor;
      default:
        return Colors.grey;
    }
  }
}
