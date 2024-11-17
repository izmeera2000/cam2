import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'devices/camera_page.dart';
import 'devices/microphone_page.dart';
import 'devices/speaker_page.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({Key? key}) : super(key: key);

  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  String cameraStatus = 'Loading...';
String microphoneStatus = 'Loading...';
  String speakerStatus = 'Loading...';



  @override
  void initState() {
    super.initState();
    _loadCameraIP();  // Load the camera IP from SharedPreferences
    _loadMicrophoneIP();  // Load the camera IP from SharedPreferences
    _loadSpeakerIP();  // Load the camera IP from SharedPreferences
  }

  // Function to load the camera IP from SharedPreferences
  void _loadCameraIP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cameraIP = prefs.getString('camera_ip'); // Get the camera IP
    setState(() {
      // Update the status to the IP if available, otherwise 'Not Available'
      cameraStatus = cameraIP ?? 'Not Available';
    });
  }

  void _loadMicrophoneIP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? microphoneIP = prefs.getString('microphone_ip'); // Get the camera IP
    setState(() {
      // Update the status to the IP if available, otherwise 'Not Available'
      microphoneStatus = microphoneIP ?? 'Not Available';
    });
  }

  void _loadSpeakerIP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? speakerIP = prefs.getString('speaker_ip'); // Get the camera IP
    setState(() {
      // Update the status to the IP if available, otherwise 'Not Available'
      speakerStatus = speakerIP ?? 'Not Available';

     });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Devices List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraPage(),
                      ),
                    ).then((result) {
                      // Optionally handle the result here if needed
                    });
                  },
                  child: DeviceCard(
                    icon: Icons.photo_camera,
                    title: 'Camera',
                    status: cameraStatus, // Displaying camera status
                    color: Colors.grey[200],
                    textColor: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MicrophonePage(),
                      ),
                    );
                  },
                  child: DeviceCard(
                    icon: Icons.record_voice_over,
                    title: 'Microphone',
                    status: microphoneStatus,
                    color: Colors.grey[200],
                    textColor: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpeakerPage(),
                      ),
                    );
                  },
                  child: DeviceCard(
                    icon: Icons.volume_up,
                    title: 'Speaker',
                    status: speakerStatus,
                    color: Colors.grey[200],
                    textColor: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final Color? color;
  final Color textColor;

  DeviceCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Conditional check for 'Not Available' or 'Loading' status
    bool isErrorState = status == 'Not Available' || status == 'Loading...';
    Color displayColor = isErrorState ? Colors.grey[200]! :Colors.blue;
    Color displayTextColor = isErrorState ? Colors.black : Colors.white;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: displayColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: displayTextColor),
          SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: displayTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: displayTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
