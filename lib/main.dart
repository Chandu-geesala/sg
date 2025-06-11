import 'dart:io';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'home.dart';

// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Global navigation key for routing
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Define a top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');

  // Handle notification when app is in background/terminated
  if (message.data.isNotEmpty) {
    print('Background message data: ${message.data}');

    // Show local notification for better visibility
    await _showLocalNotification(
      title: message.notification?.title ?? 'Disaster Alert',
      body: message.notification?.body ?? 'New disaster information available',
      payload: jsonEncode(message.data),
    );
  }
}

// Function to show local notifications
Future<void> _showLocalNotification({
  required String title,
  required String body,
  String? payload,
}) async {
  const AndroidNotificationDetails androidNotificationDetails =
  AndroidNotificationDetails(
    'disaster_alerts',
    'Disaster Alerts',
    channelDescription: 'Critical disaster management notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
    icon: '@drawable/ic_notification', // Add your custom icon
  );

  const DarwinNotificationDetails iosNotificationDetails =
  DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    sound: 'default',
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
    iOS: iosNotificationDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    notificationDetails,
    payload: payload,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  print('Firebase initialized');

  // Initialize local notifications
  await _initializeLocalNotifications();

  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  print('Firebase messaging background handler set');

  // Initialize FCM settings
  await _initializeFCM();

  runApp(const MyApp());
}

Future<void> _initializeLocalNotifications() async {
  // Android initialization
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  // iOS initialization
  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings =
  InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      print('Notification tapped with payload: ${response.payload}');

      if (response.payload != null) {
        try {
          final Map<String, dynamic> data = jsonDecode(response.payload!);
          _handleNotificationTap(data);
        } catch (e) {
          print('Error parsing notification payload: $e');
        }
      }
    },
  );

  // Create notification channel for Android
  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        'disaster_alerts',
        'Disaster Alerts',
        description: 'Critical disaster management notifications',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      ),
    );
  }
}

Future<void> _initializeFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permissions
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');

    // Get FCM token
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    // TODO: Send this token to your backend server
    // await sendTokenToServer(token);

  } else {
    print('User declined or has not accepted permission');
  }

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');

      // Show local notification when app is in foreground
      _showLocalNotification(
        title: message.notification!.title ?? 'Disaster Alert',
        body: message.notification!.body ?? 'New disaster information',
        payload: jsonEncode(message.data),
      );
    }
  });

  // Handle notification tap when app is in background but not terminated
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
    print('Message data: ${message.data}');

    _handleNotificationTap(message.data);
  });

  // Handle notification tap when app is terminated
  RemoteMessage? initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    print('App opened from terminated state by notification');
    print('Initial message data: ${initialMessage.data}');

    // Delay to ensure app is fully loaded
    Future.delayed(Duration(seconds: 1), () {
      _handleNotificationTap(initialMessage.data);
    });
  }

  // Subscribe to 'all' topic for general alerts
  await messaging.subscribeToTopic('all');
  print('Subscribed to "all" topic for disaster alerts');

  // You can also keep the disaster_alerts subscription if needed
  // await messaging.subscribeToTopic('disaster_alerts');
  // print('Subscribed to disaster_alerts topic');
}



void _handleNotificationTap(Map<String, dynamic> data) {
  print('Handling notification tap with data: $data');

  if (data.isEmpty) return;

  // Navigate to disaster detail page with the notification data
  if (navigatorKey.currentContext != null) {
    Navigator.of(navigatorKey.currentContext!).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomePage(
          initialDisasterData: data,
          isFromNotification: true,
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disaster Management',
      navigatorKey: navigatorKey, // Add global navigator key
      theme: ThemeData(
        primarySwatch: Colors.red, // Changed to red for disaster theme
        scaffoldBackgroundColor: Color(0xFFF0F1F6),
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      // Add route handling for deep links
      onGenerateRoute: (settings) {
        if (settings.name == '/disaster-detail') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => HomePage(
              initialDisasterData: args,
              isFromNotification: true,
            ),
          );
        }
        return MaterialPageRoute(builder: (context) => HomePage());
      },
    );
  }
}