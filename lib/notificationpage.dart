import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<String> notifications = []; // List to store notifications

  @override
  void initState() {
    super.initState();
    loadNotifications(); // Load notifications from SharedPreferences
  }

  // Load stored notifications from SharedPreferences
  void loadNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      notifications = prefs.getStringList('notifications') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(notifications[index]), // Display notification message
          );
        },
      ),
    );
  }
}
