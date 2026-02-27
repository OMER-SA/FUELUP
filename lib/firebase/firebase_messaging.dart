import 'dart:convert';
import 'dart:developer';
import 'package:diet_app/firebase/db_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;

class FirebaseNotificationService {
  final DBService _dbService = DBService();

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static const String serviceAccountPath =
      'assets/service_account_key/diet-aid-dda01-firebase-adminsdk-2unhb-faadf76749.json';

  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  Future<String?> getFCMToken() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    return fCMToken;
  }

  Future<void> initialize({required String userID}) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: darwinInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    FirebaseMessaging.instance.getToken().then((token) async {
      if (token != null) {
        await _dbService.updateFCMToken(fcmToken: token, userID: userID);
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _dbService.updateFCMToken(fcmToken: newToken, userID: userID);
    });
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformChannelSpecifics,
      );
    }
  }

  static Future<void> sendPushMessageToCustomer({
    required String token,
    required String body,
  }) async {
    try {
      var serviceAccountCredentialsJson =
          await rootBundle.loadString(serviceAccountPath);
      var serviceAccountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccountCredentialsJson);

      var client =
          await clientViaServiceAccount(serviceAccountCredentials, _scopes);

      var url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/diet-aid-dda01/messages:send');

      print(
          "serviceAccountCredentials.email: ${serviceAccountCredentials.email}");

      var messagePayload = jsonEncode({
        'message': {
          'token': token,
          'notification': {'title': 'Order Status Update', 'body': body},
          'data': {'extraData1': 'value1', 'extraData2': 'value2'}
        }
      });

      var response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: messagePayload,
      );

      if (response.statusCode == 200) {
        print('Push notification sent successfully!');
      } else {
        log('Failed to send push notification. Status code: ${response.statusCode}');
        log('Response body: ${response.body}');
        log('Response headers: ${response.headers}');
      }

      client.close();
    } catch (e) {
      print("Error sending push notification: $e");
      rethrow;
    }
  }

  static Future<void> sendPushMessageToCheff(
      {required String token,
      required String body,
      required String title}) async {
    print("TOkennnnn:: $token");
    try {
      var serviceAccountCredentialsJson =
          await rootBundle.loadString(serviceAccountPath);
      var serviceAccountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccountCredentialsJson);

      var client =
          await clientViaServiceAccount(serviceAccountCredentials, _scopes);

      var url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/diet-aid-dda01/messages:send');
      print(
          "serviceAccountCredentials.email: ${serviceAccountCredentials.email}");
      var messagePayload = jsonEncode({
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body.toString()},
          'data': {'extraData1': 'value1', 'extraData2': 'value2'}
        }
      });

      var response = await client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: messagePayload,
      );

      if (response.statusCode == 200) {
        print('Push notification sent successfully!');
      } else {
        log('Failed to send push notification: ${response.body}');
      }

      client.close();
    } catch (e) {
      print("Error sending push notification: $e");
      rethrow;
    }
  }
}
