import 'dart:async';
import 'package:diet_app/components/dotted_divider.dart';
import 'package:diet_app/components/loading.dart';
import 'package:diet_app/components/order/confirm_delevery_dialog.dart';
import 'package:diet_app/providers/user_provider.dart';
import 'package:diet_app/utilities/constants.dart';
import 'package:diet_app/utilities/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:diet_app/firebase/realtime_database.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final RealDataBaseService _realTimeDataBase = RealDataBaseService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  late StreamSubscription<DatabaseEvent> _ordersAddedSubscription;
  late StreamSubscription<DatabaseEvent> _ordersRemovedSubscription;
  late StreamSubscription<DatabaseEvent> _ordersChangedSubscription;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _setupOrdersListeners();
  }

  @override
  void dispose() {
    _ordersAddedSubscription.cancel();
    _ordersRemovedSubscription.cancel();
    _ordersChangedSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    final userData = context.read<UserIdProvider>();
    final userId = userData.getUuid;

    if (userId != null) {
      final fetchedOrders = await _realTimeDataBase.fetchOrdersByUserId(userId);
      setState(() {
        _orders = fetchedOrders;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _setupOrdersListeners() {
    final userData = context.read<UserIdProvider>();
    final userId = userData.getUuid;

    if (userId != null) {
      final ordersRef = FirebaseDatabase.instance
          .ref()
          .child('orders')
          .orderByChild('customerId')
          .equalTo(userId);

      _ordersAddedSubscription = ordersRef.onChildAdded.listen((event) async {
        if (event.snapshot.value != null) {
          final newOrder =
              Map<String, dynamic>.from(event.snapshot.value as Map);
          bool isDuplicate =
              _orders.any((order) => order['orderId'] == newOrder['orderId']);
          if (!isDuplicate) {
            setState(() {
              _orders.add(newOrder);
            });
          }
        }
      });

      _ordersChangedSubscription =
          ordersRef.onChildChanged.listen((event) async {
        if (event.snapshot.value != null) {
          final updatedOrder =
              Map<String, dynamic>.from(event.snapshot.value as Map);

          setState(() {
            final index = _orders.indexWhere(
                (order) => order['orderId'] == updatedOrder['orderId']);
            if (index != -1) {
              _orders[index] = updatedOrder;
            }
          });
        }
      });

      _ordersRemovedSubscription = ordersRef.onChildRemoved.listen((event) {
        if (event.snapshot.value != null) {
          final removedOrder =
              Map<String, dynamic>.from(event.snapshot.value as Map);
          setState(() {
            _orders.removeWhere(
                (order) => order['orderId'] == removedOrder['orderId']);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultColors = DefaultColors();

    // Split orders into non-delivered and delivered
    final nonDeliveredOrders = _filterAndSortOrders('Order Recieved', false);
    final deliveredOrders = _filterAndSortOrders('Order Recieved', true);

    return _isLoading
        ? const Center(child: LoadingSpinner())
        : _orders.isEmpty
            ? _buildNoOrdersFound()
            : ListView(
                children: [
                  ...nonDeliveredOrders
                      .map((order) => _buildOrderCard(order, defaultColors))
                      .toList(),
                  if (deliveredOrders.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 20.0),
                      child: DottedDivider(
                          height: 1, color: defaultColors.primaryColor),
                    ),
                  ...deliveredOrders
                      .map((order) => _buildOrderCard(order, defaultColors))
                      .toList(),
                ],
              );
  }

  Widget _buildNoOrdersFound() {
    return Center(
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterAndSortOrders(
      String status, bool delivered) {
    final filteredOrders = _orders
        .where((order) => (order['status'] == status) == delivered)
        .toList();
    filteredOrders.sort((a, b) {
      final dateA = DateTime.parse(a['orderDate']);
      final dateB = DateTime.parse(b['orderDate']);
      return dateB.compareTo(dateA); // Descending order (latest first)
    });
    return filteredOrders;
  }

  Widget _buildOrderCard(Map<String, dynamic> order, DefaultColors colors) {
    print("Orderrrrr $order");
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMealImage(order, colors),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['mealName'] ?? 'Unknown Meal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusChip(order['status'], colors),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildOrderDetails(order),
            const SizedBox(height: 16),
            Row(
              children: [
                Flexible(
                    child: _buildRecipeList(order['recipe'] as List<dynamic>?)),
                ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                            order['status'] != 'Order Recieved'
                                ? colors.primaryColor
                                : colors.greyColor)),
                    onPressed: order['status'] != 'Order Recieved'
                        ? () async {
                            print("Orderrr::: ${order['status']}");
                            await confirmDeliveryDialog(context, colors, order);
                          }
                        : () {
                            FlutterToast.showToast(
                                "The Order Is Already Received",
                                colors.warningColor);
                          },
                    child: Text(
                      "Order Recieved ?",
                      style: TextStyle(color: Colors.white),
                    ))
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealImage(Map<String, dynamic> order, DefaultColors colors) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        image: order['mealPicture'] != null
            ? DecorationImage(
                image: NetworkImage(order['mealPicture']),
                fit: BoxFit.cover,
              )
            : null,
        color: colors.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primaryColor),
      ),
      child: order['mealPicture'] == null
          ? Icon(Icons.fastfood, size: 50, color: colors.primaryColor)
          : null,
    );
  }

  Widget _buildStatusChip(String status, DefaultColors colors) {
    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: _getStatusColor(status, colors),
    );
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

  Widget _buildOrderDetails(Map<String, dynamic> order) {
    final quantity = order['quantity'] as int? ?? 0;
    final price = order['price'] as int? ?? 0;
    final totalPrice = quantity * price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Quantity', "$quantity"),
        _buildDetailRow('Price', "$price Rs"),
        _buildDetailRow('Total Price', '$totalPrice Rs'),
        _buildDetailRow('Order Date', _formatDate(order['orderDate'])),
        _buildDetailRow('Kitchen Name', order['kitchenName'] ?? 'Unknown'),
        _buildDetailRow('Kitchen Address', order['address'] ?? 'Unknown'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              text: '$label: ',
            ),
            TextSpan(text: info),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeList(List<dynamic>? recipe) {
    if (recipe == null || recipe.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recipe:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Column(
          children: recipe
              .map((item) =>
                  _buildRecipeItem(Map<String, dynamic>.from(item as Map)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRecipeItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${item['ingredient'] ?? ''} - ${item['measurement'] ?? ''}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return DateFormat('MMM d, y HH:mm').format(dateTime);
  }
}
