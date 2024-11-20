import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart'; // Import Pusher package
import 'notificationpage.dart';
import 'devicespage.dart';
import 'homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import Flutter Local Notifications
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences and Flutter Local Notifications
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await requestNotificationPermission();
  await onConnectPressed(prefs);

  // Initialize Local Notifications
  await initializeNotifications();

  runApp(MyApp());
}

// Global instance of FlutterLocalNotificationsPlugin
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Initialize Flutter Local Notifications
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/launcher_icon');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// Request notification permissions for both Android and iOS
Future<void> requestNotificationPermission() async {
  // For Android 13 and above, request permissions
  if (await Permission.notification.isGranted) {
    print("Notification permission already granted for Android");
  } else {
    // Request permission
    PermissionStatus status = await Permission.notification.request();
    if (status.isGranted) {
      print("Notification permission granted for Android");
    } else {
      print("Notification permission denied for Android");
    }
  }
 
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    const DevicesPage(),
    NotificationPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ESP Doorbell'),
      ),
      body: SafeArea(child: _widgetOptions[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.devices),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notification',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

Future<void> onConnectPressed(SharedPreferences prefs) async {
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  try {
    await pusher.init(
      apiKey: "3ef10ab69edd1c712eeb",
      cluster: "ap1",
      onConnectionStateChange: (currentState, previousState) {
        print("Connection: $currentState");
      },
      onError: (message, code, e) {
        print("onError: $message code: $code exception: $e");
      },
      onSubscriptionSucceeded: (channelName, data) {
        print("onSubscriptionSucceeded: $channelName data: $data");
      },
      onEvent: (event) {
        print("onEvent: $event");
        // Store notifications in SharedPreferences
        storeNotification(event, prefs);
        // Trigger a local notification when an event is received
        triggerLocalNotification(event.data.toString());
      },
      onSubscriptionError: (message, e) {
        print("onSubscriptionError: $message Exception: $e");
      },
      onDecryptionFailure: (event, reason) {
        print("onDecryptionFailure: $event reason: $reason");
      },
      onMemberAdded: (channelName, member) {
        print("onMemberAdded: $channelName user: $member");
      },
      onMemberRemoved: (channelName, member) {
        print("onMemberRemoved: $channelName user: $member");
      },
      onSubscriptionCount: (channelName, subscriptionCount) {
        print(
            "onSubscriptionCount: $channelName subscriptionCount: $subscriptionCount");
      },
    );
    await pusher.subscribe(channelName: "test");
    await pusher.connect();
  } catch (e) {
    print("ERROR: $e");
  }
}

void storeNotification(PusherEvent event, SharedPreferences prefs) {
  List<String> notifications = prefs.getStringList('notifications') ?? [];
  String notificationMessage = event.data.toString(); // Save event data
  notifications.add(notificationMessage);
  prefs.setStringList('notifications',
      notifications); // Store the notifications list in SharedPreferences
}

// Function to trigger a local notification
Future<void> triggerLocalNotification(String message) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'channel_id',
    'channel_name',
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'ticker',
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidNotificationDetails);

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    'Doorbell', // Notification Title
    message, // Notification Body
    notificationDetails,
    payload: 'item x', // Optional data for notification click
  );
}
