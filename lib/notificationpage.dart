import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, String>> notifications = []; // List to store notifications as maps
  bool isLoading = false; // To show loading state
  int notificationsLimit = 5; // Limit to the number of notifications to show initially
  int currentOffset = 0; // For pagination (current position in the notifications list)

  @override
  void initState() {
    super.initState();
    loadNotifications(); // Load notifications from SharedPreferences
  }

  // Load stored notifications from SharedPreferences
  void loadNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> allNotifications = prefs.getStringList('notifications') ?? [];
    
    // Reverse the list to show latest notifications first
    setState(() {
      notifications = allNotifications.reversed
          .map((notification) => jsonDecode(notification)) // Decode JSON into a map
          .map<Map<String, String>>((data) => Map<String, String>.from(data)) // Ensure it's a Map<String, String>
          .toList();
    });

    // Load the initial set of notifications
    loadMoreNotifications();
  }

  // Load more notifications with a limit
  void loadMoreNotifications() {
    setState(() {
      isLoading = true;
    });

    // Calculate the next set of notifications to display
    int nextOffset = currentOffset + notificationsLimit;
    if (nextOffset > notifications.length) {
      nextOffset = notifications.length; // Ensure we don't exceed the list length
    }

    // Get the notifications to display from currentOffset to nextOffset
    List<Map<String, String>> newNotifications = notifications.sublist(currentOffset, nextOffset);

    setState(() {
      currentOffset = nextOffset; // Update the offset for the next load
      notifications = newNotifications;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                String eventData = notifications[index]['data'] ?? ''; // Get event data
                String timestamp = notifications[index]['timestamp'] ?? ''; // Get timestamp

                return ListTile(
                  title: Text('$eventData at $timestamp'), // Display event data and timestamp
                );
              },
            ),
          ),
          if (isLoading) 
            CircularProgressIndicator(), // Show loading indicator
          if (currentOffset < notifications.length)
            ElevatedButton(
              onPressed: loadMoreNotifications,
              child: Text('Load More'),
            ),
        ],
      ),
    );
  }
}
