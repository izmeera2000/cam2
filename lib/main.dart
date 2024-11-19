import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart'; // Import Pusher package
import 'notificationpage.dart';
import 'devicespage.dart';
import 'homepage.dart';
 
import 'package:shared_preferences/shared_preferences.dart';
 void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences to store notifications
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await onConnectPressed(prefs);

  runApp(MyApp());
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
        print("onSubscriptionCount: $channelName subscriptionCount: $subscriptionCount");
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
  prefs.setStringList('notifications', notifications); // Store the notifications list in SharedPreferences
}