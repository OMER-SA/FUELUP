import 'package:diet_app/components/loading.dart';
import 'package:diet_app/firebase/db_service.dart';
import 'package:diet_app/firebase/firebase_messaging.dart';
import 'package:diet_app/firebase/realtime_database.dart';
import 'package:diet_app/providers/customer_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> confirmDeliveryDialog(
  BuildContext context,
  defaultColors,
  Map<String, dynamic> order,
) async {
  final RealDataBaseService _realTimeDataBase = RealDataBaseService();
  final DBService dbService = DBService();
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      bool loading = false;
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(order['mealName']!),
          content: const Text(
            'Are you sure you got the order ?',
          ),
          actions: loading
              ? [LoadingSpinner()]
              : <Widget>[
                  ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(defaultColors.redColor)),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      )),
                  ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                              defaultColors.primaryColor)),
                      onPressed: () async {
                        setState(() => loading = true);
                        final customerProvider = Provider.of<CustomerProvider>(
                            context,
                            listen: false);
                        final fullName =
                            "${customerProvider.getFirstName} ${customerProvider.getLastName}";
                        print("Orderrr::: ${order['kitchenId']}");
                        final chefData = await dbService
                            .getUser(order['kitchenId'].toString());

                        await _realTimeDataBase.updateOrderStatus(
                            order['orderId'], 'Order Recieved');

                        if (chefData['fcmToken'] != '') {
                          await FirebaseNotificationService
                              .sendPushMessageToCheff(
                                  token: chefData['fcmToken'],
                                  body:
                                      'The order has been recieved by $fullName',
                                  title: "Order Recieved");
                        }

                        Navigator.of(context).pop();
                        setState(() => loading = false);
                      },
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ))
                ],
        );
      });
    },
  );
}
